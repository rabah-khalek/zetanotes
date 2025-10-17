//
//  AutocompleteService.swift
//  NoteTaker
//
//  Real-time autocomplete suggestions while typing
//  Implements debouncing to avoid excessive inference calls
//

import Combine
import Foundation

/// Service providing intelligent autocomplete suggestions
/// Uses debouncing to ensure smooth, non-blocking experience
class AutocompleteService: AIService {
    let llmService: LLMInferenceService
    let config: AIGenerationConfig

    private var debounceTimer: Timer?
    private let debounceDelay: TimeInterval = 0.2 // 200ms debounce
    private var lastContext: String = "" // Store context for post-processing

    // MARK: - Configuration

    private enum Config {
        static let minCharacters = 10 // Minimum characters before suggesting
        static let maxTokens: Int = 100 // Maximum tokens to generate (allows full sentences)
        static let contextLength = 500 // Characters of context to use
    }

    // MARK: - Initialization

    init(llmService: LLMInferenceService) {
        self.llmService = llmService
        config = AIGenerationConfig(
            temperature: 0.5, // Moderate creativity for natural continuations
            maxTokens: Config.maxTokens,
            stopSequences: [
                ". ", // Stop after completing a sentence
                ".\n", // Stop after sentence with newline
                "\n\n\n", // Stop at major paragraph breaks
                "<|user|>", // Prevent fake user messages
                "<|system|>" // Prevent fake system messages
            ]
        )
    }

    // MARK: - AIService Protocol

    func buildPrompt(for text: String) -> String {
        // Get the last N characters for context
        let contextLength = min(text.count, Config.contextLength)
        let startIndex = text.index(text.endIndex, offsetBy: -contextLength)
        let context = String(text[startIndex...])

        // Store context for post-processing
        lastContext = context

        // Use same pattern as other services: instruction + text + label
        return """
        \(DefaultPrompts.autocomplete)

        \(context)

        Continuation:
        """
    }

    // Post-process to clean the autocomplete output
    func postProcess(_ output: String) -> String {
        // Don't trim yet - we need to detect if there's a period at the end
        var cleaned = output

        // Remove common prefixes that models add
        let prefixes = [
            "Continuation:",
            "Here is the continuation:",
            "Here is",
            "Here's",
            "The continuation is:",
            "continuation:"
        ]

        for prefix in prefixes where cleaned.lowercased().hasPrefix(prefix.lowercased()) {
            cleaned = String(cleaned.dropFirst(prefix.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: ":"))
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Remove leading ellipsis that models add when context seems truncated
        if cleaned.hasPrefix("...") {
            cleaned = String(cleaned.dropFirst(3))
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if cleaned.hasPrefix("..") {
            cleaned = String(cleaned.dropFirst(2))
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Remove the context if the LLM echoed it back
        if cleaned.lowercased().hasPrefix(lastContext.lowercased()) {
            cleaned = String(cleaned.dropFirst(lastContext.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Also handle partial context repetition (last few words)
        let contextWords = lastContext.split(separator: " ")
        if contextWords.count >= 3 {
            let lastFewWords = contextWords.suffix(min(5, contextWords.count)).joined(separator: " ")
            if let range = cleaned.range(of: lastFewWords, options: [.caseInsensitive, .anchored]) {
                cleaned = String(cleaned[range.upperBound...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // Allow single newlines in autocomplete (for natural continuation)
        // Only stop at triple newlines (major paragraph breaks)
        if let tripleNewline = cleaned.range(of: "\n\n\n") {
            cleaned = String(cleaned[..<tripleNewline.lowerBound])
        }

        // Trim only leading whitespace (don't trim trailing - we need it for sentence detection)
        while cleaned.first?.isWhitespace == true || cleaned.first?.isNewline == true {
            cleaned.removeFirst()
        }

        // Handle sentence completion:
        // If the output doesn't end with sentence-ending punctuation, add a period
        if !cleaned.isEmpty {
            let lastChar = cleaned.last!
            let hasSentenceEnd = lastChar == "." || lastChar == "!" || lastChar == "?"

            if !hasSentenceEnd {
                // Find the last complete sentence if output was truncated
                // Look for the last period, question mark, or exclamation point
                if let lastPeriod = cleaned.lastIndex(of: "."),
                   lastPeriod != cleaned.index(before: cleaned.endIndex) {
                    // There's a period in the middle - truncate to last complete sentence
                    let afterPeriod = cleaned.index(after: lastPeriod)
                    if afterPeriod < cleaned.endIndex {
                        // Keep text up to and including the period
                        cleaned = String(cleaned[..<afterPeriod])
                    }
                } else if let lastQuestion = cleaned.lastIndex(of: "?") {
                    let afterQuestion = cleaned.index(after: lastQuestion)
                    if afterQuestion < cleaned.endIndex {
                        cleaned = String(cleaned[..<afterQuestion])
                    }
                } else if let lastExclamation = cleaned.lastIndex(of: "!") {
                    let afterExclamation = cleaned.index(after: lastExclamation)
                    if afterExclamation < cleaned.endIndex {
                        cleaned = String(cleaned[..<afterExclamation])
                    }
                } else {
                    // No sentence ending found - add a period to complete the sentence
                    cleaned += "."
                }
            }
        }

        // Finally, trim trailing whitespace (but we already trimmed leading)
        while cleaned.last?.isWhitespace == true || cleaned.last?.isNewline == true {
            cleaned.removeLast()
        }

        return cleaned
    }

    // MARK: - Autocomplete

    /// Generates an autocomplete suggestion for the given text
    /// - Parameter text: The current text content
    /// - Returns: Suggested completion text, or nil if no suggestion
    func generateSuggestion(for text: String) async -> String? {
        // Don't suggest if text is too short
        guard text.count >= Config.minCharacters else { return nil }

        return await process(text)
    }

    /// Generates autocomplete with debouncing
    /// Returns a publisher that emits suggestions after debounce period
    /// - Parameter text: The text to complete
    /// - Returns: Publisher emitting optional suggestion
    func debouncedSuggestion(for text: String) -> AnyPublisher<String?, Never> {
        return Future<String?, Never> { [weak self] promise in
            self?.debounceTimer?.invalidate()

            self?.debounceTimer = Timer
                .scheduledTimer(withTimeInterval: self?.debounceDelay ?? 0.2, repeats: false) { _ in
                    Task {
                        let suggestion = await self?.generateSuggestion(for: text)
                        promise(.success(suggestion))
                    }
                }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Cleanup

    func cancelPendingSuggestion() {
        debounceTimer?.invalidate()
        debounceTimer = nil
    }
}
