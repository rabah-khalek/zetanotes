//
//  ReformulationService.swift
//  NoteTaker
//
//  Rewrites text to be clearer and more professional
//  Maintains original meaning while improving clarity
//

import Foundation

/// Service for reformulating text to be clearer and more professional
class ReformulationService: AIService {
    let llmService: LLMInferenceService
    let config: AIGenerationConfig

    // MARK: - Initialization

    init(llmService: LLMInferenceService) {
        self.llmService = llmService
        self.config = AIGenerationConfig(
            temperature: 0.4,   // Moderate creativity for better phrasing
            maxTokens: nil,     // Will be calculated dynamically
            stopSequences: [
                "\n\n\n",
                "\n---",
                "\nNote:",
                "\nHere is",
                "\nRewritten:",
                "\nThe rewritten"
            ]
        )
    }

    // MARK: - AIService Protocol

    func buildPrompt(for text: String) -> String {
        return "\(DefaultPrompts.reformulate)\(text)\n\nRewritten text:"
    }

    // MARK: - AIService Override

    /// Override process to use custom prompt and dynamic max tokens
    func process(_ text: String, customPrompt: String) async -> String? {
        // Calculate dynamic max tokens with 30% buffer for expansion
        let maxTokens = calculateMaxTokens(for: text, bufferPercent: 30, maxLimit: 1024)

        let instruction = customPrompt.isEmpty ? DefaultPrompts.reformulate : customPrompt + "\n\n"
        let prompt = "\(instruction)\(text)\n\nRewritten text:"

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

    /// Reformulates the given text to be clearer and more professional
    /// - Parameter text: The text to reformulate
    /// - Returns: Reformulated text, or nil on failure
    func reformulate(_ text: String) async -> String? {
        return await process(text, customPrompt: "")
    }

    // MARK: - Post-processing

    func postProcess(_ output: String) -> String {
        let stopMarkers = [
            "\n\nThe ",
            "\n\nHere is",
            "\n\nNote:",
            "\n\nRewritten:",
            "\n\nThis version",
            "\n\n---"
        ]

        let prefixes = [
            "Rewritten:",
            "Rewritten version:",
            "Here is the rewritten text:",
            "The rewritten version is:",
            "rewritten:"
        ]

        return standardPostProcess(
            output,
            stopMarkers: stopMarkers,
            prefixes: prefixes,
            keepOnlyFirstParagraph: false  // Don't limit to first paragraph for reformulation
        )
    }
}
