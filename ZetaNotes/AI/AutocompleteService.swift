//
//  AutocompleteService.swift
//  ZetaNotes
//
//  Real-time autocomplete suggestions while typing
//  Implements debouncing to avoid excessive inference calls
//

import Combine
import Foundation

/// Service providing intelligent autocomplete suggestions
/// Note: Debouncing is handled by the view layer for optimal responsiveness
class AutocompleteService: AIService {
    let llmService: LLMInferenceService
    let config: AIGenerationConfig

    private var currentModel: AIModel
    private var lastContext: String = "" // Store context for post-processing

    // MARK: - Configuration

    private enum Config {
        static let minCharacters = 10 // Minimum characters before suggesting
        static let contextLength = 300 // Characters of context to use (reduced from 500 for better focus)
    }

    // MARK: - Initialization

    init(llmService: LLMInferenceService, model: AIModel) {
        self.llmService = llmService
        currentModel = model

        // Get model-specific config from registry
        let toolConfig = ModelToolConfigRegistry.getConfig(for: model, toolType: .autocomplete)

        config = AIGenerationConfig(
            temperature: toolConfig.temperature,
            maxTokens: toolConfig.maxTokens ?? 100,
            usePromptAsUserMessage: toolConfig.usePromptAsUserMessage
        )
    }

    // Update model and config
    func updateModel(_ model: AIModel) {
        currentModel = model
        _ = ModelToolConfigRegistry.getConfig(for: model, toolType: .autocomplete)
        // Note: config is let, so we can't update it directly
        // The config will be used from the registry in buildPrompt
    }

    // MARK: - AIService Protocol

    func buildPrompt(for text: String) -> String {
        // Get the last N characters for context
        let contextLength = min(text.count, Config.contextLength)
        let startIndex = text.index(text.endIndex, offsetBy: -contextLength)
        let context = String(text[startIndex...])

        // Store context for post-processing
        lastContext = context

        // For autocomplete, we use direct completion (not chat template)
        // Just return the context - the model will continue from where it left off
        return context
    }

    // Override process() to use direct generation instead of chat template
    func process(_ text: String) async -> String? {
        guard !text.isEmpty else { return nil }

        let prompt = buildPrompt(for: text)

        // Use direct generation for autocomplete (not chat template)
        // This allows the model to continue the text naturally without conversational framing
        guard let rawOutput = await llmService.generate(
            prompt: prompt,
            maxTokens: config.maxTokens,
            temperature: config.temperature
        ) else {
            return nil
        }

        return postProcess(rawOutput)
    }

    // Post-process to clean the autocomplete output
    func postProcess(_ output: String) -> String {
        // First apply centralized LLM output cleaner
        var cleaned = LLMOutputCleaner.clean(output)

        // Remove common prefixes that models add
        let prefixes = [
            "Continuation:",
            "Here is the continuation:",
            "Here is",
            "Here's",
            "The continuation is:",
            "continuation:",
            "I can't help but notice", // Llama 3.2 meta-commentary
            "I notice that", // Llama 3.2 meta-commentary
            "I see that", // Meta-commentary
            "This article is", // Meta-commentary
            "This text is" // Meta-commentary
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

        // LIMIT TO SINGLE LINE: Stop at first newline to avoid multi-line ghost text issues
        if let newlineIndex = cleaned.firstIndex(where: { $0.isNewline }) {
            cleaned = String(cleaned[..<newlineIndex])
        }

        // Trim only leading whitespace (don't trim trailing - we need it for sentence detection)
        while cleaned.first?.isWhitespace == true {
            cleaned.removeFirst()
        }

        // Handle sentence completion:
        // Truncate to last complete sentence if output was cut off mid-sentence
        if !cleaned.isEmpty {
            let lastChar = cleaned.last!
            let hasSentenceEnd = lastChar == "." || lastChar == "!" || lastChar == "?" || lastChar == ","

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
                } else if let lastComma = cleaned.lastIndex(of: ",") {
                    // Truncate to last comma for natural pause points
                    let afterComma = cleaned.index(after: lastComma)
                    if afterComma < cleaned.endIndex {
                        cleaned = String(cleaned[..<afterComma])
                    }
                }
                // Do NOT add a period - keep completions open-ended for natural flow
            }
        }

        // Finally, trim trailing whitespace
        while cleaned.last?.isWhitespace == true {
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
}
