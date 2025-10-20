//
//  ContentView.swift
//  ZetaNotes
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
    @StateObject private var downloadState = ModelDownloadState.shared
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

    // Search state
    @State private var showingSearch = false
    @State private var searchQuery = ""
    @State private var isSearching = false
    @State private var semanticMatchText = "" // Stores the matched text for highlighting

    // Sidebar state
    @State private var showingSidebar = true
    @State private var sidebarWidth: CGFloat = AppTheme.Spacing.sidebarDefaultWidth

    // Chat state
    @State private var showingChat = false
    @State private var chatSidebarWidth: CGFloat = AppTheme.Spacing.chatDefaultWidth

    var body: some View {
        CustomWindowLayout(
            toolbarHeight: 52,
            showLeftSidebar: showingSidebar,
            leftSidebarWidth: sidebarWidth,
            showRightSidebar: showingChat,
            rightSidebarWidth: chatSidebarWidth
        ) {
            // Toolbar
            buildCustomToolbar()
        } leftSidebar: {
            // Left sidebar
            NoteListView(viewModel: viewModel)
        } content: {
            // Main content
            mainContentArea
        } rightSidebar: {
            // Right sidebar (chat)
            ChatSidebarView()
                .environmentObject(aiEngine)
        }
        .sheet(isPresented: $showingSettings) {
            AISettingsView(viewModel: viewModel)
                .environmentObject(aiEngine)
        }
        .sheet(isPresented: $showingToolEditor) {
            ToolEditorView(
                tool: editingTool ?? AITool(
                    name: "",
                    icon: "star.fill",
                    keyboardShortcut: "",
                    color: .purple,
                    llmConfig: LLMConfig(
                        prompt: "",
                        temperature: 0.7,
                        maxTokens: nil,
                        stopSequences: []
                    )
                ),
                isPresented: $showingToolEditor,
                targetLanguage: $viewModel.targetLanguage,
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

            // Register for app termination notification to flush saves
            NotificationCenter.default.addObserver(
                forName: NSApplication.willTerminateNotification,
                object: nil,
                queue: .main
            ) { [viewModel] _ in
                print("💾 App terminating, flushing pending saves...")
                Task { @MainActor in
                    viewModel.flushPendingSaves()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .insertTextIntoNote)) { notification in
            if let text = notification.object as? String,
               let note = viewModel.selectedNote {
                let currentContent = note.content ?? ""

                // Check if this is a chat dump (starts with ---\n`Chat •)
                if text.hasPrefix("---\n`Chat •") {
                    // Look for existing chat section to replace
                    // Match pattern: ---\n`Chat • {date}`\n---\n\n{content}
                    // The content continues until we hit another section marker or end of string
                    let pattern = #"---\n`Chat • [^`]+`\n---\n\n(?:(?!---\n`(?:Chat|[A-Z][a-z]+ • )).|\n)*"#

                    if let range = currentContent.range(
                        of: pattern,
                        options: .regularExpression
                    ) {
                        // Replace existing chat section
                        var newContent = currentContent
                        newContent.replaceSubrange(range, with: text)
                        note.content = newContent
                    } else {
                        // No existing chat, append it
                        note.content = currentContent + "\n\n" + text
                    }
                } else {
                    // Not a chat dump, just append
                    note.content = currentContent + "\n\n" + text
                }

                viewModel.saveNote(note)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showUpgradePrompt)) { notification in
            if let type = notification.object as? UpgradePromptView.PromptType {
                upgradePromptType = type
            }
            // Close settings and tool editor if open
            showingSettings = false
            showingToolEditor = false
            showUpgradePrompt = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showLicenseActivation)) { _ in
            showLicenseActivation = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleChat)) { _ in
            showingChat.toggle()
        }
        .onDisappear {
            systemMonitor.stopMonitoring()
            // Flush any pending saves when view disappears
            viewModel.flushPendingSaves()
        }
        .onChange(of: viewModel.searchQuery) { newQuery in
            // Clear semantic match highlighting when search is cleared
            if newQuery.isEmpty {
                semanticMatchText = ""
            }
        }
        .onChange(of: searchQuery) { newQuery in
            // Clear semantic match highlighting when local search query is cleared
            if newQuery.isEmpty {
                semanticMatchText = ""
            }
        }
    }

    // MARK: - Toolbar Builder

    @ViewBuilder
    private func buildCustomToolbar() -> some View {
        CustomToolbarView(height: 52) {
            // Left items
            toolbarLeftItems
        } centerContent: {
            // Center items
            toolbarCenterItems
        } rightContent: {
            // Right items
            toolbarRightItems
        }
    }

    // MARK: - Main Content Area

    @ViewBuilder
    private var mainContentArea: some View {
        ZStack(alignment: .bottom) {
            // Main content view
            mainContentView
                .padding(.bottom, AppTheme.Spacing.contentBottomPadding) // Space for bottom status bar
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom overlays
            VStack {
                Spacer()

                ZStack(alignment: .bottom) {
                    // Bottom center status bar
                    bottomStatusBar

                    // Search bar overlay
                    searchBarOverlay

                    // Error log overlay
                    errorLogOverlay
                }
            }
        }
    }

    // MARK: - Main Detail View (Legacy - will remove)

    @ViewBuilder
    private var mainDetailView: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Main content area (squeezable)
                ZStack(alignment: .top) {
                    // Background color to fill entire area
                    Color(nsColor: .windowBackgroundColor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea(.all)

                    VStack(spacing: 0) {
                        mainContentView
                            .padding(.bottom, 32) // Space for bottom status bar
                            .padding(.top, 52) // Space for custom toolbar
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Custom toolbar overlay at top
                    VStack(spacing: 0) {
                        customToolbar
                            .background(
                                Color(nsColor: .windowBackgroundColor)
                                    .opacity(0.98)
                                    .background(.ultraThinMaterial)
                            )
                            .overlay(
                                // Bottom border
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.15))
                                    .frame(height: 1),
                                alignment: .bottom
                            )
                            .zIndex(10) // Ensure toolbar stays on top

                        Spacer()
                    }

                    // Bottom overlays
                    VStack {
                        Spacer()

                        ZStack(alignment: .bottom) {
                            // Bottom center status bar
                            bottomStatusBar

                            // Search bar overlay
                            searchBarOverlay

                            // Error log overlay
                            errorLogOverlay
                        }
                    }
                }
                .frame(width: showingChat ? geometry.size.width - chatSidebarWidth : geometry.size.width)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingChat)

                // Chat sidebar (from right)
                if showingChat {
                    ChatSidebarView()
                        .environmentObject(aiEngine)
                        .frame(width: chatSidebarWidth)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .ignoresSafeArea(.all)
        }
        .ignoresSafeArea(.all)
    }

    // MARK: - Toolbar Items

    @ViewBuilder
    private var toolbarCenterItems: some View {
        HStack(spacing: 8) {
            // Autocomplete Toggle
            AutocompleteToggle(isEnabled: $viewModel.isAutocompleteEnabled)
                .keyboardShortcut("q", modifiers: .command)
                .help("Toggle Autocomplete (⌘Q)")
                .padding(.leading, 8)
                .disabled(downloadState.isDownloading || !aiEngine.isModelLoaded)
                .disabled(viewModel.selectedNote == nil)

            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 1, height: 14)

            // Find
            AIToolButton(
                icon: "magnifyingglass",
                label: "Find",
                shortcut: "F",
                color: .indigo,
                isLoading: false,
                action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showingSearch.toggle()
                    }
                }
            )
            .keyboardShortcut("f", modifiers: .command)
            .help("Find in note (⌘F)")
            .disabled(viewModel.selectedNote == nil || downloadState.isDownloading || !aiEngine.isModelLoaded)

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
            .disabled(viewModel.selectedNote == nil || viewModel.isAutoCorrecting || downloadState
                .isDownloading || !aiEngine.isModelLoaded)

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
            .disabled(viewModel.selectedNote == nil || viewModel.isReformulating || downloadState
                .isDownloading || !aiEngine.isModelLoaded)

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
            .disabled(viewModel.selectedNote == nil || viewModel.isGeneratingSummary || downloadState
                .isDownloading || !aiEngine.isModelLoaded)

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
            .disabled(viewModel.selectedNote == nil || viewModel.isTranslating || downloadState
                .isDownloading || !aiEngine.isModelLoaded)

            // Divider before custom tools
            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 1, height: 14)

            // Show custom tools (Pro only) - all tools shown, keyboard shortcut optional
            if licenseManager.isPro && !toolManager.customTools.isEmpty {
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
                    // Only add keyboard shortcut if tool has one
                    .if(!tool.keyboardShortcut.isEmpty) { view in
                        view.keyboardShortcut(KeyEquivalent(Character(tool.keyboardShortcut)), modifiers: .command)
                    }
                    .help(tool.keyboardShortcut.isEmpty ? tool.name : "\(tool.name) (⌘\(tool.keyboardShortcut))")
                    .disabled(viewModel.selectedNote == nil || viewModel.executingToolId == tool.id || !aiEngine
                        .isModelLoaded)
                }
            }

            // "+" button to add new custom tool (always visible)
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
                        .font(.system(size: 14))
                        .foregroundColor(licenseManager.isPro ? .blue : .orange)
                }
            }
            .buttonStyle(.plain)
            .help(licenseManager.isPro ? "Add custom tool" : "Upgrade to Pro for custom tools")
        }
        .padding(.horizontal, 8)
        .controlSize(.small)
    }

    @ViewBuilder
    private var bottomStatusBar: some View {
        HStack(spacing: 0) {
            Spacer()

            // All items centered
            HStack(spacing: 8) {
                if let selectedNote = viewModel.selectedNote, let createdAt = selectedNote.createdAt {
                    timestampBadge(label: "Created", date: createdAt, color: .green)
                }

                wordCountBadge

                // Active AI Model (only show when model is loaded)
                if !systemMonitor.activeModel.isEmpty && aiEngine.isModelLoaded {
                    activeModelBadge
                }

                // System usage (only show when model is loaded)
                if aiEngine.isModelLoaded {
                    systemUsageBadge
                }

                // Model Download Progress (if downloading)
                if downloadState.isDownloading, let modelName = downloadState.downloadingModelName {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 12, height: 12)

                        Text("Downloading \(modelName)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.primary)

                        Text("\(Int(downloadState.downloadProgress * 100))%")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.orange.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(Color.orange.opacity(0.2), lineWidth: 0.5)
                            )
                    )
                    .help("Downloading AI model: \(Int(downloadState.downloadProgress * 100))% complete")
                }
            }
            .padding(.vertical, 6)

            Spacer()
        }
        .padding(.vertical, AppTheme.Spacing.statusBarVerticalPadding)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Badge Components

    private var wordCountBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.text")
                .font(.system(size: 9))
                .foregroundColor(.blue)

            Text("\(currentWordCount)w")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)

            Text("•")
                .font(.system(size: 8))
                .foregroundColor(.secondary.opacity(0.5))

            Text("\(currentCharacterCount)c")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.blue.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.blue.opacity(0.2), lineWidth: 0.5)
                )
        )
        .help("\(currentWordCount) words, \(currentCharacterCount) characters")
    }

    private var activeModelBadge: some View {
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
    }

    private var systemUsageBadge: some View {
        HStack(spacing: 6) {
            // CPU indicator
            HStack(spacing: 2) {
                Image(systemName: "cpu.fill")
                    .font(.system(size: 9))
                    .foregroundColor(cpuColor)

                Text("CPU:")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)

                Text(String(format: "%3d", Int(systemMonitor.cpuUsage)) + "%")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.primary)
            }

            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 1, height: 10)

            // Memory indicator
            HStack(spacing: 2) {
                Image(systemName: "memorychip.fill")
                    .font(.system(size: 9))
                    .foregroundColor(memoryColor)

                Text("MEM:")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)

                Text(String(format: "%4d", Int(systemMonitor.memoryUsage)) + "M")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.primary)
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
        .help("""
        CPU: \(Int(systemMonitor.cpuUsage))% of \(systemMonitor.cpuCoreCount) cores • \
        Memory: \(Int(systemMonitor.memoryUsage))MB \
        (\(String(format: "%.1f", systemMonitor.memoryUsagePercentage))% of \
        \(Int(systemMonitor.totalSystemMemory / 1024))GB)
        """)
    }

    private func timestampBadge(label: String, date: Date, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: label == "Created" ? "calendar.badge.plus" : "calendar.badge.clock")
                .font(.system(size: 9))
                .foregroundColor(color)

            Text(label + ":")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)

            Text(formatTimestamp(date))
                .font(.system(size: 10, weight: .medium, design: .default))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(color.opacity(0.2), lineWidth: 0.5)
                )
        )
        .help("\(label): \(formatFullTimestamp(date))")
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }

    private func formatFullTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }

    // MARK: - Color Helpers

    private var cpuColor: Color {
        switch systemMonitor.cpuUsage {
        case 0 ..< 30:
            return .green
        case 30 ..< 70:
            return .yellow
        default:
            return .red
        }
    }

    private var memoryColor: Color {
        switch systemMonitor.memoryUsagePercentage {
        case 0 ..< 60:
            return .green
        case 60 ..< 80:
            return .yellow
        default:
            return .red
        }
    }

    // MARK: - Toolbar Items

    @ViewBuilder
    private var toolbarLeftItems: some View {
        HStack(spacing: 8) {
            // Sidebar toggle
            Button(action: {
                withAnimation(AppTheme.Animation.standard) {
                    showingSidebar.toggle()
                }
            }) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: AppTheme.Typography.toolbarIconSize))
                    .foregroundColor(showingSidebar ? AppTheme.Colors.accentBlue : AppTheme.Colors.secondaryText)
            }
            .buttonStyle(.plain)
            .help("Toggle Sidebar (⌘B)")
            .keyboardShortcut("b", modifiers: .command)

            Button(action: { showingSettings.toggle() }) {
                Image(systemName: "gear")
                    .font(.system(size: AppTheme.Typography.toolbarIconSize))
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
            .buttonStyle(.plain)
            .help("AI Settings & Prompts")

            Button(action: {
                NotificationCenter.default.post(name: .createNewNote, object: nil)
            }) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: AppTheme.Typography.toolbarIconSize))
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
            .buttonStyle(.plain)
            .help("New Note (⌘N)")
        }
        .padding(.horizontal, 8)
        .controlSize(.small)
    }

    // MARK: - Custom Toolbar

    @ViewBuilder
    private var customToolbar: some View {
        ZStack {
            // Draggable background layer (for window movement)
            WindowDraggableView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(true)

            // Toolbar content (buttons on top of draggable area)
            HStack(spacing: 0) {
                // Left: Settings and New Note
                toolbarLeftItems
                    .padding(.leading, 16)
                    .allowsHitTesting(true) // Allow buttons to receive clicks

                Spacer()
                    .allowsHitTesting(false) // Spacer doesn't block dragging

                // Center: AI Tools
                toolbarCenterItems
                    .allowsHitTesting(true) // Allow buttons to receive clicks

                Spacer()
                    .allowsHitTesting(false) // Spacer doesn't block dragging

                // Right: Chat button (hidden when chat open)
                if !showingChat {
                    toolbarRightItems
                        .padding(.trailing, 16)
                        .allowsHitTesting(true) // Allow button to receive clicks
                } else {
                    // Empty spacer when chat is open to maintain balance
                    Color.clear
                        .frame(width: 60)
                        .padding(.trailing, 16)
                        .allowsHitTesting(false)
                }
            }
        }
        .frame(height: 52)
    }

    @ViewBuilder
    private var toolbarRightItems: some View {
        HStack(spacing: 8) {
            // Chat toggle (symmetric to sidebar toggle)
            Button(action: {
                if licenseManager.isPro {
                    withAnimation(AppTheme.Animation.standard) {
                        showingChat.toggle()
                    }
                } else {
                    NotificationCenter.default.post(
                        name: .showUpgradePrompt,
                        object: UpgradePromptView.PromptType.chat
                    )
                }
            }) {
                ZStack(alignment: .topLeading) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: AppTheme.Typography.toolbarIconSize))
                        .foregroundColor(
                            licenseManager.isPro
                                ? (showingChat ? AppTheme.Colors.accentBlue : AppTheme.Colors.secondaryText)
                                : .orange
                        )

                    // Lock icon for free users
                    if !licenseManager.isPro {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.orange)
                            .offset(x: -4, y: -4)
                    }
                }
            }
            .buttonStyle(.plain)
            .help(licenseManager.isPro ? "Toggle Chat (⌘⇧C)" : "Upgrade to Pro for AI Chat")
            .keyboardShortcut("c", modifiers: [.command, .shift])
        }
        .padding(.horizontal, 4)
        .controlSize(.small)
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContentView: some View {
        if let selectedNote = viewModel.selectedNote {
            NoteEditorView(
                viewModel: viewModel,
                aiEngine: aiEngine,
                note: selectedNote,
                searchQuery: $searchQuery,
                isSearching: showingSearch,
                semanticMatchText: $semanticMatchText
            )
            .background(AppTheme.Colors.editorBackground)
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

    // MARK: - Search Bar Overlay

    @ViewBuilder
    private var searchBarOverlay: some View {
        if showingSearch {
            VStack(spacing: 0) {
                VStack(spacing: 2) {
                    // Instructions at top with blue styling
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.blue.opacity(0.8))
                        Text("AI semantic search within this note")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("•")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("Press ⏎ to find related content")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue.opacity(0.06))
                    )

                    // Search bar
                    HStack(spacing: 12) {
                        // Search icon or loading indicator
                        if isSearching {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 14, height: 14)
                        } else {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }

                        // Search field
                        TextField("Search in original content...", text: $searchQuery)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .onSubmit {
                                // Semantic search on Enter
                                performSearch()
                            }

                        // Close button
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showingSearch = false
                                searchQuery = ""
                                semanticMatchText = ""
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Close search")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                )
                .padding(.horizontal, 24)
                .padding(.top, 0)

                Spacer()
            }
            .transition(.move(edge: .top).combined(with: .opacity))
            .zIndex(3)
        }
    }

    // MARK: - Error Log Overlay

    @ViewBuilder
    private var errorLogOverlay: some View {
        ZStack {
            // Error Log popout
            if showingErrorLog {
                ErrorLogView(errorLogger: errorLogger, isPresented: $showingErrorLog)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 40) // Above bottom status bar
                    .padding(.horizontal)
                    .zIndex(2)
            }
        }
    }

    // MARK: - Search Functions

    private func performSearch() {
        guard !searchQuery.isEmpty, let note = viewModel.selectedNote else { return }

        isSearching = true

        // On Enter, always perform semantic search
        performSemanticSearch(in: note.content ?? "")
    }

    private func performKeywordSearch(in content: String) {
        // Simple keyword search - highlight matches in the content
        // This would typically scroll to and highlight the matches
        let matches = content.ranges(of: searchQuery, options: .caseInsensitive)
        print("Found \(matches.count) keyword matches for '\(searchQuery)'")
        // TODO: Implement highlighting and navigation through matches
    }

    private func performSemanticSearch(in content: String) {
        // ✅ SCOPED SEARCH: Only searches within the CURRENT note's content
        // Does NOT search across all notes or generate embeddings for other notes
        // Embeddings are computed on-demand for:
        //   1. The search query
        //   2. Chunks of THIS note's content only
        // This keeps the operation fast and memory-efficient

        Task {
            guard !searchQuery.isEmpty else { return }

            print("🔍 Performing semantic search within current note for '\(searchQuery)'")

            // Extract only base content (exclude AI-generated sections) from CURRENT note
            let baseContent = extractBaseContent(from: content)

            if baseContent.isEmpty {
                print("⚠️ No base content to search")
                await MainActor.run { isSearching = false }
                return
            }

            // Get embedding for search query
            guard let queryEmbedding = await aiEngine.embeddingService.generateEmbedding(for: searchQuery) else {
                print("⚠️ Failed to generate query embedding")
                await MainActor.run { isSearching = false }
                return
            }

            // Split content into larger, more meaningful chunks (paragraphs with context)
            let chunks = splitIntoMeaningfulChunks(baseContent)

            if chunks.isEmpty {
                print("No content chunks found")
                await MainActor.run { isSearching = false }
                return
            }

            struct SearchMatch {
                let text: String
                let similarity: Float
                let range: Range<String.Index>
            }

            var bestMatches: [SearchMatch] = []

            // Generate embeddings for each chunk of CURRENT NOTE ONLY (not all notes)
            // This is an on-demand, scoped operation limited to the active note
            for chunk in chunks {
                guard chunk.text.count > 20 else { continue } // Skip very short chunks

                if let chunkEmbedding = await aiEngine.embeddingService.generateEmbedding(for: chunk.text) {
                    let similarity = aiEngine.embeddingService.cosineSimilarity(queryEmbedding, chunkEmbedding)

                    // Store all results for comparison
                    bestMatches.append(SearchMatch(text: chunk.text, similarity: similarity, range: chunk.range))
                }
            }

            guard !bestMatches.isEmpty else {
                print("No matches found")
                await MainActor.run { isSearching = false }
                return
            }

            // Sort by similarity
            bestMatches.sort { $0.similarity > $1.similarity }

            // Calculate relative differences to find truly distinct matches
            let maxSimilarity = bestMatches.first?.similarity ?? 0
            let minSimilarity = bestMatches.last?.similarity ?? 0
            let similarityRange = maxSimilarity - minSimilarity

            print(
                "📊 Similarity range: \(String(format: "%.2f", minSimilarity)) to \(String(format: "%.2f", maxSimilarity)) (range: \(String(format: "%.2f", similarityRange)))"
            )

            // Only keep top results that are meaningfully different from the rest
            var topMatches: [SearchMatch] = []

            if similarityRange > 0.01 { // If there's meaningful variation
                // Take matches that are significantly above average
                let averageSimilarity = bestMatches.map { $0.similarity }.reduce(0, +) / Float(bestMatches.count)
                topMatches = bestMatches.filter { $0.similarity > averageSimilarity }.prefix(5).map { $0 }
            } else {
                // All chunks are very similar - just take the top one
                if let best = bestMatches.first {
                    topMatches = [best]
                }
            }

            if topMatches.isEmpty {
                print("All content has similar relevance")
                await MainActor.run { isSearching = false }
                return
            }

            print("Found \(topMatches.count) distinct semantic matches:")
            for (index, match) in topMatches.enumerated() {
                print(
                    "  \(index + 1). Similarity: \(String(format: "%.2f%%", match.similarity * 100)) - \(match.text.prefix(60))..."
                )
            }

            // Highlight the most relevant match
            if let bestMatch = topMatches.first {
                await MainActor.run {
                    // Store the matched text for highlighting (don't modify searchQuery)
                    semanticMatchText = bestMatch.text
                    isSearching = false
                }
            } else {
                await MainActor.run {
                    isSearching = false
                }
            }
        }
    }

    /// Extracts only the base content from a note, excluding all AI-generated blocks
    private func extractBaseContent(from content: String) -> String {
        // Define all AI-generated section markers
        let markers = [
            "\n\n---\n`Summary",
            "\n\n---\n`Translation to ",
            "\n\n---\n`Patched",
            "\n\n---\n`Reformulated"
        ]

        // Find the earliest AI section marker
        var firstAIIndex: String.Index?

        for marker in markers {
            if let range = content.range(of: marker) {
                if firstAIIndex == nil || range.lowerBound < firstAIIndex! {
                    firstAIIndex = range.lowerBound
                }
            }
        }

        // Return only content before first AI section
        if let firstIndex = firstAIIndex {
            return String(content[..<firstIndex])
        }

        return content
    }

    private func splitIntoMeaningfulChunks(_ text: String) -> [(text: String, range: Range<String.Index>)] {
        var chunks: [(text: String, range: Range<String.Index>)] = []

        // Use regex to split by sentence boundaries (. followed by space/newline, or just newlines)
        let sentencePattern = #"[^.!?\n]+[.!?]"#

        guard let regex = try? NSRegularExpression(pattern: sentencePattern, options: []) else {
            return []
        }

        let nsText = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))

        for match in matches {
            if let range = Range(match.range, in: text) {
                let sentence = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)

                // Only include sentences with meaningful content (at least 10 characters)
                if sentence.count >= 10 {
                    chunks.append((text: sentence, range: range))
                }
            }
        }

        // If regex didn't find anything, fall back to newline splitting
        if chunks.isEmpty {
            let lines = text.components(separatedBy: .newlines)
            var currentIndex = text.startIndex

            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)

                if trimmed.count >= 10 {
                    if let range = text.range(of: trimmed, range: currentIndex ..< text.endIndex) {
                        chunks.append((text: trimmed, range: range))
                        currentIndex = range.upperBound
                    }
                }
            }
        }

        return chunks
    }

    private func splitIntoChunks(_ text: String) -> [(text: String, range: Range<String.Index>)] {
        var chunks: [(text: String, range: Range<String.Index>)] = []

        // Split by sentences (ending with . ! ?)
        let sentencePattern = "[^.!?]+[.!?]+"
        if let regex = try? NSRegularExpression(pattern: sentencePattern, options: []) {
            let nsText = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))

            for match in matches {
                if let range = Range(match.range, in: text) {
                    let sentence = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !sentence.isEmpty {
                        chunks.append((text: sentence, range: range))
                    }
                }
            }
        }

        // Fallback: split by paragraphs if no sentences found
        if chunks.isEmpty {
            let paragraphs = text.components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            var currentIndex = text.startIndex

            for paragraph in paragraphs {
                if let range = text.range(of: paragraph, range: currentIndex ..< text.endIndex) {
                    chunks.append((text: paragraph, range: range))
                    currentIndex = range.upperBound
                }
            }
        }

        return chunks
    }
}

// String extension for finding ranges
extension String {
    func ranges(of searchString: String, options: String.CompareOptions = []) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var searchRange = startIndex ..< endIndex

        while let range = range(of: searchString, options: options, range: searchRange) {
            ranges.append(range)
            searchRange = range.upperBound ..< endIndex
        }

        return ranges
    }
}

// MARK: - View Extension for Conditional Modifiers

extension View {
    /// Conditionally apply a modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
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
