//
//  ContentView.swift
//  NoteTaker
//
//  Main application view with minimal Mac native style
//  Sidebar: Note list | Main: Editor
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = NoteViewModel()
    @StateObject private var systemMonitor = SystemMonitor.shared
    @StateObject private var errorLogger = ErrorLogger.shared
    @EnvironmentObject var aiEngine: AIEngine
    @StateObject private var licenseManager = LicenseManager.shared
    @StateObject private var toolManager = ToolManager.shared
    @State private var showingSettings = false
    @State private var showingErrorLog = false

    // Tool Editor state
    @State private var showingToolEditor = false
    @State private var editingTool: AITool?

    // License/Upgrade state
    @State private var showUpgradePrompt = false
    @State private var showLicenseActivation = false
    @State private var upgradePromptType: UpgradePromptView.PromptType = .general

    var body: some View {
        NavigationSplitView {
            // Sidebar: Note list (minimal Mac Notes style)
            NoteListView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 350)
        } detail: {
            // Main content: Note editor
            if let selectedNote = viewModel.selectedNote {
                NoteEditorView(viewModel: viewModel, aiEngine: aiEngine, note: selectedNote)
                    .id(selectedNote.id) // Force new view instance for each note
            } else {
                EmptyStateView()
            }
        }
            .toolbar {
                // Upgrade button on the far left (only for non-Pro users)
                ToolbarItem(placement: .navigation) {
                    if !licenseManager.isPro {
                        Button(action: {
                            showUpgradePrompt = true
                            upgradePromptType = .general
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 12))
                                Text("Pro")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .help("Upgrade to Pro - $14.99")
                    }
                }

                ToolbarItem(placement: .principal) {
                    // AI Tool Buttons - Sleek compact design
                    HStack(alignment: .center, spacing: 8) {
                        // Autocomplete Toggle with Switch
                        AutocompleteToggle(isEnabled: $viewModel.isAutocompleteEnabled)
                            .help("Toggle Autocomplete")

                            Rectangle()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 1, height: 14)

                        // Patch
                        AIToolButton(
                            icon: "checkmark.seal",
                            label: "Patch",
                            shortcut: "P",
                            color: .green,
                            isLoading: viewModel.isAutoCorrecting,
                            action: {
                                if let note = viewModel.selectedNote {
                                    Task {
                                        await viewModel.autoCorrect(for: note)
                                    }
                                }
                            }
                        )
                        .keyboardShortcut("p", modifiers: .command)
                        .help("Patch grammar (⌘P)")
                        .disabled(viewModel.selectedNote == nil || viewModel.isAutoCorrecting)

                        // Reformulate
                        AIToolButton(
                            icon: "arrow.triangle.2.circlepath",
                            label: "Rephrase",
                            shortcut: "R",
                            color: .orange,
                            isLoading: viewModel.isReformulating,
                            action: {
                                if let note = viewModel.selectedNote {
                                    Task {
                                        await viewModel.reformulate(for: note)
                                    }
                                }
                            }
                        )
                        .keyboardShortcut("r", modifiers: .command)
                        .help("Reformulate text (⌘R)")
                        .disabled(viewModel.selectedNote == nil || viewModel.isReformulating)

                        // Summarize
                        AIToolButton(
                            icon: "doc.text.magnifyingglass",
                            label: "Summarize",
                            shortcut: "S",
                            color: .blue,
                            isLoading: viewModel.isGeneratingSummary,
                            action: {
                                if let note = viewModel.selectedNote {
                                    Task {
                                        await viewModel.generateSummary(for: note)
                                    }
                                }
                            }
                        )
                        .keyboardShortcut("s", modifiers: .command)
                        .help("Generate summary (⌘S)")
                        .disabled(viewModel.selectedNote == nil || viewModel.isGeneratingSummary)

                        // Translate
                        AIToolButton(
                            icon: "globe",
                            label: "Translate",
                            shortcut: "T",
                            color: .pink,
                            isLoading: viewModel.isTranslating,
                            action: {
                                if let note = viewModel.selectedNote {
                                    Task {
                                        await viewModel.generateTranslation(for: note)
                                    }
                                }
                            }
                        )
                        .keyboardShortcut("t", modifiers: .command)
                        .help("Translate text (⌘T)")
                        .disabled(viewModel.selectedNote == nil || viewModel.isTranslating)

                        // Custom Tools section
                        customToolsSection
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                ToolbarItem(placement: .automatic) {
                    HStack(alignment: .center, spacing: 8) {
                        Button(action: { showingSettings.toggle() }) {
                                Image(systemName: "gear")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("AI Settings & Prompts")

                            Button(action: {
                                NotificationCenter.default.post(name: .createNewNote, object: nil)
                            }) {
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("New Note (⌘N)")
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        .sheet(isPresented: $showingSettings) {
            AISettingsView(viewModel: viewModel)
                .environmentObject(aiEngine)
        }
        .sheet(isPresented: $showingToolEditor) {
            ToolEditorView(
                tool: editingTool ?? AITool(name: "", icon: "star.fill", prompt: "", keyboardShortcut: "", color: .purple),
                isPresented: $showingToolEditor,
                onSave: { tool in
                    if editingTool != nil {
                        toolManager.updateTool(tool)
                    } else {
                        toolManager.addTool(tool)
                    }
                }
            )
        }
        .sheet(isPresented: $showUpgradePrompt) {
            UpgradePromptView(
                isPresented: $showUpgradePrompt,
                promptType: upgradePromptType
            )
        }
        .sheet(isPresented: $showLicenseActivation) {
            LicenseActivationView(isPresented: $showLicenseActivation)
        }
        .safeAreaInset(edge: .bottom) {
            // Footer with system monitor and error log
            StatusFooterView(
                systemMonitor: systemMonitor,
                errorLogger: errorLogger,
                showingErrorLog: $showingErrorLog
            )
        }
        .overlay(alignment: .bottom) {
            ZStack {
                // Error Log popout
                if showingErrorLog {
                    ErrorLogView(errorLogger: errorLogger, isPresented: $showingErrorLog)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 36) // Offset for footer
                        .padding(.horizontal)
                        .zIndex(2)
                }
            }
        }
        .onAppear {
            // Start system monitoring for CPU/GPU usage
            systemMonitor.startMonitoring()
            systemMonitor.setActiveModel(aiEngine.selectedModel.displayName)
        }
        .onReceive(NotificationCenter.default.publisher(for: .showUpgradePrompt)) { notification in
            if let type = notification.object as? UpgradePromptView.PromptType {
                upgradePromptType = type
            }
            showUpgradePrompt = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showLicenseActivation)) { _ in
            showLicenseActivation = true
        }
        .onDisappear {
            systemMonitor.stopMonitoring()
        }
    }

    // MARK: - Custom Tools Section

    @ViewBuilder
    private var customToolsSection: some View {
        if licenseManager.isPro || !toolManager.customTools.isEmpty {
            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 1, height: 14)

            // Show custom tools (Pro only)
            if licenseManager.isPro {
                ForEach(toolManager.customTools.prefix(3)) { tool in
                    ToolButton(
                        tool: tool,
                        isLoading: viewModel.executingToolId == tool.id,
                        action: {
                            if let note = viewModel.selectedNote {
                                Task {
                                    await viewModel.executeTool(tool, for: note)
                                }
                            }
                        }
                    )
                    .keyboardShortcut(KeyEquivalent(Character(tool.keyboardShortcut)), modifiers: .command)
                    .help("\(tool.name) (⌘\(tool.keyboardShortcut))")
                    .disabled(viewModel.selectedNote == nil || viewModel.executingToolId == tool.id)
                }
            }

            // "+" button to add new custom tool (always on the right)
            Button(action: {
                if licenseManager.isPro {
                    editingTool = nil
                    showingToolEditor = true
                } else {
                    NotificationCenter.default.post(
                        name: .showUpgradePrompt,
                        object: UpgradePromptView.PromptType.general
                    )
                }
            }) {
                HStack(spacing: 4) {
                    if !licenseManager.isPro {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.orange)
                    }
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 12))
                }
                .foregroundColor(licenseManager.isPro ? .blue : .orange)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(licenseManager.isPro ? Color.blue.opacity(0.1) : Color.orange.opacity(0.1))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .help(licenseManager.isPro ? "Add custom tool" : "Upgrade to Pro for custom tools")
        }
    }
}

// MARK: - Autocomplete Toggle Component

struct AutocompleteToggle: View {
    @Binding var isEnabled: Bool
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 5) {
            Text("Autocomplete")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isEnabled ? .purple : .secondary)

            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.mini)
                .tint(.purple)
                .scaleEffect(0.7)
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - AI Tool Button Component (Keybind square + label)

struct AIToolButton: View {
    let icon: String
    let label: String
    let shortcut: String
    let color: Color
    let isLoading: Bool
    let action: () -> Void

    @State private var isHovered = false
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                // Loading spinner if active
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 10, height: 10)
                        .padding(.trailing, 2)
                }

                // Square with ⌘ + first letter
                HStack(spacing: 1) {
                    Text("⌘")
                        .font(.system(size: 8, weight: .medium))
                    Text(String(label.prefix(1)))
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(foregroundColor)
                .padding(.horizontal, 3)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(foregroundColor.opacity(0.4), lineWidth: 0.5)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(foregroundColor.opacity(isHovered && isEnabled ? 0.08 : 0.03))
                        )
                )

                // Rest of label
                if label.count > 1 {
                    Text(String(label.dropFirst()))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(foregroundColor)
                }
            }
            .scaleEffect(isHovered && isEnabled ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var foregroundColor: Color {
        if !isEnabled {
            return .secondary.opacity(0.3)
        }
        if isLoading {
            return color.opacity(0.85)
        }
        if isHovered {
            return color
        }
        return color.opacity(0.8)
    }
}

// MARK: - Tool Button Component

struct ToolButton: View {
    let tool: AITool
    let isLoading: Bool
    let action: () -> Void

    @State private var isHovered = false
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                // Loading spinner if active
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 10, height: 10)
                        .padding(.trailing, 2)
                }

                // Square with ⌘ + keyboard shortcut letter
                HStack(spacing: 1) {
                    Text("⌘")
                        .font(.system(size: 8, weight: .medium))
                    Text(tool.keyboardShortcut)
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(foregroundColor)
                .padding(.horizontal, 3)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(foregroundColor.opacity(0.4), lineWidth: 0.5)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(foregroundColor.opacity(isHovered && isEnabled ? 0.08 : 0.03))
                        )
                )

                // Full tool name
                Text(tool.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(foregroundColor)
            }
            .scaleEffect(isHovered && isEnabled ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var foregroundColor: Color {
        if !isEnabled {
            return .secondary.opacity(0.3)
        }
        if isLoading {
            return tool.color.color.opacity(0.85)
        }
        if isHovered {
            return tool.color.color
        }
        return tool.color.color.opacity(0.8)
    }
}

// MARK: - Empty State (Compact and clean)

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "note.text")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Note Selected")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)

            Text("Select a note or create a new one")
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.8))

            Button(action: {
                NotificationCenter.default.post(name: .createNewNote, object: nil)
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .semibold))
                    Text("New Note")
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            // Note: Keyboard shortcut ⌘N is handled by toolbar button
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
    }
}

// MARK: - Status Footer View

struct StatusFooterView: View {
    @ObservedObject var systemMonitor: SystemMonitor
    @ObservedObject var errorLogger: ErrorLogger
    @Binding var showingErrorLog: Bool

    var body: some View {
        HStack(spacing: 0) {
            Spacer()

            HStack(alignment: .center, spacing: 8) {
                // Active AI Model (left side)
                if !systemMonitor.activeModel.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 9))
                            .foregroundColor(.purple)

                        Text(systemMonitor.activeModel)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.purple.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(Color.purple.opacity(0.2), lineWidth: 0.5)
                            )
                    )
                    .help("Active AI Model: \(systemMonitor.activeModel)")

                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 1, height: 14)
                }

                // System Monitor (inline, no popup)
                HStack(spacing: 6) {
                    // CPU indicator with fixed width for percentage
                    HStack(spacing: 3) {
                        Image(systemName: "cpu.fill")
                            .font(.system(size: 9))
                            .foregroundColor(cpuColor)

                        Text("CPU:")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)

                        Text(String(format: "%3d", Int(systemMonitor.cpuUsage)) + "%")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.primary)
                            .frame(width: 32, alignment: .trailing)
                    }

                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 1, height: 10)

                    // Memory indicator with fixed width
                    HStack(spacing: 3) {
                        Image(systemName: "memorychip.fill")
                            .font(.system(size: 9))
                            .foregroundColor(memoryColor)

                        Text("MEM:")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)

                        Text(String(format: "%4d", Int(systemMonitor.memoryUsage)) + "M")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.primary)
                            .frame(width: 42, alignment: .trailing)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 0.5)
                        )
                )
                .help("CPU: \(Int(systemMonitor.cpuUsage))% of \(systemMonitor.cpuCoreCount) cores • Memory: \(Int(systemMonitor.memoryUsage))MB (\(String(format: "%.1f", systemMonitor.memoryUsagePercentage))% of \(Int(systemMonitor.totalSystemMemory / 1024))GB)")

                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1, height: 14)

                // Error log button with badge and expand indicator
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showingErrorLog.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: errorLogger.errors.isEmpty ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(errorLogger.errors.isEmpty ? .green : .orange)

                        Text(errorLogger.errors.isEmpty ? "No Errors" : "\(errorLogger.errors.count)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(errorLogger.errors.isEmpty ? .secondary : .orange)

                        // Chevron to indicate expandable
                        Image(systemName: showingErrorLog ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(errorLogger.errors.isEmpty ? Color.green.opacity(0.08) : Color.orange.opacity(0.12))
                    )
                }
                .buttonStyle(.plain)
                .help(errorLogger.errors.isEmpty ? "No errors" : "Click to view \(errorLogger.errors.count) error\(errorLogger.errors.count == 1 ? "" : "s")")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .frame(height: 28)
        .background(
            Color(nsColor: .controlBackgroundColor)
                .overlay(
                    Rectangle()
                        .fill(Color.secondary.opacity(0.1))
                        .frame(height: 0.5),
                    alignment: .top
                )
        )
    }

    // MARK: - Color Helpers

    private var cpuColor: Color {
        switch systemMonitor.cpuUsage {
        case 0..<30:
            return .green
        case 30..<70:
            return .yellow
        default:
            return .red
        }
    }

    private var memoryColor: Color {
        switch systemMonitor.memoryUsagePercentage {
        case 0..<60:
            return .green
        case 60..<80:
            return .yellow
        default:
            return .red
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AIEngine.shared)
    }
}
