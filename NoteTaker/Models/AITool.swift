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

// MARK: - Tool Type

/// The type of AI tool/operation being performed
enum ToolType: String, Codable, CaseIterable {
    case autocomplete = "Autocomplete"
    case patch = "Patch"
    case rephrase = "Rephrase"
    case summarize = "Summarize"
    case translate = "Translate"
    case custom = "Custom"

    var icon: String {
        switch self {
        case .autocomplete: return "text.cursor"
        case .patch: return "checkmark.seal"
        case .rephrase: return "arrow.triangle.2.circlepath"
        case .summarize: return "doc.text.magnifyingglass"
        case .translate: return "globe"
        case .custom: return "star.fill"
        }
    }

    var keyboardShortcut: String {
        switch self {
        case .autocomplete: return "" // No shortcut - toggled via toolbar
        case .patch: return "P"
        case .rephrase: return "R"
        case .summarize: return "S"
        case .translate: return "T"
        case .custom: return ""
        }
    }
}

// MARK: - AI Tool

/// Represents an AI tool with LLM configuration, keyboard shortcut, and visual styling
struct AITool: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var icon: String
    var keyboardShortcut: String // Single character (e.g., "P", "R", "S", "T")
    var color: ToolColor
    var isDefault: Bool // true for built-in tools (Patch, Rephrase, etc.)
    var isEditable: Bool // false for default tools on free tier

    /// LLM generation configuration (prompt, temperature, tokens, stop sequences)
    var llmConfig: LLMConfig

    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        keyboardShortcut: String,
        color: ToolColor,
        isDefault: Bool = false,
        isEditable: Bool = true,
        llmConfig: LLMConfig,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.keyboardShortcut = keyboardShortcut
        self.color = color
        self.isDefault = isDefault
        self.isEditable = isEditable
        self.llmConfig = llmConfig
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    // MARK: - Legacy Convenience Accessors

    /// Convenience accessor for prompt (legacy compatibility)
    var prompt: String {
        get { llmConfig.prompt }
        set { llmConfig.prompt = newValue }
    }

    /// Convenience accessor for temperature (legacy compatibility)
    var temperature: Float {
        get { llmConfig.temperature }
        set { llmConfig.temperature = newValue }
    }

    /// Convenience accessor for maxTokens (legacy compatibility)
    var maxTokens: Int? {
        get { llmConfig.maxTokens }
        set { llmConfig.maxTokens = newValue }
    }

    /// Convenience accessor for stopSequences (legacy compatibility)
    var stopSequences: [String] {
        get { llmConfig.stopSequences }
        set { llmConfig.stopSequences = newValue }
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
    /// Creates the set of default tools with model-specific optimized configurations
    /// Uses the current AI model's optimized LLM config for each tool
    static func createDefaultTools(for model: AIModel) -> [AITool] {
        return [
            // Autocomplete (no keyboard shortcut - it's a toggleable feature)
            AITool(
                name: "Autocomplete",
                icon: "text.cursor",
                keyboardShortcut: "", // No shortcut - toggled via toolbar button
                color: .purple,
                isDefault: true,
                isEditable: false,
                llmConfig: ModelToolConfigRegistry.getConfig(for: model, toolType: .autocomplete)
            ),

            // Patch (Auto-correct)
            AITool(
                name: "Patch",
                icon: "checkmark.seal",
                keyboardShortcut: "P",
                color: .green,
                isDefault: true,
                isEditable: false,
                llmConfig: ModelToolConfigRegistry.getConfig(for: model, toolType: .patch)
            ),

            // Rephrase (Reformulation)
            AITool(
                name: "Rephrase",
                icon: "arrow.triangle.2.circlepath",
                keyboardShortcut: "R",
                color: .orange,
                isDefault: true,
                isEditable: false,
                llmConfig: ModelToolConfigRegistry.getConfig(for: model, toolType: .rephrase)
            ),

            // Summarize
            AITool(
                name: "Summarize",
                icon: "doc.text.magnifyingglass",
                keyboardShortcut: "S",
                color: .blue,
                isDefault: true,
                isEditable: false,
                llmConfig: ModelToolConfigRegistry.getConfig(for: model, toolType: .summarize)
            ),

            // Translate
            AITool(
                name: "Translate",
                icon: "globe",
                keyboardShortcut: "T",
                color: .pink,
                isDefault: true,
                isEditable: false,
                llmConfig: ModelToolConfigRegistry.getConfig(for: model, toolType: .translate)
            )
        ]
    }

    /// Creates default tools using the currently selected model from AIEngine
    static func createDefaultTools() -> [AITool] {
        createDefaultTools(for: AIEngine.shared.selectedModel)
    }

    /// Maps a default tool name to its corresponding ToolType
    /// Returns nil if the tool name doesn't match a known default tool
    static func toolType(forName name: String) -> ToolType? {
        switch name {
        case "Autocomplete":
            return .autocomplete
        case "Patch":
            return .patch
        case "Rephrase":
            return .rephrase
        case "Summarize":
            return .summarize
        case "Translate":
            return .translate
        default:
            return nil
        }
    }

    /// Gets the ToolType for this tool (if it's a default tool)
    var toolType: ToolType? {
        guard isDefault else { return nil }
        return AITool.toolType(forName: name)
    }
}
