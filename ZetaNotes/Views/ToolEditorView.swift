//
//  ToolEditorView.swift
//  ZetaNotes
//
//  Editor for creating and editing AI tools (custom tools only)
//  Default tools are edited separately in settings with Pro restriction
//

import SwiftUI

struct ToolEditorView: View {
    @State private var tool: AITool
    @Binding var isPresented: Bool
    let onSave: ((AITool) -> Void)?
    let isReadOnly: Bool
    var targetLanguage: Binding<String>?

    @StateObject private var toolManager = ToolManager.shared
    @StateObject private var licenseManager = LicenseManager.shared
    @StateObject private var aiEngine = AIEngine.shared
    @State private var shortcutError: String?
    @State private var nameError: String?
    @State private var showAdvanced = false
    @State private var newStopSequence = ""

    init(tool: AITool, isPresented: Binding<Bool>, isReadOnly: Bool = false, targetLanguage: Binding<String>? = nil, onSave: ((AITool) -> Void)? = nil) {
        _tool = State(initialValue: tool)
        _isPresented = isPresented
        self.isReadOnly = isReadOnly
        self.targetLanguage = targetLanguage
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            formContent
        }
        .frame(width: 600)
        .frame(minHeight: 500, maxHeight: 700)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 12) {
            headerIcon
            headerTitle
            if isReadOnly && tool.isDefault && !licenseManager.isPro {
                proRequiredBadge
            }
            Spacer()
            closeButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
    }

    private var headerIcon: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 36, height: 36)
            Image(systemName: tool.name.isEmpty ? "plus.circle.fill" : "pencil.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(.blue)
        }
    }

    private var headerTitle: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(isReadOnly ? tool.name : (tool.name.isEmpty ? "New Custom Tool" : "Edit Tool"))
                .font(.title3)
                .fontWeight(.bold)
            Text(isReadOnly ? "View tool settings" :
                (tool.name.isEmpty ? "Create a custom AI tool" : "Modify your tool"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var proRequiredBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.system(size: 10))
            Text("Pro required to edit")
                .font(.caption)
        }
        .foregroundColor(.orange)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(6)
    }

    private var closeButton: some View {
        Button(action: { isPresented = false }) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.secondary)
                .font(.system(size: 20))
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.cancelAction)
    }

    // MARK: - Form Content

    private var formContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                nameField
                colorPicker
                keyboardShortcutField

                Divider()
                    .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("AI Prompt", systemImage: "text.bubble")
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                        Text("\(tool.prompt.count) characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("Use {content} where you want the selected text to be inserted")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if isReadOnly {
                        ScrollView {
                            Text(tool.prompt)
                                .font(.system(size: 13))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
                                .cornerRadius(8)
                        }
                        .frame(height: 160)
                    } else {
                        TextEditor(text: $tool.prompt)
                            .font(.system(size: 13))
                            .frame(height: 160)
                            .padding(8)
                            .background(Color(nsColor: .textBackgroundColor))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(
                                        tool.prompt.contains("{content}") ? Color.gray.opacity(0.3) : Color.orange,
                                        lineWidth: tool.prompt.contains("{content}") ? 1 : 2
                                    )
                            )

                        if !tool.prompt.isEmpty && !tool.prompt.contains("{content}") {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                Text("Prompt must include {content} placeholder")
                                    .font(.caption)
                            }
                            .foregroundColor(.orange)
                        }
                    }
                    
                    // Language Picker (Translation tool only)
                    if tool.name == "Translate", let languageBinding = targetLanguage {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("Target Language", systemImage: "globe")
                                    .font(.system(size: 13, weight: .medium))
                                Spacer()
                            }
                            
                            Picker("Target Language", selection: languageBinding) {
                                Text("English").tag("English")
                                Text("Spanish").tag("Spanish")
                                Text("French").tag("French")
                                Text("German").tag("German")
                                Text("Portuguese").tag("Portuguese")
                                Text("Italian").tag("Italian")
                                Text("Dutch").tag("Dutch")
                                Text("Chinese").tag("Chinese")
                                Text("Japanese").tag("Japanese")
                                Text("Korean").tag("Korean")
                                Text("Russian").tag("Russian")
                                Text("Arabic").tag("Arabic")
                            }
                            .pickerStyle(.menu)
                            .frame(width: 200)
                            .disabled(isReadOnly)
                            
                            Text("The prompt uses {language} placeholder which will be replaced with this language at runtime.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 20)

                // Advanced Settings (Collapsible)
                VStack(alignment: .leading, spacing: 0) {
                    // Clickable header
                    HStack {
                        Label("Advanced Settings", systemImage: "slider.horizontal.3")
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                        Image(systemName: showAdvanced ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.primary)
                    .padding(12)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
                    .cornerRadius(8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showAdvanced.toggle()
                        }
                    }

                    if showAdvanced {
                        VStack(alignment: .leading, spacing: 20) {
                            // Temperature
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Temperature")
                                        .font(.system(size: 13, weight: .medium))
                                    Spacer()
                                    Text(String(format: "%.2f", tool.temperature))
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.secondary.opacity(0.1))
                                        .cornerRadius(4)
                                }

                                if !isReadOnly {
                                    Slider(value: Binding(
                                        get: { Double(tool.temperature) },
                                        set: { tool.temperature = Float($0) }
                                    ), in: 0 ... 1, step: 0.05)
                                }

                                Text("Lower = more focused/deterministic. Higher = more creative/random.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            // Max Tokens
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Max Tokens")
                                    .font(.system(size: 13, weight: .medium))

                                HStack {
                                    if isReadOnly {
                                        Text(tool.maxTokens.map { String($0) } ?? "Dynamic")
                                            .font(.system(size: 13))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
                                            .cornerRadius(6)
                                    } else {
                                        Toggle("Use fixed limit", isOn: Binding(
                                            get: { tool.maxTokens != nil },
                                            set: { tool.maxTokens = $0 ? 500 : nil }
                                        ))

                                        if tool.maxTokens != nil {
                                            TextField("Tokens", value: Binding(
                                                get: { tool.maxTokens ?? 500 },
                                                set: { tool.maxTokens = $0 }
                                            ), format: .number)
                                                .textFieldStyle(.roundedBorder)
                                                .frame(width: 100)
                                        }
                                    }
                                }

                                Text(tool
                                    .maxTokens == nil ? "Dynamically calculated based on input length" :
                                    "Fixed maximum output length")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            // Stop Sequences
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Stop Sequences")
                                        .font(.system(size: 13, weight: .medium))

                                    Spacer()

                                    if !isReadOnly {
                                        Button(action: {
                                            if !newStopSequence.isEmpty {
                                                tool.stopSequences.append(newStopSequence)
                                                newStopSequence = ""
                                            }
                                        }) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.blue)
                                        }
                                        .buttonStyle(.plain)
                                        .help("Add stop sequence")
                                        .disabled(newStopSequence.isEmpty)
                                    }
                                }

                                Text("Generation stops when these patterns are encountered")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                // Add new stop sequence field
                                if !isReadOnly {
                                    HStack(spacing: 8) {
                                        TextField("e.g., \"\\n\\n\" or \"</s>\"", text: $newStopSequence)
                                            .textFieldStyle(.roundedBorder)
                                            .font(.system(size: 12, design: .monospaced))

                                        Button(action: {
                                            if !newStopSequence.isEmpty {
                                                tool.stopSequences.append(newStopSequence)
                                                newStopSequence = ""
                                            }
                                        }) {
                                            Text("Add")
                                                .font(.system(size: 12, weight: .medium))
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 4)
                                                .background(newStopSequence.isEmpty ? Color.secondary
                                                    .opacity(0.2) : Color.blue)
                                                .foregroundColor(newStopSequence.isEmpty ? .secondary : .white)
                                                .cornerRadius(6)
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(newStopSequence.isEmpty)
                                    }
                                }

                                // Existing sequences
                                if !tool.stopSequences.isEmpty {
                                    VStack(alignment: .leading, spacing: 6) {
                                        ForEach(Array(tool.stopSequences.enumerated()), id: \.offset) { index, seq in
                                            HStack(spacing: 8) {
                                                Text(escapeStopSequence(seq))
                                                    .font(.system(size: 11, design: .monospaced))
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(Color.blue.opacity(0.1))
                                                    .foregroundColor(.blue)
                                                    .cornerRadius(6)
                                                    .frame(maxWidth: .infinity, alignment: .leading)

                                                if !isReadOnly {
                                                    Button(action: {
                                                        tool.stopSequences.remove(at: index)
                                                    }) {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .font(.system(size: 14))
                                                            .foregroundColor(.secondary)
                                                    }
                                                    .buttonStyle(.plain)
                                                    .help("Remove")
                                                }
                                            }
                                        }
                                    }
                                    .padding(8)
                                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
                                    .cornerRadius(6)
                                } else {
                                    Text("No stop sequences defined")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .italic()
                                        .padding(.vertical, 8)
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(Color.blue.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .padding(.top, 8)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, -16)
                .padding(.bottom, 16)
            }

            Divider()

            // Footer
            HStack(spacing: 12) {
                // Reset to Default button (default tools only)
                if tool.isDefault {
                    Button(action: resetToDefault) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset to Default")
                                .fontWeight(.medium)
                        }
                        .frame(minWidth: 120)
                    }
                    .buttonStyle(.bordered)
                    .help("Reset prompt and settings to defaults for current model")
                }

                Spacer()

                if !isReadOnly {
                    Button(action: {
                        if isValid, let save = onSave {
                            var updatedTool = tool
                            updatedTool.touch()
                            save(updatedTool)
                            isPresented = false
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: isValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            Text(tool.name.isEmpty ? "Create Tool" : "Save Changes")
                                .fontWeight(.semibold)
                        }
                        .frame(minWidth: 120)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValid)
                    .keyboardShortcut(.defaultAction)
                } else if tool.isDefault && !licenseManager.isPro {
                    Button(action: {
                        NotificationCenter.default.post(
                            name: .showUpgradePrompt,
                            object: UpgradePromptView.PromptType.general
                        )
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "lock.fill")
                            Text("Upgrade to Edit")
                                .fontWeight(.semibold)
                        }
                        .frame(minWidth: 140)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Form Fields

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Tool Name", systemImage: "tag")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text("\(tool.name.count)/20")
                    .font(.caption)
                    .foregroundColor(tool.name.count > 15 ? .orange : .secondary)
            }

            TextField("e.g., 'Make Concise', 'Add Emojis'", text: $tool.name)
                .textFieldStyle(.roundedBorder)
                .disabled(isReadOnly)
                .onChange(of: tool.name) { _ in validateName() }

            if let error: String = nameError {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                }
                .foregroundColor(.red)
            } else {
                Text("A short, descriptive name for your tool")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Color", systemImage: "paintpalette")
                .font(.system(size: 14, weight: .semibold))

            HStack(spacing: 8) {
                ForEach(ToolColor.allCases, id: \.self) { colorOption in
                    Button(action: { tool.color = colorOption }) {
                        ZStack {
                            Circle()
                                .fill(colorOption.color)
                                .frame(width: 32, height: 32)

                            if tool.color == colorOption {
                                Circle()
                                    .strokeBorder(Color.primary, lineWidth: 2)
                                    .frame(width: 36, height: 36)

                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isReadOnly)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var keyboardShortcutField: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 4) {
                Label("Keyboard Shortcut", systemImage: "command")
                    .font(.system(size: 14, weight: .semibold))
                Text("(Optional)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Text("⌘")
                        .font(.system(size: 16, weight: .semibold))
                    Text("+")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)

                TextField("Letter (or leave empty)", text: $tool.keyboardShortcut)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 160)
                    .disabled(isReadOnly)
                    .onChange(of: tool.keyboardShortcut) { newValue in
                        tool.keyboardShortcut = String(newValue.uppercased().prefix(1))
                        validateShortcut()
                    }
            }

            if let error: String = shortcutError {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                }
                .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Validation

    private var isValid: Bool {
        !tool.name.isEmpty &&
            !tool.prompt.isEmpty &&
            tool.prompt.contains("{content}") && // Must include placeholder
            shortcutError == nil &&
            nameError == nil
        // Note: keyboard shortcut is optional
    }

    private func validateShortcut() {
        // Empty shortcut is valid (optional)
        guard !tool.keyboardShortcut.isEmpty else {
            shortcutError = nil
            return
        }

        if !toolManager.isShortcutAvailable(tool.keyboardShortcut, excluding: tool.id) {
            shortcutError = "This keyboard shortcut is already in use"
        } else {
            shortcutError = nil
        }
    }

    private func validateName() {
        guard !tool.name.isEmpty else {
            nameError = nil
            return
        }

        if tool.name.count > 20 {
            nameError = "Name must be 20 characters or less"
        } else {
            nameError = nil
        }
    }

    // MARK: - Reset to Default

    private func resetToDefault() {
        guard tool.isDefault else { return }

        // Get the ToolType for this default tool
        guard let toolType = tool.toolType else { return }

        // Get the default config for this tool with the current model
        let defaultConfig = ModelToolConfigRegistry.getConfig(
            for: aiEngine.selectedModel,
            toolType: toolType
        )

        // Reset only the LLM-related settings, keep name, color, shortcut, icon
        tool.prompt = defaultConfig.prompt
        tool.temperature = defaultConfig.temperature
        tool.maxTokens = defaultConfig.maxTokens
        tool.stopSequences = defaultConfig.stopSequences

        // Save the changes immediately
        var updatedTool = tool
        updatedTool.touch()
        onSave?(updatedTool)
    }

    // MARK: - Helper Functions

    /// Escapes special characters in stop sequences for display
    /// Converts actual newlines, tabs, etc. to their escaped representations
    private func escapeStopSequence(_ sequence: String) -> String {
        return sequence
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
}
