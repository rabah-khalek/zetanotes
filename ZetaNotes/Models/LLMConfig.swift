//
//  LLMConfig.swift
//  ZetaNotes
//
//  Encapsulates all LLM generation parameters in a single, reusable configuration
//  Supports model-specific optimization for each tool type
//

import Foundation

/// Configuration for LLM text generation
/// Contains prompt, temperature, and token limits
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
    
    /// Whether to use the prompt as a user message instead of system message
    /// Default is true (use as user message)
    /// Some models may perform better with user message prompts
    var usePromptAsUserMessage: Bool

    init(
        prompt: String,
        temperature: Float,
        maxTokens: Int? = nil,
        usePromptAsUserMessage: Bool = true
    ) {
        self.prompt = prompt
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.usePromptAsUserMessage = usePromptAsUserMessage
    }
}
