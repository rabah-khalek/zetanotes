//
//  AISettingsView.swift
//  ZetaNotes
//
//  AI settings with sidebar navigation and custom services
//

import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable {
    case general = "General"
    case model = "AI Model"
    case tools = "Tools"
    case chat = "Chat"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .model: return "cpu"
        case .tools: return "wand.and.stars"
        case .chat: return "bubble.left.and.bubble.right"
        }
    }
}

// MARK: - Tool Editor State

enum ToolEditorState: Identifiable {
    case create
    case edit(AITool)

    var id: String {
        switch self {
        case .create:
            return "create"
        case let .edit(tool):
            return "edit_\(tool.id)"
        }
    }
}

struct AISettingsView: View {
    @ObservedObject var viewModel: NoteViewModel
    @EnvironmentObject var aiEngine: AIEngine
    @ObservedObject private var modelDownloader = ModelDownloader.shared
    @StateObject private var toolManager = ToolManager.shared
    @StateObject private var licenseManager = LicenseManager.shared
    @Environment(\.dismiss) var dismiss

    @State private var selectedSection: SettingsSection = .general
    @State private var toolEditorState: ToolEditorState?

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar Navigation
            VStack(alignment: .leading, spacing: 0) {
                // Header with subtle gradient
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Configure AI & Services")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [
                            Color(nsColor: .controlBackgroundColor).opacity(0.3),
                            Color(nsColor: .controlBackgroundColor).opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                Divider()

                // Navigation Items with improved spacing
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(SettingsSection.allCases) { section in
                        SidebarButton(
                            section: section,
                            isSelected: selectedSection == section,
                            action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedSection = section
                                }
                            }
                        )
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 8)

                Spacer()
            }
            .frame(width: 210)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))

            Divider()
                .opacity(0.5)

            // Main Content Area
            VStack(spacing: 0) {
                // Top bar with close button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 20))
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut("w", modifiers: .command)
                    .help("Close Settings (⌘W)")
                    .padding(.trailing, 16)
                    .padding(.top, 12)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        switch selectedSection {
                        case .general:
                            GeneralSettingsContent(dismiss: dismiss, viewModel: viewModel)
                        case .model:
                            ModelSettingsContent(
                                aiEngine: aiEngine,
                                modelDownloader: modelDownloader
                            )
                        case .tools:
                            ToolsSettingsContent(
                                viewModel: viewModel,
                                toolManager: toolManager,
                                licenseManager: licenseManager,
                                toolEditorState: $toolEditorState
                            )
                        case .chat:
                            ChatSettingsContent()
                        }
                    }
                    .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 850, height: 650)
        .sheet(item: $toolEditorState) { state in
            switch state {
            case .create:
                ToolEditorView(
                    tool: AITool(
                        name: "",
                        icon: "star.fill",
                        keyboardShortcut: "",
                        color: .purple,
                        llmConfig: LLMConfig(
                            prompt: "",
                            temperature: 0.7,
                            maxTokens: nil
                        )
                    ),
                    isPresented: Binding(
                        get: { toolEditorState != nil },
                        set: { if !$0 { toolEditorState = nil } }
                    ),
                    targetLanguage: $viewModel.targetLanguage,
                    onSave: { tool in
                        toolManager.addTool(tool)
                        toolEditorState = nil
                    }
                )
            case let .edit(tool):
                ToolEditorView(
                    tool: tool,
                    isPresented: Binding(
                        get: { toolEditorState != nil },
                        set: { if !$0 { toolEditorState = nil } }
                    ),
                    isReadOnly: false,
                    targetLanguage: $viewModel.targetLanguage,
                    onSave: { updatedTool in
                        toolManager.updateTool(updatedTool)
                        toolEditorState = nil
                    }
                )
            }
        }
    }
}

// MARK: - Sidebar Button

struct SidebarButton: View {
    let section: SettingsSection
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                // Icon with subtle background
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue.opacity(0.2) : Color.clear)
                        .frame(width: 28, height: 28)

                    Image(systemName: section.icon)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .blue : .secondary)
                }

                Text(section.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .primary : .primary.opacity(0.8))

                Spacer()

                // Subtle chevron indicator
                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.blue.opacity(0.6))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue
                        .opacity(0.08) : (isHovered ? Color.secondary.opacity(0.06) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Close Button

struct CloseButton: View {
    let dismiss: DismissAction
    @State private var isHovered = false

    var body: some View {
        Button(action: { dismiss() }) {
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(isHovered ? .red.opacity(0.8) : .secondary)
                Text("Close")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isHovered ? Color.red.opacity(0.05) : Color.clear)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .help("Close Settings (⌘W)")
    }
}

// MARK: - General Settings Content

struct GeneralSettingsContent: View {
    let dismiss: DismissAction
    @ObservedObject var viewModel: NoteViewModel
    @ObservedObject var licenseManager = LicenseManager.shared
    @AppStorage("preferredAppearance") private var preferredAppearance: String = "dark"
    @State private var showResetConfirmation = false
    @State private var showDangerZoneConfirmation = false
    @State private var confirmationText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("General Settings")
                .font(.title2)
                .fontWeight(.semibold)

            // Free app status section
            ProStatusSection(dismiss: dismiss)

            Divider()

            // Appearance and Reset Settings (side-by-side)
            HStack(alignment: .top, spacing: 16) {
                // Reset to Defaults Section (Left)
                VStack(alignment: .leading, spacing: 12) {
                    Label("Reset Settings", systemImage: "arrow.counterclockwise")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("Restore all defaults")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button(action: {
                        showResetConfirmation = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.system(size: 12))
                            Text("Reset")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .confirmationDialog(
                        "Reset All Settings?",
                        isPresented: $showResetConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Reset to Defaults", role: .destructive) {
                            viewModel.resetAllSettingsToDefaults()
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text(
                            "This will reset:\n• All prompts to defaults\n• All tools to defaults (removes custom tools)\n• Chat settings to defaults\n• AI model to Llama 3.2 1B\n• Appearance to Dark mode\n\nThis action cannot be undone."
                        )
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                )

                // Appearance Settings (Right)
                VStack(alignment: .leading, spacing: 12) {
                    Label("Appearance", systemImage: "paintbrush")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("Choose your theme")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Picker("", selection: $preferredAppearance) {
                        Label("Light", systemImage: "sun.max.fill")
                            .tag("light")
                        Label("Dark", systemImage: "moon.fill")
                            .tag("dark")
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                .padding(16)
                .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }

            Divider()

            // Data Export Section
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Export Data")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Backup your notes, settings, and chat history")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Export User Data")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)

                            Text("Creates a folder with all your data in JSON format for backup or migration")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        Button(action: {
                            exportUserData()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 11))
                                Text("Export Data")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.blue.opacity(0.1))
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Export includes:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.blue.opacity(0.9))
                            .textCase(.uppercase)
                            .tracking(0.5)

                        VStack(alignment: .leading, spacing: 6) {
                            ExportItemView(icon: "doc.text.fill", text: "All notes and their content")
                            ExportItemView(icon: "bubble.left.and.bubble.right.fill", text: "Chat history and settings")
                            ExportItemView(icon: "gearshape.fill", text: "App preferences and AI prompts")
                            ExportItemView(icon: "info.circle.fill", text: "AI models information (files not included)")
                        }

                        // Export location info
                        HStack(spacing: 6) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.blue.opacity(0.7))

                            Text("Export location: ~/Library/Application Support/ZetaNotes/Exports/")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
            )

            Divider()

            // Danger Zone Section
            VStack(alignment: .leading, spacing: 0) {
                // Header with warning stripe
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Danger Zone")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)

                        Text("Irreversible actions — proceed with extreme caution")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.red.opacity(0.08),
                            Color.red.opacity(0.12)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

                // Divider with gradient
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.red.opacity(0.3),
                                Color.red.opacity(0.5),
                                Color.red.opacity(0.3)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 2)

                // Content area
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Reset Entire App")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)

                            Text("Permanently delete all data and restore to factory defaults")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()
                    }

                    // What will be deleted
                    Text("This will permanently delete:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.red.opacity(0.9))
                        .textCase(.uppercase)
                        .tracking(0.5)

                    VStack(alignment: .leading, spacing: 6) {
                        DangerZoneItemView(icon: "doc.text.fill", text: "All notes and their content")
                        DangerZoneItemView(
                            icon: "brain.head.profile",
                            text: "All downloaded AI models (~1-2GB)"
                        )
                        DangerZoneItemView(icon: "wand.and.stars", text: "All custom prompts and tools")
                        DangerZoneItemView(icon: "gearshape.fill", text: "All settings and preferences")
                        DangerZoneItemView(
                            icon: "bubble.left.and.bubble.right.fill",
                            text: "Complete chat history"
                        )
                    }

                    // Reset button
                    Button(action: {
                        showDangerZoneConfirmation = true
                        confirmationText = ""
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Reset Entire App")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.red)
                        )
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color.red.opacity(0.5), lineWidth: 1)
                    )
                }
                .padding(16)
            }
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.red.opacity(0.4),
                                Color.red.opacity(0.6),
                                Color.red.opacity(0.4)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: Color.red.opacity(0.15), radius: 8, x: 0, y: 2)
            .alert("Reset Entire App", isPresented: $showDangerZoneConfirmation) {
                TextField("Type DELETE to confirm", text: $confirmationText)
                Button("Cancel", role: .cancel) {
                    confirmationText = ""
                }
                Button("Delete Everything", role: .destructive) {
                    if confirmationText.uppercased() == "DELETE" {
                        performFullReset()
                    }
                }
                .disabled(confirmationText.uppercased() != "DELETE")
            } message: {
                Text(
                    "⚠️ WARNING: This action cannot be undone!\n\n" +
                    "This will permanently delete:\n" +
                    "• All your notes\n" +
                    "• All AI models (~1-2GB)\n" +
                    "• All custom prompts and tools\n" +
                    "• All settings\n" +
                    "• Chat history\n\n" +
                    "The app will restart as if freshly installed.\n\n" +
                    "Type DELETE to confirm."
                )
            }

            Divider()

            // Legal & Support Section
            LegalSupportSection()

            Divider()

            // About Section
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)

                    Text("About ZetaNotes")
                        .font(.headline)
                        .fontWeight(.semibold)
                }

                VStack(alignment: .leading, spacing: 12) {
                    // Version and License
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Version")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                        }

                    }

                    Divider()

                    // Description
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Privacy-first note-taking with offline AI. All processing happens on your device.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Updates are delivered automatically through the Mac App Store.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        Text(
                            "Payments are securely processed through the App Store. No billing data is stored in ZetaNotes."
                        )
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    }

                    Divider()

                    // Rate Button
                    Button(action: {
                        ReviewManager.shared.requestReviewManually()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.yellow)
                            Text("Rate ZetaNotes on the App Store")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .help("Help us by rating ZetaNotes on the App Store")
                }
            }
            .padding(16)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private func performFullReset() {
        // Unload model from memory FIRST (critical - prevents using deleted model)
        AIEngine.shared.unloadModel()
        print("🔄 Unloaded model from memory")

        // Delete all Core Data (notes)
        viewModel.deleteAllNotes()

        // Clear chat messages from memory AND delete the file
        ChatManager.shared.clearMessages()
        print("🗑️ Cleared chat messages from memory")

        // Delete all downloaded models
        if let modelsDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("ZetaNotes/Models") {
            try? FileManager.default.removeItem(at: modelsDir)
            print("🗑️ Deleted Models directory from disk")
        }

        // Delete chat history file (after clearing in-memory messages)
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let zetaNotesDir = appSupport.appendingPathComponent("ZetaNotes")
            let chatHistoryFile = zetaNotesDir.appendingPathComponent("chat_history.json")

            if FileManager.default.fileExists(atPath: chatHistoryFile.path) {
                try? FileManager.default.removeItem(at: chatHistoryFile)
                print("🗑️ Deleted chat history file from disk")
            }
        }

        // Delete Core Data SQLite files (but keep the directory structure)
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let zetaNotesDir = appSupport.appendingPathComponent("ZetaNotes")

            // Delete only the Core Data store files, not the directory
            let sqliteFile = zetaNotesDir.appendingPathComponent("NotesDataModel.sqlite")
            let sqliteShmFile = zetaNotesDir.appendingPathComponent("NotesDataModel.sqlite-shm")
            let sqliteWalFile = zetaNotesDir.appendingPathComponent("NotesDataModel.sqlite-wal")

            try? FileManager.default.removeItem(at: sqliteFile)
            try? FileManager.default.removeItem(at: sqliteShmFile)
            try? FileManager.default.removeItem(at: sqliteWalFile)

            print("✅ Deleted Core Data store files (directory preserved)")
        }

        // Reset all UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            UserDefaults.standard.synchronize()
        }

        // Reset first-run flag
        UserDefaults.standard.set(false, forKey: "hasCompletedFirstRun")
        UserDefaults.standard.synchronize()

        // Quit the app (user can relaunch)
        NSApplication.shared.terminate(nil)
    }

    private func exportUserData() {
        print("🔄 Export Data button clicked")

        // Export to Application Support directory (sandboxed location)
        guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first
        else {
            let alert = NSAlert()
            alert.messageText = "Export Failed"
            alert.informativeText = "Could not access Application Support directory."
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }

        let exportBaseURL = appSupportURL.appendingPathComponent("ZetaNotes/Exports")
        print("📁 Exporting to: \(exportBaseURL.path)")

        Task {
            let success = await DataExportManager.shared.exportAllData(to: exportBaseURL)
            await MainActor.run {
                if success {
                    let alert = NSAlert()
                    alert.messageText = "Export Successful"
                    alert.informativeText = "Your data has been exported to:\n\(exportBaseURL.path)"
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "Show in Finder")
                    alert.addButton(withTitle: "OK")
                    let response = alert.runModal()
                    if response == .alertFirstButtonReturn {
                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: exportBaseURL.path)
                    }
                } else {
                    let alert = NSAlert()
                    alert.messageText = "Export Failed"
                    alert.informativeText = "An error occurred while exporting your data. Please try again."
                    alert.alertStyle = .critical
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            }
        }
    }
}

// MARK: - Model Settings Content

struct ModelSettingsContent: View {
    @ObservedObject var aiEngine: AIEngine
    @ObservedObject var modelDownloader: ModelDownloader

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("AI Model")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Choose between fast lightweight mode or high-quality mode")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Model Cards directly without extra container
            VStack(spacing: 12) {
                ForEach(AIModel.allCases, id: \.self) { model in
                    ModelCard(
                        model: model,
                        isSelected: aiEngine.selectedModel == model,
                        isDownloaded: aiEngine.isModelDownloaded(model),
                        isDownloading: modelDownloader.isDownloading && modelDownloader.downloadingModel == model,
                        downloadProgress: modelDownloader.downloadProgress,
                        onSelect: {
                            Task {
                                await aiEngine.switchModel(to: model)
                            }
                        },
                        onDownload: {
                            modelDownloader.downloadModel(model) { result in
                                switch result {
                                case .success:
                                    print("✅ Model download completed")
                                    // Automatically load the model after download
                                    Task {
                                        await aiEngine.loadModel(model)
                                        print("✅ Model \(model.displayName) loaded and ready")
                                    }
                                case let .failure(error):
                                    print("❌ Download failed: \(error)")
                                }
                            }
                        },
                        onDelete: {
                            _ = aiEngine.deleteModel(model)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Prompts Settings Content

struct PromptsSettingsContent: View {
    @ObservedObject var viewModel: NoteViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("AI Prompts")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("Reset to Defaults") {
                    viewModel.resetPromptsToDefaults()
                }
                .buttonStyle(.bordered)
            }

            // Autocomplete Prompt
            PromptSection(
                title: "Autocomplete",
                icon: "text.cursor",
                prompt: $viewModel.autocompletePrompt,
                placeholder: "Enter prompt for text completion...",
                defaultPrompt: DefaultPrompts.autocomplete
            )

            Divider()

            // Title Generation Prompt
            PromptSection(
                title: "Title Generation",
                icon: "arrow.triangle.2.circlepath",
                prompt: $viewModel.titleGenerationPrompt,
                placeholder: "Enter prompt for title generation...",
                defaultPrompt: DefaultPrompts.titleGeneration
            )

            Divider()

            // Summarization Prompt
            PromptSection(
                title: "Summarization",
                icon: "doc.text.magnifyingglass",
                prompt: $viewModel.summarizationPrompt,
                placeholder: "Enter prompt for summarization...",
                defaultPrompt: DefaultPrompts.summarization
            )

            Divider()

            // Translation Prompt with Language Selector
            TranslationPromptSection(viewModel: viewModel)

            Divider()

            // Patch Prompt
            PromptSection(
                title: "Patch",
                icon: "checkmark.circle",
                prompt: $viewModel.autoCorrectPrompt,
                placeholder: "Enter prompt for patching...",
                defaultPrompt: DefaultPrompts.autoCorrect
            )

            Divider()

            // Reformulate Prompt
            PromptSection(
                title: "Reformulate",
                icon: "arrow.2.squarepath",
                prompt: $viewModel.reformulatePrompt,
                placeholder: "Enter prompt for reformulation...",
                defaultPrompt: DefaultPrompts.reformulate
            )
        }
    }
}

// MARK: - Reusable Components (from original AISettingsView)

struct ModelSelectionSection: View {
    @ObservedObject var aiEngine: AIEngine
    @ObservedObject var modelDownloader: ModelDownloader
    @ObservedObject var licenseManager = LicenseManager.shared

    var body: some View {
        VStack(spacing: 12) {
            ForEach(AIModel.allCases, id: \.self) { model in
                ModelCard(
                    model: model,
                    isSelected: aiEngine.selectedModel == model,
                    isDownloaded: aiEngine.isModelDownloaded(model),
                    isDownloading: modelDownloader.isDownloading && modelDownloader.downloadingModel == model,
                    downloadProgress: modelDownloader.downloadProgress,
                    onSelect: {
                        Task {
                            await aiEngine.switchModel(to: model)
                        }
                    },
                    onDownload: {
                        modelDownloader.downloadModel(model) { result in
                            switch result {
                            case .success:
                                print("✅ Model download completed")
                                // Automatically load the model after download
                                Task {
                                    await aiEngine.loadModel(model)
                                    print("✅ Model \(model.displayName) loaded and ready")
                                }
                            case let .failure(error):
                                print("❌ Download failed: \(error)")
                            }
                        }
                    },
                    onDelete: {
                        _ = aiEngine.deleteModel(model)
                    }
                )
            }
        }
    }
}

struct ModelCard: View {
    let model: AIModel
    let isSelected: Bool
    let isDownloaded: Bool
    let isDownloading: Bool
    let downloadProgress: Double
    let onSelect: () -> Void
    let onDownload: () -> Void
    let onDelete: (() -> Void)? // Optional delete callback

    @ObservedObject var licenseManager = LicenseManager.shared
    @ObservedObject var aiEngine = AIEngine.shared
    @ObservedObject var downloadState = ModelDownloadState.shared
    @State private var showingDeleteConfirmation = false

    private var isSwitchingToThisModel: Bool {
        aiEngine.isSwitchingModel && aiEngine.switchingToModel == model
    }

    private var isQueued: Bool {
        // Check if this model is in the download queue but not currently downloading
        downloadState.activeDownloads.keys.contains(model.displayName) && !isDownloading
    }

    private var modelDownloadProgress: Double {
        downloadState.activeDownloads[model.displayName]?.progress ?? downloadProgress
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                // Model name
                Text(model.displayName)
                    .font(.system(size: 14, weight: .semibold))

                // Model specs
                HStack(spacing: 8) {
                    Label(model.fileSize, systemImage: "doc")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label(model.memoryUsage, systemImage: "memorychip")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label(model.speedRating, systemImage: "speedometer")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label(model.qualityRating, systemImage: "star")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Description
                Text(model.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Action button
            if isDownloading || isQueued {
                HStack(spacing: 8) {
                    VStack(spacing: 2) {
                        ProgressView(value: modelDownloadProgress)
                            .frame(width: 60)
                        Text(isQueued ? "Queued" : "\(Int(modelDownloadProgress * 100))%")
                            .font(.caption2)
                            .foregroundColor(isQueued ? .orange : .secondary)
                    }

                    // Cancel button - aligned with progress bar
                    Button(action: {
                        // Ensure cancellation happens on the main thread to prevent crashes
                        DispatchQueue.main.async {
                            // For queued models, cancel from the state first
                            // since they might not be in ModelDownloader's activeTasks yet
                            if isQueued {
                                ModelDownloadState.shared.cancelDownload(modelName: model.displayName)
                            }
                            // Always try to cancel from ModelDownloader as well
                            // (this handles actively downloading models)
                            ModelDownloader.shared.cancelDownload(for: model)
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                    .help("Cancel download")
                }
            } else if !isDownloaded {
                Button(action: onDownload) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle")
                        Text("Download")
                            .font(.caption)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else if isSwitchingToThisModel {
                // Show loading spinner when switching to this model
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 12, height: 12)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if !isSelected {
                HStack(spacing: 6) {
                    Button(action: onSelect) {
                        Text("Use This")
                            .font(.caption)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(aiEngine.isSwitchingModel)

                    // Delete button (only if downloaded and not selected)
                    if isDownloaded, onDelete != nil {
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            Image(systemName: "trash")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .foregroundColor(.red)
                        .help("Delete this model")
                    }
                }
            } else {
                HStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Active")
                            .font(.caption)
                            .foregroundColor(.green)
                    }

                    // Delete button (even for active model)
                    if isDownloaded, onDelete != nil {
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            Image(systemName: "trash")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .foregroundColor(.red)
                        .help("Delete this model")
                    }
                }
            }
        }
        .padding(12)
        .background(isSelected ? Color.blue.opacity(0.08) : Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1.5)
        )
        .alert("Delete Model", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let deleteAction = onDelete {
                    deleteAction()
                }
            }
        } message: {
            if isSelected {
                Text(
                    "Are you sure you want to delete \(model.displayName)? This is your currently active model. All AI features will be disabled until you download another model. This will free up \(model.fileSize) of storage."
                )
            } else {
                Text(
                    "Are you sure you want to delete \(model.displayName)? This will free up \(model.fileSize) of storage. You can download it again later."
                )
            }
        }
    }
}

struct TranslationPromptSection: View {
    @ObservedObject var viewModel: NoteViewModel
    @ObservedObject var licenseManager = LicenseManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Translation", systemImage: "globe")
                    .font(.subheadline)
                    .fontWeight(.medium)

                // Language picker next to title
                Picker("Target Language", selection: $viewModel.targetLanguage) {
                    Text("To English").tag("English")
                    Text("To Chinese").tag("Chinese")
                    Text("To Spanish").tag("Spanish")
                    Text("To French").tag("French")
                    Text("To German").tag("German")
                    Text("To Portuguese").tag("Portuguese")
                    Text("To Italian").tag("Italian")
                    Text("To Dutch").tag("Dutch")
                    Text("To Japanese").tag("Japanese")
                    Text("To Korean").tag("Korean")
                    Text("To Russian").tag("Russian")
                    Text("To Arabic").tag("Arabic")
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 150)

                Spacer()

            }

            // Display prompt with {language} replaced by actual language
            TextEditor(text: Binding(
                get: {
                    viewModel.translationPrompt.replacingOccurrences(of: "{language}", with: viewModel.targetLanguage)
                },
                set: { newValue in
                    // When editing, replace the actual language back to {language} placeholder
                    viewModel.translationPrompt = newValue.replacingOccurrences(
                        of: viewModel.targetLanguage,
                        with: "{language}"
                    )
                }
            ))
            .font(.system(size: 13))
            .frame(height: 80)
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )

            if viewModel.translationPrompt.isEmpty {
                Text("Enter prompt for translation (use {language} as placeholder)...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct PromptSection: View {
    let title: String
    let icon: String
    @Binding var prompt: String
    let placeholder: String
    let defaultPrompt: String

    @ObservedObject var licenseManager = LicenseManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.subheadline)
                    .fontWeight(.medium)

            }

            TextEditor(text: $prompt)
                .font(.system(size: 13))
                .frame(height: 80)
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )

            if prompt.isEmpty {
                Text(placeholder)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ProStatusSection: View {
    let dismiss: DismissAction
    @Environment(\.openURL) private var openURL

    private let supportEmail = "mailto:rabah.khalek@gmail.com?subject=ZetaNotes%20Support"
    private let websiteURL = "https://www.zetanotes.com"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.green)

                VStack(alignment: .leading, spacing: 4) {
                    Text("All features unlocked")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("ZetaNotes is free. In-app purchases were removed in version 1.0.3.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)

            HStack(spacing: 12) {
                Button {
                    if let url = URL(string: websiteURL) {
                        openURL(url)
                    }
                } label: {
                    Label("Website & Source Code", systemImage: "globe")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    if let url = URL(string: supportEmail) {
                        openURL(url)
                    }
                } label: {
                    Label("Contact", systemImage: "envelope")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Text("ZetaNotes is no longer actively maintained. Previously purchased Pro plans are no longer needed; everything is included for everyone.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct LegalSupportSection: View {
    @Environment(\.openURL) private var openURL

    private let privacyURL = URL(string: "https://www.zetanotes.com/privacy.html")!
    private let termsURL = URL(string: "https://www.zetanotes.com/terms.html")!
    private let supportEmail = "mailto:rabah.khalek@gmail.com?subject=ZetaNotes%20Support"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.blue.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Legal, Privacy & Support")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)

                    Text("View policies, reach support, and manage your license")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Text(
                "ZetaNotes runs fully on your Mac. Notes, embeddings, and chat history stay local unless you export or share them."
            )
            .font(.system(size: 12))
            .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Button {
                    openURL(privacyURL)
                } label: {
                    Label("Privacy Policy", systemImage: "doc.text")
                }
                .buttonStyle(.bordered)

                Button {
                    openURL(termsURL)
                } label: {
                    Label("Terms of Use", systemImage: "doc.richtext")
                }
                .buttonStyle(.bordered)

                Button {
                    if let url = URL(string: supportEmail) {
                        openURL(url)
                    }
                } label: {
                    Label("Contact Support", systemImage: "envelope")
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)

                Button {
                    // Open App Store subscription management
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        openURL(url)
                    }
                } label: {
                    Label("Manage Subscription", systemImage: "creditcard")
                }
                .buttonStyle(.bordered)
            }

            Text("Updates are delivered automatically through the Mac App Store.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Text(
                "Need to revoke data? Export or delete everything from the actions above, or email support to request account deletion."
            )
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Tools Settings Content (Unified)

struct ToolsSettingsContent: View {
    @ObservedObject var viewModel: NoteViewModel
    @ObservedObject var toolManager: ToolManager
    @ObservedObject var licenseManager: LicenseManager
    @Binding var toolEditorState: ToolEditorState?

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Tools")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Manage default and custom AI tools")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Add Custom Tool button
                Button(action: {
                    toolEditorState = .create
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text("Add Custom Tool")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

            // Default Tools Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Default Tools")
                        .font(.headline)
                }

                // Show all default tools (keyboard shortcut is optional)
                ForEach(toolManager.defaultTools) { tool in
                    ToolRow(
                        tool: tool,
                        canEdit: true,
                        onEdit: {
                            toolEditorState = .edit(tool)
                        }
                    )
                }
            }

            if !toolManager.customTools.isEmpty {
                Divider()
                    .padding(.vertical, 8)

                // Custom Tools Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Custom Tools")
                        .font(.headline)

                    ForEach(toolManager.customTools) { tool in
                        ToolRow(
                            tool: tool,
                            canEdit: true,
                            canDelete: true,
                            onEdit: {
                                toolEditorState = .edit(tool)
                            },
                            onDelete: {
                                toolManager.deleteTool(tool)
                            }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Tool Row

struct ToolRow: View {
    let tool: AITool
    let canEdit: Bool
    var canDelete: Bool = false
    let onEdit: () -> Void
    var onDelete: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Colored keyboard shortcut indicator (only show if shortcut exists)
            if !tool.keyboardShortcut.isEmpty {
                HStack(spacing: 2) {
                    Text("⌘")
                        .font(.system(size: 12, weight: .medium))
                    Text(tool.keyboardShortcut)
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(tool.color.color)
                .cornerRadius(6)
            } else {
                // For tools without shortcuts (e.g., custom tools), show icon instead
                Image(systemName: tool.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(tool.color.color)
                    .cornerRadius(6)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(tool.name)
                        .font(.system(size: 14, weight: .semibold))
                }

                Text(tool.prompt.prefix(100) + (tool.prompt.count > 100 ? "..." : ""))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            HStack(spacing: 8) {
                // View/Edit button
                Button(action: onEdit) {
                    if canEdit {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    } else {
                        Image(systemName: "eye")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                }
                .buttonStyle(.plain)
                .help(canEdit ? "Edit tool" : "View tool settings")

                // Delete button (custom tools only)
                if canDelete, let delete = onDelete {
                    Button(action: delete) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Delete tool")
                }
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Autocomplete Settings Row

struct AutocompleteSettingsRow: View {
    @EnvironmentObject var viewModel: NoteViewModel

    var body: some View {
        HStack(spacing: 12) {
            // Purple indicator icon
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 16))
                    .foregroundColor(.purple)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("AI Autocomplete")
                        .font(.system(size: 14, weight: .semibold))
                }

                Text("Provides intelligent text suggestions as you type")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Toggle
            Toggle("", isOn: $viewModel.isAutocompleteEnabled)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(.purple)
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Chat Settings Content

struct ChatSettingsContent: View {
    @ObservedObject private var chatManager = ChatManager.shared
    @StateObject private var licenseManager = LicenseManager.shared
    @State private var settings: ChatSettings

    init() {
        _settings = State(initialValue: ChatSettings.load())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    Text("Chat Settings")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Text("Configure AI chat parameters for conversations")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Group {
                // Temperature
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Temperature")
                            .font(.headline)
                        Spacer()
                        Text(String(format: "%.2f", settings.temperature))
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $settings.temperature, in: 0.01 ... 2.0, step: 0.05)
                        .onChange(of: settings.temperature) { _ in
                            saveSettings()
                        }

                    Text("Controls randomness: 0.01 = focused, 2 = creative")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // Max Tokens
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Max Tokens")
                            .font(.headline)
                        Spacer()
                        Text("\(settings.maxTokens)")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Slider(value: Binding(
                        get: { Double(settings.maxTokens) },
                        set: { settings.maxTokens = Int($0) }
                    ), in: 256 ... 2048, step: 128)
                        .onChange(of: settings.maxTokens) { _ in
                            saveSettings()
                        }

                    Text("Maximum length of AI responses")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // Top P
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Top P")
                            .font(.headline)
                        Spacer()
                        Text(String(format: "%.2f", settings.topP))
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $settings.topP, in: 0.0 ... 1.0, step: 0.05)
                        .onChange(of: settings.topP) { _ in
                            saveSettings()
                        }

                    Text("Nucleus sampling: limits token choices to top probability mass")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // Top K
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Top K")
                            .font(.headline)
                        Spacer()
                        Text("\(settings.topK)")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Slider(value: Binding(
                        get: { Double(settings.topK) },
                        set: { settings.topK = Int($0) }
                    ), in: 1 ... 100, step: 1)
                        .onChange(of: settings.topK) { _ in
                            saveSettings()
                        }

                    Text("Limits token choices to top K most likely tokens")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // Repeat Penalty
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Repeat Penalty")
                            .font(.headline)
                        Spacer()
                        Text(String(format: "%.2f", settings.repeatPenalty))
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $settings.repeatPenalty, in: 1.0 ... 2.0, step: 0.05)
                        .onChange(of: settings.repeatPenalty) { _ in
                            saveSettings()
                        }

                    Text("Penalizes repetition: higher values reduce repeated phrases")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // Generation Timeout
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Generation Timeout")
                            .font(.headline)
                        Spacer()
                        Text(String(format: "%.0f sec", settings.generationTimeout))
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $settings.generationTimeout, in: 1.0 ... 60.0, step: 1.0)
                        .onChange(of: settings.generationTimeout) { _ in
                            saveSettings()
                        }

                    Text("Maximum time allowed for AI to generate a response")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // System Prompt
                VStack(alignment: .leading, spacing: 8) {
                    Text("System Prompt")
                        .font(.headline)

                    TextEditor(text: $settings.systemPrompt)
                        .font(.system(size: 13, design: .monospaced))
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                        .onChange(of: settings.systemPrompt) { _ in
                            saveSettings()
                        }

                    Text("Sets the AI's behavior and personality for chat conversations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // Reset Button
                HStack {
                    Spacer()
                    Button(action: {
                        settings = .default
                        saveSettings()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 11))
                            Text("Reset to Defaults")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.blue.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func saveSettings() {
        chatManager.updateSettings(settings)
    }
}

// MARK: - Danger Zone Item View

struct DangerZoneItemView: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(.red.opacity(0.8))
                .frame(width: 16, alignment: .center)

            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Spacer()
        }
    }
}

// MARK: - Export Item View

struct ExportItemView: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(.blue.opacity(0.8))
                .frame(width: 16, alignment: .center)

            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Spacer()
        }
    }
}

// MARK: - Preview

struct AISettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AISettingsView(viewModel: NoteViewModel())
            .environmentObject(AIEngine.shared)
    }
}
