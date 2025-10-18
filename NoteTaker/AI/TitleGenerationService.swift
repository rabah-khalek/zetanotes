//
//  TitleGenerationService.swift
//  NoteTaker
//
//  Generates concise titles for notes
//  Limits context and uses newline stop sequence for single-line output
//

import Foundation

/// Service for generating titles from note content
class TitleGenerationService: AIService {
    let llmService: LLMInferenceService
    let config: AIGenerationConfig

    // MARK: - Configuration

    private enum Config {
        static let contextLimit = 300 // Only use first 300 chars
        static let maxTokens = 15 // Keep titles short
    }

    // MARK: - Initialization

    init(llmService: LLMInferenceService) {
        self.llmService = llmService
        config = AIGenerationConfig(
            temperature: 0.2, // REDUCED from 0.3 for more focused titles
            maxTokens: Config.maxTokens,
            stopSequences: [
                "\n", // Stop at first newline for single-line titles
                "<|user|>", // Prevent fake user messages
                "<|system|>" // Prevent fake system messages
            ]
        )
    }

    // MARK: - AIService Protocol

    func buildPrompt(for text: String) -> String {
        // Limit context to first 300 characters
        let limitedText = String(text.prefix(Config.contextLimit))

        return DefaultPrompts.titleGeneration.replacingOccurrences(of: "{content}", with: limitedText)
    }

    // MARK: - AIService Override

    /// Override process to use custom prompt properly
    func process(_ text: String, customPrompt: String) async -> String? {
        // Limit context to first 300 characters
        let limitedText = String(text.prefix(Config.contextLimit))

        // Use custom prompt with placeholder replacement
        let instruction = customPrompt.isEmpty ? DefaultPrompts.titleGeneration : customPrompt
        let prompt = instruction.replacingOccurrences(of: "{content}", with: limitedText)

        guard let rawOutput = await llmService.generate(
            prompt: prompt,
            maxTokens: config.maxTokens, // Use fixed 15 tokens from config
            temperature: config.temperature,
            stopSequences: config.stopSequences
        ) else {
            return nil
        }

        let title = postProcess(rawOutput)
        return title.isEmpty ? nil : title
    }

    // MARK: - Public API

    /// Generates a title from the given text
    /// - Parameter text: The text to generate a title for
    /// - Returns: Generated title, or nil on failure
    func generateTitle(for text: String) async -> String? {
        return await process(text, customPrompt: "")
    }

    /// Generates a title with fallback to extractive method
    /// - Parameter text: The text to generate a title for
    /// - Returns: Generated or extracted title (never nil)
    func generateTitleWithFallback(for text: String) async -> String {
        if let generated = await generateTitle(for: text) {
            return generated
        }

        // Fallback: extract first few words
        return extractFallbackTitle(from: text)
    }

    /// Generates a title with custom prompt and fallback
    /// - Parameters:
    ///   - text: The text to generate a title for
    ///   - customPrompt: Custom prompt instructions
    /// - Returns: Generated or extracted title (never nil)
    func generateTitleWithFallback(for text: String, customPrompt: String) async -> String {
        if let generated = await process(text, customPrompt: customPrompt) {
            return generated
        }

        // Fallback: extract first few words
        return extractFallbackTitle(from: text)
    }

    // MARK: - Post-processing

    func postProcess(_ output: String) -> String {
        // Start with trimmed output
        var cleaned = output.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove TinyLlama chat template artifacts
        cleaned = cleaned.replacingOccurrences(of: "<|assistant|>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "</s>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "<|user|>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "<|system|>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "_id|>", with: "")

        // Remove leading markdown quote character if present
        if cleaned.hasPrefix(">") {
            cleaned = cleaned.dropFirst().trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Title-specific post-processing
        // Remove quotes
        cleaned = cleaned.replacingOccurrences(of: "\"", with: "")

        // Remove trailing punctuation
        while cleaned.hasSuffix(".") || cleaned.hasSuffix(":") ||
            cleaned.hasSuffix("!") || cleaned.hasSuffix("?") {
            cleaned = String(cleaned.dropLast())
        }

        // Apply title case
        cleaned = cleaned.split(separator: " ")
            .map { word in
                let lowercased = [
                    "a",
                    "an",
                    "the",
                    "and",
                    "but",
                    "or",
                    "for",
                    "nor",
                    "on",
                    "at",
                    "to",
                    "by",
                    "in",
                    "of"
                ]
                let wordStr = String(word)
                let isFirstWord = word == cleaned.split(separator: " ").first
                return lowercased.contains(wordStr.lowercased()) && !isFirstWord
                    ? wordStr.lowercased()
                    : wordStr.prefix(1).uppercased() + wordStr.dropFirst().lowercased()
            }
            .joined(separator: " ")

        // Limit to 8 words
        let words = cleaned.split(separator: " ").prefix(8)
        cleaned = words.map(String.init).joined(separator: " ")

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Private Helpers

    private func extractFallbackTitle(from text: String) -> String {
        let words = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")
            .prefix(5)
            .map(String.init)

        return words.isEmpty ? "Untitled Note" : words.joined(separator: " ")
    }
}
