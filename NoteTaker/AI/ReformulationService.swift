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
            temperature: 0.2,   // REDUCED from 0.4 - TinyLlama needs lower temp to avoid hallucinations
            maxTokens: nil,     // Will be calculated dynamically
            stopSequences: [
                // Note: </s> is handled natively by llama.cpp (llama_vocab_is_eog)
                "<|user|>",     // Prevent fake user messages
                "<|system|>",   // Prevent fake system messages
                "\n\nText:",    // Stop if it tries to repeat the input prompt
                "\n---\n`"      // Service delimiter start
            ]
        )
    }

    // MARK: - AIService Protocol

    func buildPrompt(for text: String) -> String {
        return "\(DefaultPrompts.reformulate)\(text)</s>\n<|assistant|>\n"
    }

    // MARK: - AIService Override

    /// Override process to use custom prompt and dynamic max tokens
    func process(_ text: String, customPrompt: String) async -> String? {
        // Calculate dynamic max tokens with 30% buffer for expansion
        let maxTokens = calculateMaxTokens(for: text, bufferPercent: 30, maxLimit: 1024)

        // Use custom prompt as-is if provided (user controls the format)
        // Otherwise use default prompt with proper chat template
        // Always close with the assistant tag
        let instruction = customPrompt.isEmpty ? DefaultPrompts.reformulate : customPrompt
        let prompt = "\(instruction)\(text)</s>\n<|assistant|>\n"

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
        var cleaned = output.trimmingCharacters(in: .whitespacesAndNewlines)

        // First apply default TinyLlama artifact removal
        cleaned = cleaned.replacingOccurrences(of: "<|assistant|>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "</s>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "<|user|>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "<|system|>", with: "")

        // Remove common hallucination prefixes
        let hallucinationPrefixes = [
            "Sure! ", "Sure, ", "Certainly! ", "Certainly, ",
            "Here is ", "Here's ", "Rewritten: ", "Rewritten text: ",
            "Reformulated: ", "Reformulated text: "
        ]
        for prefix in hallucinationPrefixes {
            if cleaned.hasPrefix(prefix) {
                cleaned = String(cleaned.dropFirst(prefix.count))
                break
            }
        }

        // Remove leading markdown quote character if present
        if cleaned.hasPrefix(">") {
            cleaned = cleaned.dropFirst().trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
