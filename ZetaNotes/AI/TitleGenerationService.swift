//
//  TitleGenerationService.swift
//  ZetaNotes
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
        static let maxTokens = 30 // Allow for 5-8 word titles (increased from 15)
    }

    // MARK: - Initialization

    init(llmService: LLMInferenceService) {
        self.llmService = llmService
        // Get model-specific optimized config from registry
        let toolConfig = ModelToolConfigRegistry.getConfig(
            for: AIEngine.shared.selectedModel,
            toolType: .titleGeneration
        )
        config = AIGenerationConfig(
            temperature: toolConfig.temperature,
            maxTokens: toolConfig.maxTokens ?? Config.maxTokens
        )
    }

    // MARK: - AIService Protocol

    func buildPrompt(for text: String) -> String {
        // Use ModelToolConfigRegistry for consistent configuration
        let toolConfig = ModelToolConfigRegistry.getConfig(
            for: AIEngine.shared.selectedModel,
            toolType: .titleGeneration
        )
        return toolConfig.prompt.replacingOccurrences(of: "{content}", with: text)
    }

    // MARK: - AIService Override

    /// Override process to use direct completion instead of chat template
    /// This works better for title generation with small models
    func process(_ text: String, customPrompt: String) async -> String? {
        print("📋 Title: Processing \(text.count) chars")

        // Get model-specific config from ModelToolConfigRegistry
        let toolConfig = ModelToolConfigRegistry.getConfig(
            for: AIEngine.shared.selectedModel,
            toolType: .titleGeneration
        )

        // Use custom prompt if provided, otherwise use model-optimized prompt
        let instruction = customPrompt.isEmpty ? toolConfig.prompt : customPrompt

        // For title generation, use direct completion with explicit constraints
        // Tell the model: generate only a short title (2-4 words), no line breaks
        let completionPrompt = """
        Text: \(text)

        Generate a 2-4 word title (no line breaks):
        """

        print("🔍 Title: Using direct completion format")

        // Use direct generate() instead of chat template
        let result = await llmService.generate(
            prompt: completionPrompt,
            maxTokens: toolConfig.maxTokens ?? Config.maxTokens,
            temperature: toolConfig.temperature
        )

        if let result = result {
            print("🔍 Title: Raw model output: '\(result)'")
            let title = postProcess(result)
            let finalTitle = title.isEmpty ? nil : title

            if let finalTitle = finalTitle {
                print("✅ Title: Final output: '\(finalTitle)'")
            } else {
                print("❌ Title: Post-processing resulted in empty output")
            }

            return finalTitle
        } else {
            print("❌ Title: Failed to generate output")
            return nil
        }
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
        // First apply centralized artifact removal
        var cleaned = LLMOutputCleaner.clean(output)

        // Take only first line
        if let firstLine = cleaned.components(separatedBy: .newlines).first {
            cleaned = firstLine
        }

        // Remove "Title:" prefix if model echoes it back
        if cleaned.lowercased().hasPrefix("title:") {
            cleaned = String(cleaned.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Remove quotes
        cleaned = cleaned.replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "'", with: "")

        // Remove trailing punctuation
        while !cleaned.isEmpty && (cleaned.last == "." || cleaned.last == ":" ||
            cleaned.last == "!" || cleaned.last == "?" || cleaned.last == ",") {
            cleaned = String(cleaned.dropLast())
        }

        // Apply title case
        cleaned = cleaned.split(separator: " ")
            .enumerated()
            .map { index, word in
                let lowercased = ["a", "an", "the", "and", "but", "or", "for", "nor", "on", "at", "to", "by", "in", "of"]
                let wordStr = String(word)
                let isFirstWord = (index == 0)
                return lowercased.contains(wordStr.lowercased()) && !isFirstWord
                    ? wordStr.lowercased()
                    : wordStr.prefix(1).uppercased() + wordStr.dropFirst().lowercased()
            }
            .joined(separator: " ")

        // Limit to 8 words max
        let words = cleaned.split(separator: " ").prefix(8)
        cleaned = words.map(String.init).joined(separator: " ")

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Private Helpers

    private func extractFallbackTitle(from text: String) -> String {
        // Skip common letter openings
        var workingText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Skip greeting lines (Dear X, Hi there, etc.)
        let lines = workingText.components(separatedBy: .newlines)
        if lines.count > 1 {
            let firstLine = lines[0].trimmingCharacters(in: .whitespacesAndNewlines)
            // If first line looks like a greeting, use second line
            if firstLine.hasPrefix("Dear") || firstLine.hasPrefix("Hi") ||
               firstLine.hasPrefix("Hello") || firstLine.hasPrefix("To") ||
               firstLine.count < 20 { // Very short first line, probably greeting
                workingText = lines.dropFirst().joined(separator: " ")
            }
        }

        // Extract first meaningful sentence (up to period or 50 chars)
        if let periodIndex = workingText.firstIndex(of: ".") {
            let sentence = String(workingText[..<periodIndex])
            if sentence.count > 10 && sentence.count < 50 {
                workingText = sentence
            }
        }

        // Take first 4-6 words
        let words = workingText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")
            .prefix(6)
            .map(String.init)

        return words.isEmpty ? "Untitled Note" : words.joined(separator: " ")
    }
}
