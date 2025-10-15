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
        self.config = AIGenerationConfig(
            temperature: 0.3,
            maxTokens: 512,  // Will be overridden dynamically per request
            stopSequences: [
                "\n\n\n",  // Triple newline
                "\n---",   // Separator
                "\nNote:",
                "\nTranslation:",
                "\nThe translation",
                "\nHere is",
                "\nLet me",
                "\nI'll",
                "\nTo align"
            ]
        )
    }

    // MARK: - Configuration

    /// Sets the target language for translation
    /// - Parameter language: The language to translate to (e.g., "English", "Spanish")
    func setTargetLanguage(_ language: String) {
        self.targetLanguage = language
    }

    /// Gets the current target language
    func getTargetLanguage() -> String {
        return targetLanguage
    }

    // MARK: - AIService Protocol

    func buildPrompt(for text: String, customPrompt: String? = nil) -> String {
        // Use custom prompt if provided, otherwise use default from DefaultPrompts
        let instruction = if let customPrompt = customPrompt, !customPrompt.isEmpty {
            customPrompt.replacingOccurrences(of: "{language}", with: targetLanguage)
        } else {
            DefaultPrompts.translation.replacingOccurrences(of: "{language}", with: targetLanguage)
        }

        let prompt = "\(instruction)\(text)"

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

        let prompt = "\(finalInstruction)\n\n\(text)\n\n"

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
        let stopMarkers = [
            "\n\nThe ",
            "\n\nHere is",
            "\n\nNote:",
            "\n\nTranslation:",
            "\n\nTo align",
            "\n\nLet me",
            "\n\nI'll",
            "\n\nThis translation",
            "\n\n---",
        ]

        let prefixes = [
            "\(targetLanguage):",
            "Translation:",
            "Here is the translation:",
            "Here is the content:",
            "The translation is:",
            "Translated text:",
            "\(targetLanguage.lowercased()):",
            "translation:",
        ]

        // Use standard post-processing
        var cleaned = standardPostProcess(
            output,
            stopMarkers: stopMarkers,
            prefixes: prefixes,
            keepOnlyFirstParagraph: true
        )

        // Translation-specific: Remove garbage tokens at start (like "es:", "lsh:")
        if let colonIndex = cleaned.firstIndex(of: ":"),
           colonIndex.utf16Offset(in: cleaned) < 10 {
            let potentialPrefix = String(cleaned[..<colonIndex])
            if potentialPrefix.count < 6 && !potentialPrefix.contains(" ") {
                cleaned = String(cleaned[cleaned.index(after: colonIndex)...])
                    .trimmingCharacters(in: .whitespaces)
            }
        }

        print("🧹 Post-process cleaned output: \(cleaned)")
        return cleaned
    }
}
