//
//  AITool.swift
//  NoteTaker
//
//  Unified model for all AI tools (both default and custom)
//  Default tools: Patch, Rephrase, Summarize, Translate
//  Custom tools: User-created Pro-only tools
//

import Foundation
import SwiftUI

/// Represents an AI tool with prompt, keyboard shortcut, and visual styling
struct AITool: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var icon: String
    var prompt: String
    var keyboardShortcut: String // Single character (e.g., "P", "R", "S", "T")
    var color: ToolColor
    var isDefault: Bool // true for built-in tools (Patch, Rephrase, etc.)
    var isEditable: Bool // false for default tools on free tier

    // LLM Generation Parameters
    var temperature: Float // Randomness (0.0 = deterministic, 1.0 = creative)
    var maxTokens: Int? // Max tokens to generate (nil = dynamic)
    var stopSequences: [String] // Sequences that stop generation

    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        prompt: String,
        keyboardShortcut: String,
        color: ToolColor,
        isDefault: Bool = false,
        isEditable: Bool = true,
        temperature: Float = 0.7,
        maxTokens: Int? = nil,
        stopSequences: [String] = [],
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.prompt = prompt
        self.keyboardShortcut = keyboardShortcut
        self.color = color
        self.isDefault = isDefault
        self.isEditable = isEditable
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.stopSequences = stopSequences
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    mutating func touch() {
        modifiedAt = Date()
    }

    /// Determines if this tool can be edited based on Pro status
    func canEdit(isPro: Bool) -> Bool {
        if isDefault {
            return isPro // Default tools only editable for Pro users
        }
        return isEditable
    }

    /// Determines if this tool can be deleted
    func canDelete() -> Bool {
        return !isDefault // Can't delete default tools
    }
}

/// Color options for AI tools
enum ToolColor: String, Codable, CaseIterable {
    case blue, green, orange, pink, purple, red, yellow, teal, indigo

    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .pink: return .pink
        case .purple: return .purple
        case .red: return .red
        case .yellow: return .yellow
        case .teal: return .teal
        case .indigo: return .indigo
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Default Tools Factory

extension AITool {
    /// Creates the set of default tools with current default prompts and LLM parameters
    static func createDefaultTools() -> [AITool] {
        // Stop sequences optimized for TinyLlama (llama.cpp handles </s> natively)
        let defaultStopSequences = [
            "<|user|>", // Prevent fake user messages
            "<|system|>", // Prevent fake system messages
            "\n\nText:", // Stop if it tries to repeat the input prompt
            "\n---\n`" // Service delimiter start
        ]

        return [
            // Autocomplete (no keyboard shortcut - it's a toggleable feature)
            AITool(
                name: "Autocomplete",
                icon: "text.cursor",
                prompt: DefaultPrompts.autocomplete,
                keyboardShortcut: "", // No shortcut - toggled via toolbar button
                color: .purple,
                isDefault: true,
                isEditable: false,
                temperature: 0.7, // Moderate for natural continuations
                maxTokens: 50, // Short completions
                stopSequences: ["\n", ".", "!", "?"] // Stop at sentence boundaries
            ),

            // Patch (Auto-correct)
            AITool(
                name: "Patch",
                icon: "checkmark.seal",
                prompt: DefaultPrompts.autoCorrect,
                keyboardShortcut: "P",
                color: .green,
                isDefault: true,
                isEditable: false,
                temperature: 0.05, // Very low for deterministic corrections
                maxTokens: nil, // Dynamic based on input
                stopSequences: defaultStopSequences
            ),

            // Rephrase (Reformulation)
            AITool(
                name: "Rephrase",
                icon: "arrow.triangle.2.circlepath",
                prompt: DefaultPrompts.reformulate,
                keyboardShortcut: "R",
                color: .orange,
                isDefault: true,
                isEditable: false,
                temperature: 0.2, // Low temp to avoid hallucinations
                maxTokens: nil, // Dynamic based on input
                stopSequences: defaultStopSequences
            ),

            // Summarize
            AITool(
                name: "Summarize",
                icon: "doc.text.magnifyingglass",
                prompt: DefaultPrompts.summarization,
                keyboardShortcut: "S",
                color: .blue,
                isDefault: true,
                isEditable: false,
                temperature: 0.2, // Low temp for focused summaries
                maxTokens: 150, // Fixed max for summaries
                stopSequences: defaultStopSequences
            ),

            // Translate
            AITool(
                name: "Translate",
                icon: "globe",
                prompt: DefaultPrompts.translation,
                keyboardShortcut: "T",
                color: .pink,
                isDefault: true,
                isEditable: false,
                temperature: 0.1, // Very low for translation accuracy
                maxTokens: nil, // Dynamic based on input
                stopSequences: defaultStopSequences + ["\n\nOutput:"] // Extra stop for translation
            )
        ]
    }
}
