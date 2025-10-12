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
        static let maxTokens = 100
        static let temperature: Float = 0.3 // Lower temperature for more focused summaries
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
        print("📝 SummarizationService: Starting summarization, text length: \(text.count)")

        // For short text, just return it trimmed
        if text.count <= Config.minLengthForSummary {
            print("ℹ️ Text too short (\(text.count) < \(Config.minLengthForSummary)), returning as-is")
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // For very long text, truncate to first 2000 characters for performance
        let textToSummarize: String
        if text.count > 2000 {
            textToSummarize = String(text.prefix(2000))
            print("✂️ Text truncated to 2000 chars for performance")
        } else {
            textToSummarize = text
        }

        let prompt = buildSummarizationPrompt(text: textToSummarize, targetLength: maxLength)
        print("📤 Sending prompt to LLM, length: \(prompt.count)")

        guard let summary = await llmService.generate(
            prompt: prompt,
            maxTokens: Config.maxTokens,
            temperature: Config.temperature,
            stopSequences: ["\n\n", "###", "---"]
        ) else {
            print("⚠️ LLM returned nil, using extractive fallback")
            // Fallback: use extractive summarization
            return extractiveSummary(from: text, maxLength: maxLength)
        }

        print("📥 LLM returned: \(summary.prefix(100))...")
        let cleaned = cleanSummary(summary)
        print("🧹 Cleaned summary: \(cleaned)")

        if cleaned.isEmpty {
            print("⚠️ Cleaned summary is empty, using extractive fallback")
            return extractiveSummary(from: text, maxLength: maxLength)
        }

        return cleaned
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
        \(text)

        Summarize in one clear sentence. Be concise:
        """
    }

    private func cleanSummary(_ summary: String) -> String {
        // No postprocessing - return raw output
        return summary
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
