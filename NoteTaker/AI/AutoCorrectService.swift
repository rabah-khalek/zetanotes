//
//  AutoCorrectService.swift
//  NoteTaker
//
//  Fixes spelling and grammar mistakes in text
//  Uses very low temperature for deterministic corrections
//

import Foundation

/// Service for correcting spelling and grammar in text
class AutoCorrectService: AIService {
    let llmService: LLMInferenceService
    let config: AIGenerationConfig

    // MARK: - Initialization

    init(llmService: LLMInferenceService) {
        self.llmService = llmService
        self.config = AIGenerationConfig(
            temperature: 0.05,  // Very low for deterministic corrections
            maxTokens: nil,     // Will be calculated dynamically
            stopSequences: [
                "\n\n\n",
                "\n---",
                "\nNote:",
                "\nHere is",
                "\nCorrected:",
                "\nThe corrected"
            ]
        )
    }

    // MARK: - AIService Protocol

    func buildPrompt(for text: String) -> String {
        return "\(DefaultPrompts.autoCorrect)\(text)\n\nCorrected text:"
    }

    // MARK: - AIService Override

    /// Override process to use custom prompt and dynamic max tokens
    func process(_ text: String, customPrompt: String) async -> String? {
        // Calculate dynamic max tokens with 20% buffer for corrections
        let maxTokens = calculateMaxTokens(for: text, bufferPercent: 20, maxLimit: 1024)

        let instruction = customPrompt.isEmpty ? DefaultPrompts.autoCorrect : customPrompt + "\n\n"
        let prompt = "\(instruction)\(text)\n\nCorrected text:"

        guard let rawOutput = await llmService.generate(
            prompt: prompt,
            maxTokens: maxTokens,
            temperature: config.temperature,
            stopSequences: config.stopSequences
        ) else {
            return nil
        }

        return postProcess(rawOutput)
    }    // MARK: - Public API

    /// Corrects spelling and grammar in the given text
    /// - Parameter text: The text to correct
    /// - Returns: Corrected text, or nil on failure
    func correct(_ text: String) async -> String? {
        return await process(text, customPrompt: "")
    }

    // MARK: - Post-processing

    func postProcess(_ output: String) -> String {
        let stopMarkers = [
            "\n\nThe ",
            "\n\nHere is",
            "\n\nNote:",
            "\n\nCorrected:",
            "\n\nThis text",
            "\n\n---"
        ]

        let prefixes = [
            "Corrected:",
            "Corrected text:",
            "Here is the corrected text:",
            "The corrected text is:",
            "corrected:"
        ]

        return standardPostProcess(
            output,
            stopMarkers: stopMarkers,
            prefixes: prefixes,
            keepOnlyFirstParagraph: false  // Don't limit to first paragraph for corrections
        )
    }
}
