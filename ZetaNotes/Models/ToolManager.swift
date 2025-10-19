//
//  ToolManager.swift
//  ZetaNotes
//
//  Manages all AI tools (default + custom)
//  - Default tools: Always present, editable only for Pro users
//  - Custom tools: User-created, Pro-only feature
//

import Combine
import Foundation
import SwiftUI

/// Manager for all AI tools (default and custom)
class ToolManager: ObservableObject {
    static let shared = ToolManager()

    @Published var tools: [AITool] = []

    private let storageKey = "aiTools"
    private let maxCustomTools = 10
    private let hasInitializedKey = "hasInitializedDefaultTools"
    private var cancellables = Set<AnyCancellable>()

    private init() {
        loadTools()
        setupModelChangeObserver()
    }

    // MARK: - Model Change Observer

    private func setupModelChangeObserver() {
        // Automatically update default tools when model changes
        AIEngine.shared.$selectedModel
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updateDefaultToolsForCurrentModel()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Loading & Saving

    func loadTools() {
        // Check if we've initialized default tools
        let hasInitialized = UserDefaults.standard.bool(forKey: hasInitializedKey)

        if !hasInitialized {
            // First run: Initialize with default tools
            tools = AITool.createDefaultTools()
            saveTools()
            UserDefaults.standard.set(true, forKey: hasInitializedKey)
            print("✅ Initialized default tools")
            return
        }

        // Load from storage
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([AITool].self, from: data)
        else {
            // Fallback: Re-initialize if load fails
            tools = AITool.createDefaultTools()
            saveTools()
            return
        }

        tools = decoded

        // Ensure default tools exist (in case of updates/migration)
        ensureDefaultToolsExist()

        // Migrate Autocomplete tool to remove keyboard shortcut
        migrateAutocompleteShortcut()
    }

    func saveTools() {
        guard let encoded = try? JSONEncoder().encode(tools) else {
            print("❌ Failed to encode tools")
            return
        }
        UserDefaults.standard.set(encoded, forKey: storageKey)
        print("✅ Saved \(tools.count) tools (\(defaultTools.count) default, \(customTools.count) custom)")
    }

    /// Ensures all default tools exist (for migration/updates)
    private func ensureDefaultToolsExist() {
        let defaultToolNames = ["Autocomplete", "Patch", "Rephrase", "Summarize", "Translate"]
        let existingNames = Set(tools.filter { $0.isDefault }.map { $0.name })

        for defaultTool in AITool.createDefaultTools() where !existingNames.contains(defaultTool.name) {
            // Missing default tool, add it
            tools.insert(defaultTool, at: defaultToolInsertionIndex())
            print("➕ Added missing default tool: \(defaultTool.name)")
        }

        if tools.filter({ $0.isDefault }).count != defaultToolNames.count {
            saveTools()
        }
    }

    /// Migration: Update Autocomplete tool to remove keyboard shortcut
    /// This ensures existing installations update to the new schema where Autocomplete has no shortcut
    private func migrateAutocompleteShortcut() {
        var needsSave = false

        if let index = tools.firstIndex(where: { $0.name == "Autocomplete" && $0.isDefault }) {
            if tools[index].keyboardShortcut == "A" {
                tools[index].keyboardShortcut = ""
                needsSave = true
                print("🔄 Migrated Autocomplete tool: removed keyboard shortcut 'A'")
            }
        }

        if needsSave {
            saveTools()
        }
    }

    /// Finds the correct index to insert a new default tool (keep defaults at the beginning)
    private func defaultToolInsertionIndex() -> Int {
        return tools.lastIndex(where: { $0.isDefault })?.advanced(by: 1) ?? 0
    }

    // MARK: - Computed Properties

    var defaultTools: [AITool] {
        let defaults = tools.filter { $0.isDefault }
        // Sort alphabetically by name
        // Note: Autocomplete has no shortcut and isn't shown in toolbar shortcuts
        return defaults.sorted { $0.name < $1.name }
    }

    var customTools: [AITool] {
        tools.filter { !$0.isDefault }
    }

    // MARK: - Tool Management

    func addTool(_ tool: AITool) {
        guard customTools.count < maxCustomTools else {
            print("⚠️ Maximum number of custom tools reached")
            return
        }

        var newTool = tool
        newTool.isDefault = false // Ensure it's marked as custom
        tools.append(newTool)
        saveTools()
    }

    func updateTool(_ tool: AITool) {
        if let index = tools.firstIndex(where: { $0.id == tool.id }) {
            tools[index] = tool
            tools[index].touch()
            saveTools()
        }
    }

    func deleteTool(_ tool: AITool) {
        guard !tool.isDefault else {
            print("⚠️ Cannot delete default tools")
            return
        }

        tools.removeAll { $0.id == tool.id }
        saveTools()
    }

    func canAddCustomTool() -> Bool {
        return customTools.count < maxCustomTools
    }

    /// Resets a default tool to its factory prompt for the current model
    func resetDefaultTool(_ tool: AITool) {
        guard tool.isDefault else { return }

        // Find the factory default by name (not shortcut, since shortcuts are optional)
        // Uses current model's optimized configuration
        guard let factoryTool = AITool.createDefaultTools()
            .first(where: { $0.name == tool.name })
        else {
            return
        }

        // Update with factory prompt and shortcut
        if let index = tools.firstIndex(where: { $0.id == tool.id }) {
            tools[index].llmConfig = factoryTool.llmConfig
            tools[index].keyboardShortcut = factoryTool.keyboardShortcut
            tools[index].touch()
            saveTools()
            print("🔄 Reset \(tool.name) to default config for current model")
        }
    }

    /// Updates all default tools to use configurations optimized for the current AI model
    /// Called automatically when the AI model is switched
    /// Preserves user customizations - only updates tools that haven't been modified
    func updateDefaultToolsForCurrentModel() {
        let currentModelDefaults = AITool.createDefaultTools()
        var needsSave = false

        for defaultTool in currentModelDefaults {
            guard let index = tools.firstIndex(where: { $0.name == defaultTool.name && $0.isDefault }) else {
                continue
            }

            // Check if this tool's config matches ANY model's default (hasn't been customized)
            if isToolAtDefaultConfig(tools[index]) {
                // Update to current model's optimized config
                tools[index].llmConfig = defaultTool.llmConfig
                tools[index].touch()
                needsSave = true
                print("🔄 Updated \(defaultTool.name) config for current model")
            }
        }

        if needsSave {
            saveTools()
        }
    }

    /// Checks if a tool's config matches a default config from any model
    /// This allows updating from one model's defaults to another
    private func isToolAtDefaultConfig(_ tool: AITool) -> Bool {
        guard tool.isDefault else { return false }

        // Get the ToolType for this default tool
        guard let toolType = tool.toolType else { return false }

        // Check if the tool's config matches the default config for any model
        for model in AIModel.allCases {
            let defaultConfig = ModelToolConfigRegistry.getConfig(for: model, toolType: toolType)
            if tool.llmConfig == defaultConfig {
                return true
            }
        }

        return false
    }

    // MARK: - Tool Lookup

    func tool(withShortcut shortcut: String) -> AITool? {
        return tools.first { $0.keyboardShortcut.uppercased() == shortcut.uppercased() }
    }

    func tool(withId id: UUID) -> AITool? {
        return tools.first { $0.id == id }
    }

    // MARK: - Reset

    /// Resets all tools to defaults: removes custom tools, resets default tools to factory settings
    func resetToDefaults() {
        // Remove all custom tools and restore default tools
        tools = AITool.createDefaultTools()

        // Clear the initialization flag so it's like a fresh install
        UserDefaults.standard.removeObject(forKey: hasInitializedKey)
        UserDefaults.standard.set(true, forKey: hasInitializedKey)

        // Save the reset state
        saveTools()

        print("✅ Reset all tools to defaults (removed \(customTools.count) custom tools)")
    }

    // MARK: - Validation

    /// Check if a keyboard shortcut is available
    func isShortcutAvailable(_ shortcut: String, excluding toolId: UUID? = nil) -> Bool {
        let normalizedShortcut = shortcut.uppercased()

        // Empty shortcuts are always allowed (e.g., Autocomplete)
        guard !normalizedShortcut.isEmpty else { return true }

        // Check against all tools (default + custom)
        return !tools.contains { tool in
            !tool.keyboardShortcut.isEmpty &&
                tool.keyboardShortcut.uppercased() == normalizedShortcut &&
                tool.id != toolId
        }
    }

    /// Get list of all used shortcuts
    var usedShortcuts: Set<String> {
        Set(tools.map { $0.keyboardShortcut.uppercased() }.filter { !$0.isEmpty })
    }

    /// Get suggested available shortcuts
    var availableShortcuts: [String] {
        let allLetters = "ABCDEFGHIJKLMNOPQUVWXYZ"
        return allLetters.compactMap { letter in
            let shortcut = String(letter)
            return usedShortcuts.contains(shortcut) ? nil : shortcut
        }
    }
}
