//
//  ContentView.swift
//  NoteTaker
//
//  Main application view with minimal Mac native style
//  Sidebar: Note list | Main: Editor
//
//  Components are now separated into:
//  - AutocompleteToggle.swift
//  - AIToolButton.swift
//  - ToolButton.swift
//  - EmptyStateView.swift
//  - StatusFooterView.swift
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

    // Word and character count state
    @State private var currentWordCount = 0
    @State private var currentCharacterCount = 0

    var body: some View {
        NavigationSplitView {
            // Sidebar: Note list (minimal Mac Notes style)
            NoteListView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 350)
        } detail: {
            detailView
        }
        .navigationSplitViewStyle(.balanced)
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

    // MARK: - Detail View

    @ViewBuilder
    private var detailView: some View {
        VStack(spacing: 0) {
            headerBand
            mainContentView
            footerView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .bottom) {
            errorLogOverlay
        }
    }

    // MARK: - Header Band

    @ViewBuilder
    private var headerBand: some View {
        HStack(spacing: 0) {
            Spacer()
                .frame(width: 12)

            toolButtonsSection

            Spacer()

            headerRightButtons
        }
        .frame(height: 36)
        .background(
            Color(nsColor: .controlBackgroundColor)
                .overlay(
                    Rectangle()
                        .fill(Color.secondary.opacity(0.1))
                        .frame(height: 0.5),
                    alignment: .bottom
                )
        )
    }

    @ViewBuilder
    private var toolButtonsSection: some View {
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

                        // Custom tools
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

                            // "+" button to add new custom tool
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

    @ViewBuilder
    private var headerRightButtons: some View {
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
        .padding(.horizontal, 12)
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContentView: some View {
        if let selectedNote = viewModel.selectedNote {
            NoteEditorView(viewModel: viewModel, aiEngine: aiEngine, note: selectedNote)
                .id(selectedNote.id) // Force new view instance for each note
                .onChange(of: selectedNote.content) { newContent in
                    // Update word and character counts
                    let words = (newContent ?? "").components(separatedBy: .whitespacesAndNewlines)
                    currentWordCount = words.filter { !$0.isEmpty }.count
                    currentCharacterCount = (newContent ?? "").count
                }
                .onAppear {
                    // Initialize counts when note appears
                    let words = (selectedNote.content ?? "").components(separatedBy: .whitespacesAndNewlines)
                    currentWordCount = words.filter { !$0.isEmpty }.count
                    currentCharacterCount = (selectedNote.content ?? "").count
                }
        } else {
            EmptyStateView()
                .onAppear {
                    // Reset counts when no note selected
                    currentWordCount = 0
                    currentCharacterCount = 0
                }
        }
    }

    // MARK: - Footer

    @ViewBuilder
    private var footerView: some View {
        StatusFooterView(
            systemMonitor: systemMonitor,
            errorLogger: errorLogger,
            showingErrorLog: $showingErrorLog,
            wordCount: currentWordCount,
            characterCount: currentCharacterCount
        )
    }

    // MARK: - Error Log Overlay

    @ViewBuilder
    private var errorLogOverlay: some View {
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
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AIEngine.shared)
    }
}
