//
//  DefaultPrompts.swift
//  ZetaNotes
//
//  Centralized default prompts for all AI services
//  Users can customize these in settings
//  Uses ModelToolConfigRegistry for model-specific optimized prompts
//

import Foundation

/// Centralized default prompts for all AI features
/// These serve as the base templates that users can customize in settings
/// Prompts are now model-specific and optimized based on each model's best practices
enum DefaultPrompts {
    // MARK: - Model-Aware Prompts

    /// Returns the default autocomplete prompt for the current model
    static var autocomplete: String {
        ModelToolConfigRegistry.getConfig(
            for: AIEngine.shared.selectedModel,
            toolType: .autocomplete
        ).prompt
    }

    /// Returns the default summarization prompt for the current model
    static var summarization: String {
        ModelToolConfigRegistry.getConfig(
            for: AIEngine.shared.selectedModel,
            toolType: .summarize
        ).prompt
    }

    /// Returns the default translation prompt for the current model
    static var translation: String {
        ModelToolConfigRegistry.getConfig(
            for: AIEngine.shared.selectedModel,
            toolType: .translate
        ).prompt
    }

    /// Returns the default title generation prompt for the current model
    static var titleGeneration: String {
        ModelToolConfigRegistry.getConfig(
            for: AIEngine.shared.selectedModel,
            toolType: .titleGeneration
        ).prompt
    }

    /// Returns the default auto-correct prompt for the current model
    static var autoCorrect: String {
        ModelToolConfigRegistry.getConfig(
            for: AIEngine.shared.selectedModel,
            toolType: .patch
        ).prompt
    }

    /// Returns the default reformulate prompt for the current model
    static var reformulate: String {
        ModelToolConfigRegistry.getConfig(
            for: AIEngine.shared.selectedModel,
            toolType: .rephrase
        ).prompt
    }
}
