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
        config = AIGenerationConfig(
            temperature: 0.2, // REDUCED from 0.3 - lower temp for more focused summaries
            maxTokens: Config.maxTokens,
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
        return "\(DefaultPrompts.summarization)\(text)</s>\n<|assistant|>\n"
    }

    // MARK: - AIService Override

    /// Override process to use custom prompt and respect maxTokens from config
    func process(_ text: String, customPrompt: String) async -> String? {
        // For very long text, truncate to first 2000 characters for performance
        let textToProcess = text.count > 2000 ? String(text.prefix(2000)) : text

        // Use custom prompt as-is if provided (user controls the format)
        // Otherwise use default prompt with proper chat template
        // Always close with the assistant tag
        let instruction = customPrompt.isEmpty ? DefaultPrompts.summarization : customPrompt
        let prompt = "\(instruction)\(textToProcess)</s>\n<|assistant|>\n"

        guard let rawOutput = await llmService.generate(
            prompt: prompt,
            maxTokens: config.maxTokens, // Use fixed 100 tokens from config
            temperature: config.temperature,
            stopSequences: config.stopSequences
        ) else {
            return nil
        }

        return postProcess(rawOutput)
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

        let prompt = buildPrompt(for: textToSummarize)
        print("📤 Sending prompt to LLM, length: \(prompt.count)")

        guard let summary = await llmService.generate(
            prompt: prompt,
            maxTokens: config.maxTokens,
            temperature: config.temperature,
            stopSequences: config.stopSequences
        ) else {
            print("⚠️ LLM returned nil, using extractive fallback")
            // Fallback: use extractive summarization
            return extractiveSummary(from: text, maxLength: maxLength)
        }

        print("📥 LLM returned: \(summary.prefix(100))...")
        let cleaned = postProcess(summary)
        print("🧹 Cleaned summary: \(cleaned)")

        if cleaned.isEmpty {
            print("⚠️ Cleaned summary is empty, using extractive fallback")
            return extractiveSummary(from: text, maxLength: maxLength)
        }

        return cleaned
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
            "Here is ", "Here's ", "Summary: ", "The summary is: ",
            "In summary, ", "To summarize, "
        ]
        for prefix in hallucinationPrefixes where cleaned.hasPrefix(prefix) {
            cleaned = String(cleaned.dropFirst(prefix.count))
            break
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
