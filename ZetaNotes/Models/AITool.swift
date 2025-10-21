//
//  AITool.swift
//  ZetaNotes
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
    case titleGeneration = "Title Generation"
    case custom = "Custom"

    var icon: String {
        switch self {
        case .autocomplete: return "text.cursor"
        case .patch: return "checkmark.seal"
        case .rephrase: return "arrow.triangle.2.circlepath"
        case .summarize: return "doc.text.magnifyingglass"
        case .translate: return "globe"
        case .titleGeneration: return "textformat.size"
        case .custom: return "star.fill"
        }
    }

    var keyboardShortcut: String {
        switch self {
        case .autocomplete: return "Q" // Cmd+Q to toggle autocomplete
        case .patch: return "P"
        case .rephrase: return "R"
        case .summarize: return "S"
        case .translate: return "T"
        case .titleGeneration: return "G" // Cmd+G to regenerate title
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

    // MARK: - Convenience Accessors

    /// Convenience accessor for prompt
    var prompt: String {
        get { llmConfig.prompt }
        set { llmConfig.prompt = newValue }
    }

    /// Convenience accessor for temperature
    var temperature: Float {
        get { llmConfig.temperature }
        set { llmConfig.temperature = newValue }
    }

    /// Convenience accessor for maxTokens
    var maxTokens: Int? {
        get { llmConfig.maxTokens }
        set { llmConfig.maxTokens = newValue }
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
            // Autocomplete (no keyboard shortcut - it's a toggleable feature)
            AITool(
                name: "Autocomplete",
                icon: "text.cursor",
                keyboardShortcut: "Q", // Cmd+Q to toggle autocomplete
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
            ),

            // Title Generation
            AITool(
                name: "Title Generation",
                icon: "textformat.size",
                keyboardShortcut: "G", // Cmd+G to regenerate title
                color: .teal,
                isDefault: true,
                isEditable: false,
                llmConfig: ModelToolConfigRegistry.getConfig(for: model, toolType: .titleGeneration)
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
        case "Title Generation":
            return .titleGeneration
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
