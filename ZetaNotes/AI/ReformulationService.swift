//
//  ReformulationService.swift
//  ZetaNotes
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
        // Get model-specific optimized config from registry
        let toolConfig = ModelToolConfigRegistry.getConfig(
            for: AIEngine.shared.selectedModel,
            toolType: .rephrase
        )
        config = AIGenerationConfig(
            temperature: toolConfig.temperature,
            maxTokens: toolConfig.maxTokens
        )
    }

    // MARK: - AIService Protocol

    func buildPrompt(for text: String) -> String {
        return DefaultPrompts.reformulate.replacingOccurrences(of: "{content}", with: text)
    }

    // MARK: - AIService Override

    /// Override process to use custom prompt and dynamic max tokens with batching support
    func process(_ text: String, customPrompt: String) async -> String? {
        print("🔄 Reformulate: Processing \(text.count) chars")

        // Calculate dynamic max tokens with 30% buffer for expansion
        let maxTokens = calculateMaxTokens(for: text, bufferPercent: 30, maxLimit: 1024)

        // Use custom prompt as-is if provided (user controls the format)
        // Otherwise use default prompt with proper chat template
        let instruction = customPrompt.isEmpty ? DefaultPrompts.reformulate : customPrompt

        // Use batched processing to handle large texts
        let result = await processBatched(
            text,
            instruction: instruction,
            maxTokens: maxTokens,
            separator: " "
        )

        if let result = result {
            print("✅ Reformulate: Generated \(result.count) chars")
        } else {
            print("❌ Reformulate: Failed to generate output")
        }

        return result
    } // MARK: - Public API

    /// Reformulates the given text to be clearer and more professional
    /// - Parameter text: The text to reformulate
    /// - Returns: Reformulated text, or nil on failure
    func reformulate(_ text: String) async -> String? {
        return await process(text, customPrompt: "")
    }

    // MARK: - Post-processing

    func postProcess(_ output: String) -> String {
        // First apply centralized artifact removal
        var cleaned = LLMOutputCleaner.clean(output)

        // Remove everything before "Here is" if it contains explanation text
        if let range = cleaned.range(of: "Here is a rewritten version", options: .caseInsensitive),
           let colonRange = cleaned[range.lowerBound...].range(of: ":") {
            cleaned = String(cleaned[colonRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let range = cleaned.range(of: "Here is the rewritten", options: .caseInsensitive),
                  let colonRange = cleaned[range.lowerBound...].range(of: ":") {
            cleaned = String(cleaned[colonRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let range = cleaned.range(of: "Here is", options: .caseInsensitive),
                  let colonRange = cleaned[range.upperBound...].range(of: ":") {
            cleaned = String(cleaned[colonRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Remove common hallucination prefixes
        let hallucinationPrefixes = [
            "Sure! ", "Sure, ", "Certainly! ", "Certainly, ",
            "Here is ", "Here's ", "Rewritten: ", "Rewritten text: ",
            "Reformulated: ", "Reformulated text: "
        ]
        for prefix in hallucinationPrefixes where cleaned.hasPrefix(prefix) {
            cleaned = String(cleaned.dropFirst(prefix.count))
            break
        }

        // Remove leading markdown quote character if present
        if cleaned.hasPrefix(">") {
            cleaned = String(cleaned.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
