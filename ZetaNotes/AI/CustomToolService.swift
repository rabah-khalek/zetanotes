//
//  CustomToolService.swift
//  ZetaNotes
//
//  Service for executing user-created custom AI tools
//  Uses the same AIService infrastructure as built-in tools
//

import Foundation

/// Service for executing custom user-defined AI tools
/// Follows the same pattern as built-in services (AutoCorrect, Rephrase, etc.)
class CustomToolService: AIService {
    let llmService: LLMInferenceService
    let config: AIGenerationConfig

    private let prompt: String

    // MARK: - Initialization

    init(llmService: LLMInferenceService, prompt: String, temperature: Float, maxTokens: Int?) {
        self.llmService = llmService
        self.prompt = prompt
        self.config = AIGenerationConfig(
            temperature: temperature,
            maxTokens: maxTokens
        )
    }

    // MARK: - AIService Protocol

    func buildPrompt(for text: String) -> String {
        // The prompt is the instruction that goes into systemMessage
        // The text goes into userMessage (handled by AIService.process)
        return prompt
    }

    func postProcess(_ output: String) -> String {
        // Apply centralized LLM output cleaning
        var cleaned = LLMOutputCleaner.clean(output)

        // Remove common conversational prefixes
        let prefixes = [
            "Here is the",
            "Here's the",
            "Sure! Here",
            "Sure, here",
            "Certainly!",
            "Certainly,",
            "Of course!",
            "Of course,",
            "I'll help you",
            "I can help",
            "Let me help",
            "I'd be happy to"
        ]

        for prefix in prefixes where cleaned.lowercased().hasPrefix(prefix.lowercased()) {
            // Remove the prefix and everything up to the first colon or newline
            if let colonIndex = cleaned.firstIndex(of: ":") {
                cleaned = String(cleaned[cleaned.index(after: colonIndex)...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            } else if let newlineIndex = cleaned.firstIndex(of: "\n") {
                cleaned = String(cleaned[cleaned.index(after: newlineIndex)...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                // Just remove the prefix
                cleaned = String(cleaned.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            break
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
