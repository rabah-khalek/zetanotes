//
//  TranslationService.swift
//  ZetaNotes
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
        // Get model-specific optimized config from registry
        let toolConfig = ModelToolConfigRegistry.getConfig(
            for: AIEngine.shared.selectedModel,
            toolType: .translate
        )
        config = AIGenerationConfig(
            temperature: toolConfig.temperature,
            maxTokens: toolConfig.maxTokens
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
        let instruction = if let customPrompt = customPrompt, !customPrompt.isEmpty {
            customPrompt
        } else {
            DefaultPrompts.translation
        }

        let prompt = instruction
            .replacingOccurrences(of: "{language}", with: targetLanguage)
            .replacingOccurrences(of: "{content}", with: text)

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
        print("🌍 Translate: Processing \(text.count) chars to \(targetLanguage)")

        // Prepare instruction with language placeholder replacement
        let instruction = (customPrompt.isEmpty ? DefaultPrompts.translation : customPrompt)
            .replacingOccurrences(of: "{language}", with: targetLanguage)

        // Calculate dynamic max tokens with 50% buffer
        let maxTokens = calculateMaxTokens(for: text, bufferPercent: 50, maxLimit: 512)
        print("📊 Estimated max tokens needed: \(maxTokens)")

        // Use batched processing to handle large texts
        let result = await processBatched(
            text,
            instruction: instruction,
            maxTokens: maxTokens,
            separator: " "
        )

        if let result = result {
            // Validate that the output is actually a translation
            if !isValidTranslation(result, originalText: text) {
                print("❌ Translate: Output appears to be the same language as input")
                ErrorLogger.shared.logWarning(
                    code: WarningCode.generationEmpty,
                    operation: "Translation",
                    details: "Translating to \(targetLanguage). Model may not support this language or generated text too similar to input."
                )
                return nil
            }
            print("✅ Translate: Generated \(result.count) chars")
            return result
        } else {
            print("❌ Translate: Failed to generate output")
            ErrorLogger.shared.logError(
                code: ErrorCode.generationFailed,
                operation: "Translation",
                technicalDetails: "Failed to generate translation to \(targetLanguage). Input length: \(text.count) chars"
            )
            return nil
        }
    }

    // MARK: - Post-processing

    /// Custom post-processing for translation output
    /// Cleans up common artifacts from LLM output
    func postProcess(_ output: String) -> String {
        // First apply centralized artifact removal
        var cleaned = LLMOutputCleaner.clean(output)

        // Remove template artifacts that may leak through
        cleaned = cleaned.replacingOccurrences(of: "{content}user", with: "")
        cleaned = cleaned.replacingOccurrences(of: "{content}", with: "")
        cleaned = cleaned.replacingOccurrences(of: "{language}", with: "")

        // Remove everything before phrases like "Here is a revised version:" which indicate preamble
        if let range = cleaned.range(of: "Here is a revised version", options: .caseInsensitive),
           let colonRange = cleaned[range.lowerBound...].range(of: ":") {
            cleaned = String(cleaned[colonRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let range = cleaned.range(of: "Here is the translation", options: .caseInsensitive),
                  let colonRange = cleaned[range.lowerBound...].range(of: ":") {
            cleaned = String(cleaned[colonRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let range = cleaned.range(of: "Here is", options: .caseInsensitive),
                  let colonRange = cleaned[range.upperBound...].range(of: ":") {
            cleaned = String(cleaned[colonRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Remove partial continuation from original prompt (e.g., "to fit your needs")
        let partialPromptPhrases = [
            "to fit your needs",
            "to better suit your needs",
            "can modify the template",
            "Please let me know if"
        ]
        for phrase in partialPromptPhrases {
            if let range = cleaned.range(of: phrase, options: .caseInsensitive) {
                // Remove everything up to and including this phrase
                cleaned = String(cleaned[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }

        // Remove common hallucination prefixes (especially important for translation)
        let hallucinationPrefixes = [
            "Sure! ", "Sure, ", "Certainly! ", "Certainly, ",
            "Here is ", "Here's ", "Here is the ",
            "The translation is: ", "Translation: ", "Translated text: ",
            "I can help", "I'll translate", "I will translate",
            // Dynamic prefixes with target language
            "In \(targetLanguage): ", "The \(targetLanguage) translation is: ",
            "In \(targetLanguage.lowercased()): ", "The \(targetLanguage.lowercased()) translation is: "
        ]
        for prefix in hallucinationPrefixes where cleaned.lowercased().hasPrefix(prefix.lowercased()) {
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

    /// Validates that the translation output is not just repeating/paraphrasing the input
    /// Returns true if output appears to be a valid translation
    private func isValidTranslation(_ output: String, originalText: String) -> Bool {
        // If output is too similar to input, it's likely not translated
        let outputWords = Set(output.lowercased().split(separator: " ").map(String.init))
        let inputWords = Set(originalText.lowercased().split(separator: " ").map(String.init))

        // Calculate word overlap percentage
        let commonWords = outputWords.intersection(inputWords)
        let overlapPercentage = Double(commonWords.count) / Double(max(outputWords.count, 1)) * 100

        // If more than 70% of words are the same, it's likely not translated
        let isValid = overlapPercentage < 70

        if !isValid {
            print("⚠️ Translation validation failed: \(Int(overlapPercentage))% word overlap with original (target language: \(targetLanguage))")
        }

        return isValid
    }
}
