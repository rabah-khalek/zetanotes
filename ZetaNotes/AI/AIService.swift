//
//  AIService.swift
//  ZetaNotes
//
//  Base protocol for all AI text processing services
//  Provides consistent interface for LLM-based operations
//

import Foundation

/// Configuration for AI text generation
struct AIGenerationConfig {
    let temperature: Float
    let maxTokens: Int?
    let usePromptAsUserMessage: Bool

    init(
        temperature: Float = 0.7,
        maxTokens: Int? = nil,
        usePromptAsUserMessage: Bool = true
    ) {
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.usePromptAsUserMessage = usePromptAsUserMessage
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
    // MARK: - Batch Processing

    /// Processes text in batches to handle content larger than model batch size
    /// Chunks text by sentences and processes each chunk separately
    /// - Parameters:
    ///   - text: The text to process
    ///   - instruction: The instruction/prompt template (should contain {content} placeholder)
    ///   - maxTokens: Optional max tokens per generation
    ///   - separator: String to join processed chunks (default: single space)
    /// - Returns: Combined processed output, or nil on failure
    func processBatched(
        _ text: String,
        instruction: String,
        maxTokens: Int? = nil,
        separator: String = " "
    ) async -> String? {
        guard !text.isEmpty else { return nil }

        // Get the current model's batch size and calculate chunk size
        // Leave 30% buffer for the prompt template overhead
        let modelBatchSize = Int(llmService.getCurrentModel().optimalBatchSize)
        let maxTokensPerChunk = Int(Double(modelBatchSize) * 0.7)

        // Create chunker with model-aware token limit
        let chunker = TextChunker(maxTokensPerChunk: maxTokensPerChunk)
        let chunks = chunker.chunk(text)

        // If only one chunk, process normally without batching
        if chunks.count == 1 {
            // Check if we should use prompt as user message or system message
            let (systemMsg, userMsg) = config.usePromptAsUserMessage
                ? ("Respond only with the requested output.", instruction + text)  // System reminder, combine instruction and text in user message
                : (instruction, text)        // Separate system instruction and user text

            // Use chat template for proper formatting
            guard let rawOutput = await llmService.generateWithChatTemplate(
                systemMessage: systemMsg,
                userMessage: userMsg,
                maxTokens: maxTokens ?? config.maxTokens,
                temperature: config.temperature
            ) else {
                return nil
            }
            return postProcess(rawOutput)
        }

        // Process each chunk
        print("Processing large text in \(chunks.count) batches...")
        var processedChunks: [String] = []

        for (index, chunk) in chunks.enumerated() {
            print("   Batch \(index + 1)/\(chunks.count): \(chunk.count) chars")

            // Check if we should use prompt as user message or system message
            let (systemMsg, userMsg) = config.usePromptAsUserMessage
                ? ("Respond only with the requested output.", instruction + chunk)  // System reminder, combine instruction and chunk in user message
                : (instruction, chunk)        // Separate system instruction and user chunk

            // Use chat template for proper formatting
            guard let rawOutput = await llmService.generateWithChatTemplate(
                systemMessage: systemMsg,
                userMessage: userMsg,
                maxTokens: maxTokens ?? config.maxTokens,
                temperature: config.temperature
            ) else {
                print("Batch \(index + 1) failed, skipping")
                continue
            }

            let processed = postProcess(rawOutput)
            if !processed.isEmpty {
                processedChunks.append(processed)
            } else {
                print("Batch \(index + 1) produced empty output after post-processing")
            }
        }

        if processedChunks.isEmpty {
            print("All batches failed")
            return nil
        }

        print("Successfully processed \(processedChunks.count)/\(chunks.count) batches")
        let result = processedChunks.joined(separator: separator)
        print("Final output length: \(result.count) chars")
        return result
    }

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
            "\n\n#### " // New service delimiter format
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
    /// Handles both exact matches and continuations (e.g., "Summary:" matching "Summarize the...")
    /// - Parameters:
    ///   - text: The text to clean
    ///   - prefixes: Custom prefixes (uses defaults if nil)
    /// - Returns: Cleaned text
    func removePrefixes(from text: String, prefixes: [String]? = nil) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespaces)

        let commonPrefixes = prefixes ?? [
            "Here is",
            "Here's",
            "The result is:",
            "Result:"
        ]

        for prefix in commonPrefixes {
            // Remove trailing colon and spaces from prefix for base matching
            let basePrefix = prefix.trimmingCharacters(in: CharacterSet(charactersIn: ": "))
            let basePrefixLower = basePrefix.lowercased()
            let cleanedLower = cleaned.lowercased()

            // Check if text starts with this prefix (case-insensitive)
            if cleanedLower.hasPrefix(basePrefixLower) {
                // Find the first word boundary in the ENTIRE string
                // This removes the first word completely, handling extended forms like "Summarize"
                if let firstBoundary = cleaned.firstIndex(where: { $0.isWhitespace || $0 == ":" || $0 == "\n" }) {
                    // Remove everything up to (and including) the first word boundary
                    cleaned = String(cleaned[firstBoundary...]).trimmingCharacters(in: .whitespaces)
                } else {
                    // No boundary found - the entire text is just the prefix word
                    cleaned = ""
                }
                break
            }
        }

        // Remove any remaining standalone colons or punctuation at the start
        while !cleaned.isEmpty {
            let firstChar = cleaned.first!
            if firstChar == ":" || (firstChar.isPunctuation && !firstChar.isLetter) {
                cleaned = String(cleaned.dropFirst())
                    .trimmingCharacters(in: .whitespaces)
            } else {
                break
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
        // Find all occurrences of "\n\n"
        var searchRange = text.startIndex ..< text.endIndex

        while let doubleNewline = text.range(of: "\n\n", range: searchRange) {
            // Check if this is part of a service delimiter ("\n\n#### ")
            let afterNewlines = doubleNewline.upperBound
            if afterNewlines < text.endIndex {
                let remainingText = text[afterNewlines...]
                // Skip if this "\n\n" is followed by "#### " (service delimiter)
                if remainingText.hasPrefix("#### ") {
                    searchRange = afterNewlines ..< text.endIndex
                    continue
                }
            }

            // This is a real paragraph break, not a service delimiter
            let firstParagraph = String(text[..<doubleNewline.lowerBound])
            if firstParagraph.count > minLength {
                return firstParagraph
            }
            break
        }

        return text
    }

    /// Skips first paragraph if it looks like a label/prefix and keeps the actual content
    /// Useful when LLM outputs "Summary:\n\nActual summary..." and you want just the summary
    /// - Parameters:
    ///   - text: The text to process
    ///   - maxPrefixLength: Maximum length of prefix paragraph to skip (defaults to 50)
    /// - Returns: Text after first paragraph if first paragraph is short, otherwise original text
    func skipPrefixParagraph(from text: String, maxPrefixLength: Int = 50) -> String {
        // Find first real paragraph break (not service delimiter)
        var searchRange = text.startIndex ..< text.endIndex

        while let doubleNewline = text.range(of: "\n\n", range: searchRange) {
            // Check if this is part of a service delimiter ("\n\n#### ")
            let afterNewlines = doubleNewline.upperBound
            if afterNewlines < text.endIndex {
                let remainingText = text[afterNewlines...]
                // Skip if this "\n\n" is followed by "#### " (service delimiter)
                if remainingText.hasPrefix("#### ") {
                    searchRange = afterNewlines ..< text.endIndex
                    continue
                }
            }

            // Found a real paragraph break
            let firstParagraph = String(text[..<doubleNewline.lowerBound])

            // If first paragraph is short (likely a label like "Summary:"), skip it
            if firstParagraph.count <= maxPrefixLength {
                return String(text[afterNewlines...]).trimmingCharacters(in: .whitespacesAndNewlines)
            }

            // First paragraph is substantial, keep everything
            break
        }

        return text
    }

    /// Standard post-processing pipeline
    /// - Parameters:
    ///   - output: Raw LLM output
    ///   - stopMarkers: Custom stop markers
    ///   - prefixes: Custom prefixes to remove
    ///   - keepOnlyFirstParagraph: Whether to keep only first paragraph
    ///   - skipLabelParagraph: Whether to skip label-like first paragraphs (e.g., "Summary:\n\n")
    /// - Returns: Cleaned output
    func standardPostProcess(
        _ output: String,
        stopMarkers: [String]? = nil,
        prefixes: [String]? = nil,
        keepOnlyFirstParagraph: Bool = true,
        skipLabelParagraph: Bool = false
    ) -> String {
        var cleaned = output.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove hallucination markers
        cleaned = removeHallucinationMarkers(from: cleaned, markers: stopMarkers)

        // Skip prefix paragraph if present (e.g., "Summary:\n\nActual content")
        // This removes label-like first paragraphs that LLMs sometimes add
        if skipLabelParagraph {
            cleaned = skipPrefixParagraph(from: cleaned)
        }

        // Remove common prefixes from remaining text
        cleaned = removePrefixes(from: cleaned, prefixes: prefixes)

        // Keep only first paragraph if requested
        // This is done AFTER prefix removal to get the actual content paragraph
        if keepOnlyFirstParagraph {
            cleaned = keepFirstParagraph(from: cleaned)
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// Default implementation for AIService
extension AIService {
    /// Default implementation of process() using buildPrompt and postProcess
    /// Uses batching for large texts automatically
    func process(_ text: String) async -> String? {
        guard !text.isEmpty else { return nil }

        let prompt = buildPrompt(for: text)

        // Use batched processing for consistency
        // For small texts that fit in one batch, this adds minimal overhead
        let instruction = prompt // The buildPrompt already includes the instruction

        // Estimate if we need batching
        let estimatedTokens = estimateTokens(for: text)
        let modelBatchSize = Int(llmService.getCurrentModel().optimalBatchSize)

        // If text fits in one batch, use direct generation for efficiency
        if estimatedTokens < modelBatchSize {
            guard let rawOutput = await llmService.generateWithChatTemplate(
                systemMessage: instruction,
                userMessage: text,
                maxTokens: config.maxTokens,
                temperature: config.temperature
            ) else {
                return nil
            }
            return postProcess(rawOutput)
        }

        // For large texts, use batching
        // This shouldn't happen often for autocomplete/title, but provides safety
        return await processBatched(
            text,
            instruction: instruction,
            maxTokens: config.maxTokens,
            separator: " "
        )
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

        guard let rawOutput = await llmService.generateWithChatTemplate(
            systemMessage: instruction,
            userMessage: text,
            maxTokens: maxTokens ?? config.maxTokens,
            temperature: config.temperature
        ) else {
            return nil
        }

        return postProcess(rawOutput)
    }

    /// Default post-processing: trim whitespace and remove TinyLlama artifacts
    func postProcess(_ output: String) -> String {
        var cleaned = output.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove TinyLlama chat template artifacts that may leak into output
        cleaned = cleaned.replacingOccurrences(of: "<|assistant|>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "</s>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "<|user|>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "<|system|>", with: "")

        // Remove common hallucination prefixes that small models add
        let hallucinationPrefixes = [
            "Sure! ", "Sure, ", "Certainly! ", "Certainly, ",
            "Here is ", "Here's ", "Here is the ",
            "The translation is: ", "Translation: ", "Translated text: ",
            "Summary: ", "The summary is: ",
            "Corrected: ", "Corrected text: ",
            "Rewritten: ", "Rewritten text: "
        ]

        for prefix in hallucinationPrefixes where cleaned.hasPrefix(prefix) {
            cleaned = String(cleaned.dropFirst(prefix.count))
            break // Only remove first match
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct TextChunker {
    // MARK: - Configuration

    /// Maximum tokens per chunk (should be less than model batch size to leave room for prompt template)
    private let maxTokensPerChunk: Int

    /// Characters per token estimate (default: 2.5 chars ≈ 1 token)
    private let charsPerToken: Double

    init(maxTokensPerChunk: Int = 400, charsPerToken: Double = 2.5) {
        self.maxTokensPerChunk = maxTokensPerChunk
        self.charsPerToken = charsPerToken
    }

    // MARK: - Public API

    /// Chunks text into sentence-based segments that fit within token limits
    /// - Parameter text: The text to chunk
    /// - Returns: Array of text chunks, each containing complete sentences
    func chunk(_ text: String) -> [String] {
        guard !text.isEmpty else { return [] }

        // Split into sentences
        let sentences = splitIntoSentences(text)

        if sentences.isEmpty {
            // Fallback: if no sentences detected, split by paragraphs or character limit
            return chunkByParagraphs(text)
        }

        // Group sentences into chunks that fit within token limit
        return groupSentencesIntoChunks(sentences)
    }

    // MARK: - Sentence Splitting

    /// Splits text into sentences using natural language boundaries
    /// - Parameter text: The text to split
    /// - Returns: Array of sentences
    private func splitIntoSentences(_ text: String) -> [String] {
        var sentences: [String] = []

        // Use NSLinguisticTagger for proper sentence detection
        let tagger = NSLinguisticTagger(tagSchemes: [.tokenType], options: 0)
        tagger.string = text

        let range = NSRange(location: 0, length: text.utf16.count)
        var sentenceRanges: [NSRange] = []

        // Find sentence boundaries
        tagger.enumerateTags(in: range, unit: .sentence, scheme: .tokenType, options: []) { _, tokenRange, _ in
            sentenceRanges.append(tokenRange)
        }

        // Extract sentence strings
        for sentenceRange in sentenceRanges {
            if let range = Range(sentenceRange, in: text) {
                let sentence = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !sentence.isEmpty {
                    sentences.append(sentence)
                }
            }
        }

        // Fallback: if tagger didn't find sentences, use simple regex
        if sentences.isEmpty {
            return fallbackSentenceSplit(text)
        }

        return sentences
    }

    /// Fallback sentence splitting using simple regex patterns
    private func fallbackSentenceSplit(_ text: String) -> [String] {
        var sentences: [String] = []

        // Split on common sentence terminators: . ! ? followed by space or newline
        let pattern = "(?<=[.!?])\\s+"

        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let nsText = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))

            var lastIndex = 0
            for match in matches {
                let range = match.range
                let sentence = nsText.substring(with: NSRange(location: lastIndex, length: range.location - lastIndex))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !sentence.isEmpty {
                    sentences.append(sentence)
                }
                lastIndex = range.location + range.length
            }

            // Add remaining text
            if lastIndex < nsText.length {
                let remaining = nsText.substring(from: lastIndex).trimmingCharacters(in: .whitespacesAndNewlines)
                if !remaining.isEmpty {
                    sentences.append(remaining)
                }
            }
        }

        return sentences.isEmpty ? [text] : sentences
    }

    // MARK: - Chunk Grouping

    /// Groups sentences into chunks that fit within token limits
    private func groupSentencesIntoChunks(_ sentences: [String]) -> [String] {
        var chunks: [String] = []
        var currentChunk: [String] = []
        var currentTokenCount = 0

        for sentence in sentences {
            let sentenceTokens = estimateTokens(for: sentence)

            // If single sentence exceeds limit, add it as its own chunk and truncate if needed
            if sentenceTokens > maxTokensPerChunk {
                // Flush current chunk first
                if !currentChunk.isEmpty {
                    chunks.append(currentChunk.joined(separator: " "))
                    currentChunk = []
                    currentTokenCount = 0
                }

                // Truncate long sentence to fit
                let truncated = truncateToTokenLimit(sentence, maxTokens: maxTokensPerChunk)
                chunks.append(truncated)
                continue
            }

            // Check if adding this sentence would exceed limit
            if currentTokenCount + sentenceTokens > maxTokensPerChunk, !currentChunk.isEmpty {
                // Flush current chunk
                chunks.append(currentChunk.joined(separator: " "))
                currentChunk = []
                currentTokenCount = 0
            }

            // Add sentence to current chunk
            currentChunk.append(sentence)
            currentTokenCount += sentenceTokens
        }

        // Add final chunk
        if !currentChunk.isEmpty {
            chunks.append(currentChunk.joined(separator: " "))
        }

        return chunks
    }

    // MARK: - Paragraph Chunking (Fallback)

    /// Chunks by paragraphs when sentence detection fails
    private func chunkByParagraphs(_ text: String) -> [String] {
        let paragraphs = text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if paragraphs.isEmpty {
            // Ultimate fallback: character-based chunking
            return chunkByCharacters(text)
        }

        var chunks: [String] = []
        var currentChunk: [String] = []
        var currentTokenCount = 0

        for paragraph in paragraphs {
            let paragraphTokens = estimateTokens(for: paragraph)

            if paragraphTokens > maxTokensPerChunk {
                // Flush current chunk
                if !currentChunk.isEmpty {
                    chunks.append(currentChunk.joined(separator: "\n\n"))
                    currentChunk = []
                    currentTokenCount = 0
                }

                // Split paragraph into sentences
                let sentences = splitIntoSentences(paragraph)
                if !sentences.isEmpty {
                    chunks.append(contentsOf: groupSentencesIntoChunks(sentences))
                } else {
                    // Truncate paragraph
                    chunks.append(truncateToTokenLimit(paragraph, maxTokens: maxTokensPerChunk))
                }
                continue
            }

            if currentTokenCount + paragraphTokens > maxTokensPerChunk, !currentChunk.isEmpty {
                chunks.append(currentChunk.joined(separator: "\n\n"))
                currentChunk = []
                currentTokenCount = 0
            }

            currentChunk.append(paragraph)
            currentTokenCount += paragraphTokens
        }

        if !currentChunk.isEmpty {
            chunks.append(currentChunk.joined(separator: "\n\n"))
        }

        return chunks
    }

    // MARK: - Character Chunking (Ultimate Fallback)

    /// Ultimate fallback: chunk by character count
    private func chunkByCharacters(_ text: String) -> [String] {
        let maxCharsPerChunk = Int(Double(maxTokensPerChunk) * charsPerToken)
        var chunks: [String] = []
        var currentIndex = text.startIndex

        while currentIndex < text.endIndex {
            let endIndex = text.index(currentIndex, offsetBy: maxCharsPerChunk, limitedBy: text.endIndex) ?? text
                .endIndex
            let chunk = String(text[currentIndex ..< endIndex])
            chunks.append(chunk)
            currentIndex = endIndex
        }

        return chunks
    }

    // MARK: - Token Utilities

    /// Estimates token count for text
    private func estimateTokens(for text: String) -> Int {
        return Int(Double(text.count) / charsPerToken)
    }

    /// Truncates text to fit within token limit
    private func truncateToTokenLimit(_ text: String, maxTokens: Int) -> String {
        let maxChars = Int(Double(maxTokens) * charsPerToken)
        if text.count <= maxChars {
            return text
        }

        let endIndex = text.index(text.startIndex, offsetBy: maxChars)
        return String(text[..<endIndex]) + "..."
    }
}
