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
        config = AIGenerationConfig(
            temperature: 0.05, // Very low for deterministic corrections
            maxTokens: nil, // Will be calculated dynamically
            stopSequences: [
                // Note: </s> is handled natively by llama.cpp (llama_vocab_is_eog)
                "<|user|>", // Prevent fake user messages
                "<|system|>", // Prevent fake system messages
                "\n\nText:", // Stop if it tries to repeat the input prompt
                "\n---\n`" // Service delimiter start
            ]
        )
    }

    // MARK: - AIService Protocol

    func buildPrompt(for text: String) -> String {
        return DefaultPrompts.autoCorrect.replacingOccurrences(of: "{content}", with: text)
    }

    // MARK: - AIService Override

    /// Override process to use custom prompt and dynamic max tokens
    func process(_ text: String, customPrompt: String) async -> String? {
        // Calculate dynamic max tokens with 20% buffer for corrections
        let maxTokens = calculateMaxTokens(for: text, bufferPercent: 20, maxLimit: 1024)

        // Use custom prompt as-is if provided (user controls the format)
        // Otherwise use default prompt with proper chat template
        let instruction = customPrompt.isEmpty ? DefaultPrompts.autoCorrect : customPrompt
        let prompt = instruction.replacingOccurrences(of: "{content}", with: text)

        guard let rawOutput = await llmService.generate(
            prompt: prompt,
            maxTokens: maxTokens,
            temperature: config.temperature,
            stopSequences: config.stopSequences
        ) else {
            return nil
        }

        return postProcess(rawOutput)
    } // MARK: - Public API

    /// Corrects spelling and grammar in the given text
    /// - Parameter text: The text to correct
    /// - Returns: Corrected text, or nil on failure
    func correct(_ text: String) async -> String? {
        return await process(text, customPrompt: "")
    }

    // MARK: - Post-processing

    func postProcess(_ output: String) -> String {
        var cleaned = output.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove model-specific artifacts
        cleaned = cleaned.replacingOccurrences(of: "<|assistant|>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "</s>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "<|user|>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "<|system|>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "_id|>", with: "")

        // Remove everything before "Here is" if it contains explanation text
        if let range = cleaned.range(of: "Here is the corrected text:", options: .caseInsensitive) {
            cleaned = String(cleaned[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let range = cleaned.range(of: "Here is the corrected version:", options: .caseInsensitive) {
            cleaned = String(cleaned[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let range = cleaned.range(of: "Here is", options: .caseInsensitive),
                  let colonRange = cleaned[range.upperBound...].range(of: ":") {
            cleaned = String(cleaned[colonRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Remove common hallucination prefixes
        let hallucinationPrefixes = [
            "Sure! ", "Sure, ", "Certainly! ", "Certainly, ",
            "Here is ", "Here's ", "Corrected: ", "Corrected text: ",
            "The text is grammatically correct", "I found a few", "I've corrected"
        ]
        for prefix in hallucinationPrefixes where cleaned.hasPrefix(prefix) {
            // If it's a sentence explaining changes, skip to next paragraph
            if prefix.contains("text is") || prefix.contains("found") || prefix.contains("corrected") {
                if let doubleNewline = cleaned.range(of: "\n\n") {
                    cleaned = String(cleaned[doubleNewline.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            } else {
                cleaned = String(cleaned.dropFirst(prefix.count))
            }
            break
        }

        // Remove leading markdown quote character if present
        if cleaned.hasPrefix(">") {
            cleaned = String(cleaned.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
