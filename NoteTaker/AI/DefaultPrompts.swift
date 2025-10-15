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

    static let summarization = """
Task: Write a brief 1-2 sentence summary of the following text. Only include information from the original text.

Text:
"""

    // MARK: - Translation

    static let translation = """
Task: Translate the following text to {language}. Output only the translated text.

Text to translate:
"""

    // MARK: - Title Generation

    static let titleGeneration = """
Task: Create a short title (5-8 words) that captures the main idea of the following text.

Text:
"""

    // MARK: - Auto-Correct

    static let autoCorrect = """
Task: Fix all spelling and grammar errors in the following text. Keep the same meaning and tone. Output only the corrected text.

Text:
"""

    // MARK: - Reformulation

    static let reformulate = """
Task: Rewrite the following text to be clearer and more professional. Keep all the same information. Output only the rewritten text.

Text:
"""
}
