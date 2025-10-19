//
//  LLMConfig.swift
//  ZetaNotes
//
//  Encapsulates all LLM generation parameters in a single, reusable configuration
//  Supports model-specific optimization for each tool type
//

import Foundation

/// Configuration for LLM text generation
/// Contains prompt, temperature, token limits, and stop sequences
struct LLMConfig: Codable, Equatable {
    /// The prompt template to use for generation
    var prompt: String

    /// Temperature controls randomness (0.0 = deterministic, 2.0 = very creative)
    /// - Typical values:
    ///   - 0.01-0.1: Factual tasks (translation, correction)
    ///   - 0.2-0.5: Balanced tasks (summarization, reformulation)
    ///   - 0.6-1.0: Creative tasks (autocomplete, generation)
    var temperature: Float

    /// Maximum number of tokens to generate (nil = dynamic based on input)
    var maxTokens: Int?

    /// Sequences that trigger generation to stop
    var stopSequences: [String]

    init(
        prompt: String,
        temperature: Float,
        maxTokens: Int? = nil,
        stopSequences: [String] = []
    ) {
        self.prompt = prompt
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.stopSequences = stopSequences
    }
}
