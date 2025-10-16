//
//  AutocompleteService.swift
//  NoteTaker
//
//  Real-time autocomplete suggestions while typing
//  Implements debouncing to avoid excessive inference calls
//

import Foundation
import Combine

/// Service providing intelligent autocomplete suggestions
/// Uses debouncing to ensure smooth, non-blocking experience
class AutocompleteService: AIService {
    let llmService: LLMInferenceService
    let config: AIGenerationConfig

    private var debounceTimer: Timer?
    private let debounceDelay: TimeInterval = 0.2 // 200ms debounce
    private var lastContext: String = "" // Store context for post-processing

    // MARK: - Configuration

    private struct Config {
        static let minCharacters = 10 // Minimum characters before suggesting
        static let maxTokens: Int = 20 // Maximum tokens to generate
        static let contextLength = 500 // Characters of context to use
    }

    // MARK: - Initialization

    init(llmService: LLMInferenceService) {
        self.llmService = llmService
        self.config = AIGenerationConfig(
            temperature: 0.3,
            maxTokens: Config.maxTokens,
            stopSequences: ["\n\n", "\n\n\n"]  // Stop at paragraph breaks only
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
        var cleaned = output.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove common prefixes that models add
        let prefixes = [
            "Continuation:",
            "Here is the continuation:",
            "Here is",
            "Here's",
            "The continuation is:",
            "continuation:"
        ]

        for prefix in prefixes {
            if cleaned.lowercased().hasPrefix(prefix.lowercased()) {
                cleaned = String(cleaned.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .trimmingCharacters(in: CharacterSet(charactersIn: ":"))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
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

        // Stop at double newlines (paragraph breaks)
        if let doubleNewline = cleaned.range(of: "\n\n") {
            cleaned = String(cleaned[..<doubleNewline.lowerBound])
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
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

            self?.debounceTimer = Timer.scheduledTimer(withTimeInterval: self?.debounceDelay ?? 0.2, repeats: false) { _ in
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
