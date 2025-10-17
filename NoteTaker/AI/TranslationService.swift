//
//  TranslationService.swift
//  NoteTaker
//
//  Translates text between languages
//  Uses simple completion-style prompts for better performance with small models
//

import Foundation

/// Service for translating text between languages
class TranslationService: AIService {
    let llmService: LLMInferenceService
    let config: AIGenerationConfig

    private var targetLanguage: String = "English"

    // MARK: - Initialization

    init(llmService: LLMInferenceService) {
        self.llmService = llmService
        config = AIGenerationConfig(
            temperature: 0.1, // REDUCED from 0.3 - translation needs high accuracy, low creativity
            maxTokens: 512, // Will be overridden dynamically per request
            stopSequences: [
                // Note: </s> is handled natively by llama.cpp (llama_vocab_is_eog)
                "<|user|>", // Prevent fake user messages
                "<|system|>", // Prevent fake system messages
                "\n\nText:", // Stop if it tries to repeat the input prompt
                "\n\nOutput:", // Stop if it hallucinates continuation
                "\n---\n`" // Service delimiter start
            ]
        )
    }

    // MARK: - Configuration

    /// Sets the target language for translation
    /// - Parameter language: The language to translate to (e.g., "English", "Spanish")
    func setTargetLanguage(_ language: String) {
        targetLanguage = language
    }

    /// Gets the current target language
    func getTargetLanguage() -> String {
        return targetLanguage
    }

    // MARK: - AIService Protocol

    func buildPrompt(for text: String, customPrompt: String? = nil) -> String {
        // Use custom prompt as-is if provided (user controls the format)
        // Otherwise use default prompt with proper chat template
        // Always close with the assistant tag
        let instruction = if let customPrompt = customPrompt, !customPrompt.isEmpty {
            customPrompt.replacingOccurrences(of: "{language}", with: targetLanguage)
        } else {
            DefaultPrompts.translation.replacingOccurrences(of: "{language}", with: targetLanguage)
        }

        let prompt = "\(instruction)\(text)</s>\n<|assistant|>\n"

        print("🌍 Translation prompt built:")
        print("📝 Using: \(customPrompt != nil && !customPrompt!.isEmpty ? "custom prompt" : "default prompt")")
        print("🎯 Target language: \(targetLanguage)")
        print("📄 Text length: \(text.count) characters")

        return prompt
    }

    // Override buildPrompt to match AIService protocol
    func buildPrompt(for text: String) -> String {
        return buildPrompt(for: text, customPrompt: nil)
    }

    // MARK: - AIService Override

    /// Override process to use dynamic max tokens
    func process(_ text: String) async -> String? {
        return await translate(text, withPrompt: "")
    }

    // MARK: - Public API

    /// Translates the given text to the target language
    /// - Parameters:
    ///   - text: The text to translate
    ///   - to: The target language (optional, uses default if not specified)
    /// - Returns: Translated text, or nil on failure
    func translate(_ text: String, to language: String? = nil) async -> String? {
        if let language = language {
            let previousLanguage = targetLanguage
            setTargetLanguage(language)
            let result = await translate(text, withPrompt: "")
            setTargetLanguage(previousLanguage)
            return result
        } else {
            return await translate(text, withPrompt: "")
        }
    }

    /// Translates with optional custom prompt template
    /// - Parameters:
    ///   - text: The text to translate
    ///   - customPrompt: Optional custom prompt template (use {language} as placeholder)
    /// - Returns: Translated text, or nil on failure
    func translate(_ text: String, withPrompt customPrompt: String) async -> String? {
        print("🌍 Starting translation")

        // Prepare prompt instruction
        let instruction = customPrompt.isEmpty
            ? DefaultPrompts.translation
            : customPrompt
        let finalInstruction = instruction.replacingOccurrences(of: "{language}", with: targetLanguage)

        // CRITICAL FIX: Use proper chat template closing like other services
        let prompt = "\(finalInstruction)\(text)</s>\n<|assistant|>\n"

        // Calculate dynamic max tokens with 50% buffer
        let maxTokens = calculateMaxTokens(for: text, bufferPercent: 50, maxLimit: 512)
        print("📊 Estimated max tokens needed: \(maxTokens)")

        guard let rawOutput = await llmService.generate(
            prompt: prompt,
            maxTokens: maxTokens,
            temperature: config.temperature,
            stopSequences: config.stopSequences
        ) else {
            print("❌ Translation generation returned nil")
            return nil
        }

        print("✅ Raw translation output (\(rawOutput.count) chars): \(rawOutput)")
        let processed = postProcess(rawOutput)
        print("✅ Post-processed translation (\(processed.count) chars): \(processed)")

        return processed
    }

    // MARK: - Post-processing

    /// Custom post-processing for translation output
    /// Cleans up common artifacts from LLM output
    func postProcess(_ output: String) -> String {
        var cleaned = output.trimmingCharacters(in: .whitespacesAndNewlines)

        // First apply default TinyLlama artifact removal
        cleaned = cleaned.replacingOccurrences(of: "<|assistant|>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "</s>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "<|user|>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "<|system|>", with: "")

        // Remove common hallucination prefixes (especially important for translation)
        let hallucinationPrefixes = [
            "Sure! ", "Sure, ", "Certainly! ", "Certainly, ",
            "Here is ", "Here's ", "Here is the ",
            "The translation is: ", "Translation: ", "Translated text: ",
            "In \(targetLanguage): ", "The \(targetLanguage) translation is: "
        ]
        for prefix in hallucinationPrefixes where cleaned.hasPrefix(prefix) {
            cleaned = String(cleaned.dropFirst(prefix.count))
            break
        }

        // Remove leading markdown quote character if present
        if cleaned.hasPrefix(">") {
            cleaned = cleaned.dropFirst().trimmingCharacters(in: .whitespacesAndNewlines)
        }

        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        print("🧹 Post-process cleaned output: \(cleaned)")
        return cleaned
    }
}
