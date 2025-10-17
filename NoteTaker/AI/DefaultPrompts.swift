//
//  DefaultPrompts.swift
//  NoteTaker
//
//  Centralized default prompts for all AI services
//  Users can customize these in settings
//

import Foundation

/// Centralized default prompts for all AI features
/// These serve as the base templates that users can customize in settings
struct DefaultPrompts {

    // MARK: - Autocomplete

    static let autocomplete = """
Continue the following text naturally. Write only the next few words that would logically follow.
"""

    // MARK: - Summarization
    // TinyLlama works better with instructions in user message
    static let summarization = """
<|system|>
You are a helpful assistant.</s>
<|user|>
Summarize in 1-2 sentences:

"""

    // MARK: - Translation
    // TinyLlama works better with instructions in user message
    static let translation = """
<|system|>
You are a translator.</s>
<|user|>
Translate to {language}:

"""

    // MARK: - Title Generation
    // TinyLlama works better with instructions in user message
    static let titleGeneration = """
<|system|>
You are a helpful assistant.</s>
<|user|>
Create a short title (5-8 words) that captures the main idea of the following text:

"""

    // MARK: - Auto-Correct
    // TinyLlama works better with instructions in user message
    static let autoCorrect = """
<|system|>
You are a helpful assistant.</s>
<|user|>
Fix spelling and grammar:

"""

    // MARK: - Reformulation
    // TinyLlama works better with instructions in user message
    static let reformulate = """
<|system|>
You are a helpful assistant.</s>
<|user|>
Rewrite more clearly:

"""
}
