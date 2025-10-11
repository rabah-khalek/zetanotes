//
//  SummarizationService.swift
//  NoteTaker
//
//  Generates concise summaries of notes
//  Uses extractive and abstractive techniques
//

import Foundation

/// Service for generating note summaries
/// Provides quick overviews for long-form content
class SummarizationService {
    private let llmService: LLMInferenceService

    // MARK: - Configuration

    private struct Config {
        static let minLengthForSummary = 100 // Characters
        static let defaultSummaryLength = 100 // Characters
        static let maxTokens = 150
        static let temperature: Float = 0.5
    }

    // MARK: - Initialization

    init(llmService: LLMInferenceService) {
        self.llmService = llmService
    }

    // MARK: - Summarization

    /// Generates a summary of the given text
    /// - Parameters:
    ///   - text: The text to summarize
    ///   - maxLength: Maximum length of summary in characters
    /// - Returns: Summary text, or nil if summarization fails
    func summarize(_ text: String, maxLength: Int = Config.defaultSummaryLength) async -> String? {
        // For short text, just return it trimmed
        if text.count <= Config.minLengthForSummary {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // For very long text, truncate to first 2000 characters for performance
        let textToSummarize: String
        if text.count > 2000 {
            textToSummarize = String(text.prefix(2000))
        } else {
            textToSummarize = text
        }

        let prompt = buildSummarizationPrompt(text: textToSummarize, targetLength: maxLength)

        guard let summary = await llmService.generate(
            prompt: prompt,
            maxTokens: Config.maxTokens,
            temperature: Config.temperature,
            stopSequences: ["\n\n", "###", "---"]
        ) else {
            // Fallback: use extractive summarization
            return extractiveSummary(from: text, maxLength: maxLength)
        }

        let cleaned = cleanSummary(summary)
        return cleaned.isEmpty ? extractiveSummary(from: text, maxLength: maxLength) : cleaned
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

    // MARK: - Prompt Engineering

    private func buildSummarizationPrompt(text: String, targetLength: Int) -> String {
        return """
        Summarize the following text in approximately \(targetLength) characters. Be concise and capture the key points:

        \(text)

        Summary:
        """
    }

    private func cleanSummary(_ summary: String) -> String {
        var cleaned = summary.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove prompt artifacts
        cleaned = cleaned.replacingOccurrences(of: "Summary:", with: "")
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned
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
