//
//  DefaultPrompts.swift
//  NoteTaker
//
//  Centralized default prompts for all AI services
//  Users can customize these in settings
//  Now uses ModelPromptRegistry for model-specific optimized prompts
//

import Foundation

/// Centralized default prompts for all AI features
/// These serve as the base templates that users can customize in settings
/// Prompts are now model-specific and optimized based on each model's best practices
enum DefaultPrompts {
    // MARK: - Model-Aware Prompts

    /// Returns the default autocomplete prompt for the current model
    static var autocomplete: String {
        ModelPromptRegistry.getPrompt(
            for: AIEngine.shared.selectedModel,
            type: .autocomplete
        )
    }

    /// Returns the default summarization prompt for the current model
    static var summarization: String {
        ModelPromptRegistry.getPrompt(
            for: AIEngine.shared.selectedModel,
            type: .summarization
        )
    }

    /// Returns the default translation prompt for the current model
    static var translation: String {
        ModelPromptRegistry.getPrompt(
            for: AIEngine.shared.selectedModel,
            type: .translation
        )
    }

    /// Returns the default title generation prompt for the current model
    static var titleGeneration: String {
        ModelPromptRegistry.getPrompt(
            for: AIEngine.shared.selectedModel,
            type: .titleGeneration
        )
    }

    /// Returns the default auto-correct prompt for the current model
    static var autoCorrect: String {
        ModelPromptRegistry.getPrompt(
            for: AIEngine.shared.selectedModel,
            type: .autoCorrect
        )
    }

    /// Returns the default reformulate prompt for the current model
    static var reformulate: String {
        ModelPromptRegistry.getPrompt(
            for: AIEngine.shared.selectedModel,
            type: .reformulate
        )
    }

    // MARK: - Legacy Static Prompts (for TinyLlama 1.1B)

    // These are kept for backward compatibility and as fallbacks

    /// Legacy autocomplete prompt (TinyLlama 1.1B format)
    static let autocompleteLegacy = """
    Continue the following text naturally. Write only the next few words that would logically follow.
    """

    /// Legacy summarization prompt (TinyLlama 1.1B format)
    static let summarizationLegacy = """
    <|system|>
    You are a helpful assistant.</s>
    <|user|>
    Summarize in 1-2 sentences:

    """

    /// Legacy translation prompt (TinyLlama 1.1B format)
    static let translationLegacy = """
    <|system|>
    You are a translator.</s>
    <|user|>
    Translate to {language}:

    """

    /// Legacy title generation prompt (TinyLlama 1.1B format)
    static let titleGenerationLegacy = """
    <|system|>
    You are a helpful assistant.</s>
    <|user|>
    Create a short title (5-8 words) that captures the main idea of the following text:

    """

    /// Legacy auto-correct prompt (TinyLlama 1.1B format)
    static let autoCorrectLegacy = """
    <|system|>
    You are a helpful assistant.</s>
    <|user|>
    Fix spelling and grammar:

    """

    /// Legacy reformulate prompt (TinyLlama 1.1B format)
    static let reformulateLegacy = """
    <|system|>
    You are a helpful assistant.</s>
    <|user|>
    Rewrite more clearly:

    """
}
