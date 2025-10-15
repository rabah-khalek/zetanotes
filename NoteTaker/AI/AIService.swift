//
//  AIService.swift
//  NoteTaker
//
//  Base protocol for all AI text processing services
//  Provides consistent interface for LLM-based operations
//

import Foundation

/// Configuration for AI text generation
struct AIGenerationConfig {
    let temperature: Float
    let maxTokens: Int?
    let stopSequences: [String]

    init(
        temperature: Float = 0.7,
        maxTokens: Int? = nil,
        stopSequences: [String] = []
    ) {
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.stopSequences = stopSequences
    }
}

/// Base protocol for AI text processing services
/// All AI services that process text through the LLM should conform to this
protocol AIService {
    /// The underlying LLM inference service
    var llmService: LLMInferenceService { get }

    /// Configuration for this service's generation parameters
    var config: AIGenerationConfig { get }

    /// Builds the prompt for the given input text
    /// - Parameter text: The input text to process
    /// - Returns: The formatted prompt ready for the LLM
    func buildPrompt(for text: String) -> String

    /// Post-processes the raw LLM output
    /// - Parameter output: The raw output from the LLM
    /// - Returns: The cleaned/processed output
    func postProcess(_ output: String) -> String

    /// Processes the input text through the LLM
    /// - Parameter text: The input text to process
    /// - Returns: The processed output, or nil on failure
    func process(_ text: String) async -> String?
}

/// Common utilities for all AI services
extension AIService {
    // MARK: - Token Estimation

    /// Estimates the number of tokens for a given text
    /// Uses rough approximation: 1 token ≈ 2.5 characters
    /// - Parameter text: The text to estimate
    /// - Returns: Estimated token count
    func estimateTokens(for text: String) -> Int {
        return Int(Double(text.count) * 0.4)
    }

    /// Calculates dynamic max tokens with a buffer percentage
    /// - Parameters:
    ///   - text: The input text
    ///   - bufferPercent: Buffer percentage (e.g., 50 for 50% buffer)
    ///   - maxLimit: Maximum token limit
    /// - Returns: Calculated max tokens
    func calculateMaxTokens(for text: String, bufferPercent: Int, maxLimit: Int) -> Int {
        let estimated = estimateTokens(for: text)
        let withBuffer = estimated + (estimated * bufferPercent / 100)
        return min(withBuffer, maxLimit)
    }

    // MARK: - Post-Processing Utilities

    /// Removes common hallucination markers from output
    /// - Parameters:
    ///   - text: The text to clean
    ///   - markers: Custom markers (uses defaults if nil)
    /// - Returns: Cleaned text
    func removeHallucinationMarkers(from text: String, markers: [String]? = nil) -> String {
        var cleaned = text

        let stopMarkers = markers ?? [
            "\n\nThe ",
            "\n\nHere is",
            "\n\nNote:",
            "\n\n---"
        ]

        for marker in stopMarkers {
            if let range = cleaned.range(of: marker) {
                cleaned = String(cleaned[..<range.lowerBound])
                break
            }
        }

        return cleaned
    }

    /// Removes common prefixes that LLMs add to outputs
    /// - Parameters:
    ///   - text: The text to clean
    ///   - prefixes: Custom prefixes (uses defaults if nil)
    /// - Returns: Cleaned text
    func removePrefixes(from text: String, prefixes: [String]? = nil) -> String {
        var cleaned = text

        let commonPrefixes = prefixes ?? [
            "Here is",
            "Here's",
            "The result is:",
            "Result:"
        ]

        for prefix in commonPrefixes {
            let variations = [
                prefix,
                prefix.lowercased(),
                prefix + ":"
            ]

            for variation in variations {
                if cleaned.hasPrefix(variation) {
                    cleaned = String(cleaned.dropFirst(variation.count))
                        .trimmingCharacters(in: .whitespaces)
                    break
                }
            }
        }

        return cleaned
    }

    /// Keeps only the first paragraph from output
    /// Useful when LLM generates multiple paragraphs with explanations
    /// - Parameters:
    ///   - text: The text to process
    ///   - minLength: Minimum length to consider keeping just first paragraph
    /// - Returns: First paragraph if substantial, otherwise original text
    func keepFirstParagraph(from text: String, minLength: Int = 10) -> String {
        if let doubleNewline = text.range(of: "\n\n") {
            let firstParagraph = String(text[..<doubleNewline.lowerBound])
            if firstParagraph.count > minLength {
                return firstParagraph
            }
        }
        return text
    }

    /// Standard post-processing pipeline
    /// - Parameters:
    ///   - output: Raw LLM output
    ///   - stopMarkers: Custom stop markers
    ///   - prefixes: Custom prefixes to remove
    ///   - keepOnlyFirstParagraph: Whether to keep only first paragraph
    /// - Returns: Cleaned output
    func standardPostProcess(
        _ output: String,
        stopMarkers: [String]? = nil,
        prefixes: [String]? = nil,
        keepOnlyFirstParagraph: Bool = true
    ) -> String {
        var cleaned = output.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove hallucination markers
        cleaned = removeHallucinationMarkers(from: cleaned, markers: stopMarkers)

        // Remove common prefixes
        cleaned = removePrefixes(from: cleaned, prefixes: prefixes)

        // Keep only first paragraph if requested
        if keepOnlyFirstParagraph {
            cleaned = keepFirstParagraph(from: cleaned)
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// Default implementation for AIService
extension AIService {
    /// Default implementation of process() using buildPrompt and postProcess
    func process(_ text: String) async -> String? {
        guard !text.isEmpty else { return nil }

        let prompt = buildPrompt(for: text)

        guard let rawOutput = await llmService.generate(
            prompt: prompt,
            maxTokens: config.maxTokens,
            temperature: config.temperature,
            stopSequences: config.stopSequences
        ) else {
            return nil
        }

        return postProcess(rawOutput)
    }

    /// Process with custom prompt
    /// - Parameters:
    ///   - text: The text to process
    ///   - customPrompt: Custom prompt instructions to use
    ///   - defaultPrompt: Default prompt to use if custom is empty
    ///   - maxTokens: Optional max tokens override
    /// - Returns: Processed output, or nil on failure
    func processWithCustomPrompt(
        _ text: String,
        customPrompt: String,
        defaultPrompt: String,
        maxTokens: Int? = nil
    ) async -> String? {
        guard !text.isEmpty else { return nil }

        // Use custom prompt if not empty, otherwise use default
        let instruction = customPrompt.isEmpty ? defaultPrompt : customPrompt

        let prompt = """
        \(instruction)

        \(text)
        """

        guard let rawOutput = await llmService.generate(
            prompt: prompt,
            maxTokens: maxTokens ?? config.maxTokens,
            temperature: config.temperature,
            stopSequences: config.stopSequences
        ) else {
            return nil
        }

        return postProcess(rawOutput)
    }

    /// Default post-processing: trim whitespace
    func postProcess(_ output: String) -> String {
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
