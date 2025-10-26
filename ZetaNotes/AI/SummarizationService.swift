//
//  SummarizationService.swift
//  ZetaNotes
//
//  Generates concise summaries of notes
//  Uses extractive and abstractive techniques
//

import Foundation

/// Service for generating note summaries
/// Provides quick overviews for long-form content
class SummarizationService: AIService {
    let llmService: LLMInferenceService
    let config: AIGenerationConfig

    // MARK: - Configuration

    private enum Config {
        static let minLengthForSummary = 100 // Characters
        static let defaultSummaryLength = 100 // Characters
        static let maxTokens = 100
    }

    // MARK: - Initialization

    init(llmService: LLMInferenceService) {
        self.llmService = llmService
        // Get model-specific optimized config from registry
        let toolConfig = ModelToolConfigRegistry.getConfig(
            for: AIEngine.shared.selectedModel,
            toolType: .summarize
        )
        config = AIGenerationConfig(
            temperature: toolConfig.temperature,
            maxTokens: toolConfig.maxTokens ?? Config.maxTokens,
            usePromptAsUserMessage: toolConfig.usePromptAsUserMessage
        )
    }

    // MARK: - AIService Protocol

    func buildPrompt(for text: String) -> String {
        return DefaultPrompts.summarization.replacingOccurrences(of: "{content}", with: text)
    }

    // MARK: - AIService Override

    /// Override process to use custom prompt with batching support
    func process(_ text: String, customPrompt: String) async -> String? {
        print("📝 Summarize: Processing \(text.count) chars")

        // Use custom prompt with placeholder replacement
        let instruction = customPrompt.isEmpty ? DefaultPrompts.summarization : customPrompt

        // Use batched processing to handle large texts
        // For summaries, join chunks with newlines to create structured output
        let result = await processBatched(
            text,
            instruction: instruction,
            maxTokens: config.maxTokens,
            separator: "\n"
        )

        if let result = result {
            print("✅ Summarize: Generated \(result.count) chars")
        } else {
            print("❌ Summarize: Failed to generate output")
            ErrorLogger.shared.logError(
                code: .generationFailed,
                operation: "Summarization",
                technicalDetails: "Failed to generate summary. Input length: \(text.count) chars"
            )
        }

        return result
    }

    // MARK: - Summarization

    /// Generates a summary of the given text
    /// - Parameters:
    ///   - text: The text to summarize
    ///   - maxLength: Maximum length of summary in characters
    /// - Returns: Summary text, or nil if summarization fails
    func summarize(_ text: String, maxLength: Int = Config.defaultSummaryLength) async -> String? {
        // Use the batched process method instead of truncating
        return await process(text, customPrompt: "")
    }

    // MARK: - Post-processing

    func postProcess(_ output: String) -> String {
        // First apply centralized artifact removal
        var cleaned = LLMOutputCleaner.clean(output)

        // Remove common preamble patterns (case-insensitive)
        let preamblePatterns = [
            "a brief summary of the text:",
            "brief summary:",
            "summary of the text:",
            "here is a summary:",
            "here's a summary:",
            "the summary is:",
            "summary:",
            "in summary,",
            "to summarize,",
            "sure!",
            "sure,",
            "certainly!",
            "certainly,"
        ]

        for pattern in preamblePatterns {
            if let range = cleaned.range(of: pattern, options: .caseInsensitive) {
                if range.lowerBound == cleaned.startIndex ||
                   cleaned[..<range.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    cleaned = String(cleaned[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                    break
                }
            }
        }

        // Remove leading markdown quote character if present
        if cleaned.hasPrefix(">") {
            cleaned = cleaned.dropFirst().trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Generates summaries for multiple notes in batch
    /// - Parameter notes: Array of note objects
    /// - Returns: Dictionary mapping note IDs to summaries
    func batchSummarize(_ notes: [Note]) async -> [UUID: String] {
        var summaries: [UUID: String] = [:]

        for note in notes {
            guard let noteId = note.id, let content = note.content else { continue }

            if let summary = await summarize(content) {
                summaries[noteId] = summary
            }
        }

        return summaries
    }

    // MARK: - Fallback: Extractive Summarization

    /// Simple extractive summarization as fallback
    /// Takes the first few sentences up to maxLength
    private func extractiveSummary(from text: String, maxLength: Int) -> String {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var summary = ""

        for sentence in sentences {
            let potential = summary.isEmpty ? sentence : summary + ". " + sentence

            if potential.count > maxLength {
                break
            }

            summary = potential
        }

        if summary.isEmpty && !text.isEmpty {
            // Last resort: just truncate
            summary = String(text.prefix(maxLength))
            if summary.count == maxLength {
                summary += "..."
            }
        }

        return summary
    }
}
