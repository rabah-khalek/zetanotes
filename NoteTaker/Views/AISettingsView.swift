//
//  AISettingsView.swift
//  NoteTaker
//
//  AI settings with sidebar navigation and custom services
//

import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable {
    case general = "General"
    case model = "AI Model"
    case prompts = "Prompts"
    case customServices = "Custom Services"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .model: return "cpu"
        case .prompts: return "text.alignleft"
        case .customServices: return "wand.and.stars"
        }
    }
}

struct AISettingsView: View {
    @ObservedObject var viewModel: NoteViewModel
    @EnvironmentObject var aiEngine: AIEngine
    @StateObject private var modelDownloader = ModelDownloader()
    @StateObject private var customServiceManager = CustomServiceManager.shared
    @Environment(\.dismiss) var dismiss

    @State private var selectedSection: SettingsSection = .general
    @State private var showingCustomServiceEditor = false
    @State private var editingService: CustomService?

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
                        GeneralSettingsContent(dismiss: dismiss)
                    case .model:
                        ModelSettingsContent(
                            aiEngine: aiEngine,
                            modelDownloader: modelDownloader
                        )
                    case .prompts:
                        PromptsSettingsContent(viewModel: viewModel)
                    case .customServices:
                        CustomServicesContent(
                            customServiceManager: customServiceManager,
                            showingEditor: $showingCustomServiceEditor,
                            editingService: $editingService
                        )
                    }
                }
                .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 850, height: 650)
        .sheet(item: $editingService) { service in
            CustomServiceEditorView(
                service: service,
                isPresented: Binding(
                    get: { editingService != nil },
                    set: { if !$0 { editingService = nil } }
                ),
                onSave: { updatedService in
                    customServiceManager.updateService(updatedService)
                    editingService = nil
                }
            )
        }
        .sheet(isPresented: $showingCustomServiceEditor) {
            CustomServiceEditorView(
                service: CustomService(),
                isPresented: $showingCustomServiceEditor,
                onSave: { service in
                    customServiceManager.addService(service)
                    showingCustomServiceEditor = false
                }
            )
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
                    .fill(isSelected ? Color.blue.opacity(0.08) : (isHovered ? Color.secondary.opacity(0.06) : Color.clear))
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
    @ObservedObject var licenseManager = LicenseManager.shared
    @AppStorage("preferredAppearance") private var preferredAppearance: String = "auto"

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("General Settings")
                .font(.title2)
                .fontWeight(.semibold)

            // Pro Status / Upgrade Section
            ProStatusSection(dismiss: dismiss)

            Divider()

            // Appearance Settings
            VStack(alignment: .leading, spacing: 12) {
                Label("Appearance", systemImage: "paintbrush")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("Choose how the app looks")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("", selection: $preferredAppearance) {
                    Text("🌗 Auto").tag("auto")
                    Text("☀️ Light").tag("light")
                    Text("🌙 Dark").tag("dark")
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(8)

            Divider()

            // About Section
            VStack(alignment: .leading, spacing: 8) {
                Label("About NoteTaker", systemImage: "info.circle")
                    .font(.headline)
                    .fontWeight(.semibold)

                HStack {
                    Text("Version")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("1.0.0")
                        .fontWeight(.medium)
                }

                if licenseManager.isPro {
                    HStack {
                        Text("License")
                            .foregroundColor(.secondary)
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Text("Pro")
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(8)
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
                                case .failure(let error):
                                    print("❌ Download failed: \(error)")
                                }
                            }
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

// MARK: - Custom Services Content

struct CustomServicesContent: View {
    @ObservedObject var customServiceManager: CustomServiceManager
    @ObservedObject var licenseManager = LicenseManager.shared
    @Binding var showingEditor: Bool
    @Binding var editingService: CustomService?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Custom Services")
                        .font(.title2)
                        .fontWeight(.semibold)

                    if licenseManager.isPro {
                        Text("Create custom AI services with your own prompts and keyboard shortcuts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Upgrade to Pro to create custom AI services")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                Spacer()

                // Add button with lock for non-Pro users - Enhanced
                Button(action: {
                    if licenseManager.isPro {
                        editingService = nil
                        showingEditor = true
                    } else {
                        NotificationCenter.default.post(
                            name: .showUpgradePrompt,
                            object: UpgradePromptView.PromptType.general
                        )
                    }
                }) {
                    HStack(spacing: 6) {
                        if !licenseManager.isPro {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11))
                        }
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text(licenseManager.isPro ? "Add Service" : "Upgrade to Add")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(licenseManager.isPro ? .white : .orange)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(licenseManager.isPro ? Color.blue : Color.orange.opacity(0.15))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(!licenseManager.isPro && !customServiceManager.canAddService())
                .help(licenseManager.isPro ?
                      (customServiceManager.canAddService() ? "Create a new custom service" : "Maximum services reached") :
                      "Upgrade to Pro to create custom services")
            }

            if customServiceManager.services.isEmpty {
                // Empty State - Enhanced
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)

                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 42))
                            .foregroundColor(.blue.opacity(0.6))
                    }

                    VStack(spacing: 8) {
                        Text("No Custom Services Yet")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)

                        Text(licenseManager.isPro ?
                             "Create your first custom AI service to enhance your workflow" :
                             "Upgrade to Pro to unlock custom AI services")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 400)
                    }

                    if licenseManager.isPro {
                        Button(action: {
                            editingService = nil
                            showingEditor = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                Text("Create Your First Service")
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 70)
            } else {
                // Services List
                VStack(spacing: 12) {
                    ForEach(customServiceManager.services) { service in
                        CustomServiceRow(
                            service: service,
                            onEdit: {
                                editingService = service
                            },
                            onDelete: {
                                customServiceManager.deleteService(service)
                            }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Custom Service Row

struct CustomServiceRow: View {
    let service: CustomService
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false
    @State private var showDeleteConfirm = false

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                // Service name with keyboard shortcut
                HStack(spacing: 6) {
                    // Keyboard shortcut badge
                    HStack(spacing: 2) {
                        Text("⌘")
                            .font(.system(size: 10, weight: .semibold))
                        Text(service.keyboardShortcut)
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(service.color.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(service.color.color.opacity(0.15))
                    .cornerRadius(4)

                    // Service name
                    Text(service.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }

                // Prompt preview with fade effect
                Text(service.prompt.prefix(60) + (service.prompt.count > 60 ? "..." : ""))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Action buttons - always visible on hover with smooth transition
            HStack(spacing: 6) {
                Button(action: onEdit) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .medium))
                        if isHovered {
                            Text("Edit")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(isHovered ? 0.1 : 0.05))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .help("Edit Service")

                Button(action: { showDeleteConfirm = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 11, weight: .medium))
                        if isHovered {
                            Text("Delete")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.red.opacity(isHovered ? 0.1 : 0.05))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .help("Delete Service")
            }
            .opacity(isHovered ? 1 : 0.6)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? Color(nsColor: .controlBackgroundColor).opacity(0.8) : Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    isHovered ? service.color.color.opacity(0.4) : Color.gray.opacity(0.15),
                    lineWidth: isHovered ? 1.5 : 1
                )
        )
        .shadow(color: isHovered ? Color.black.opacity(0.05) : Color.clear, radius: 4, x: 0, y: 2)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .alert("Delete Service?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("Are you sure you want to delete '\(service.name)'? This action cannot be undone.")
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
                            case .failure(let error):
                                print("❌ Download failed: \(error)")
                            }
                        }
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

    @ObservedObject var licenseManager = LicenseManager.shared

    private var isLocked: Bool {
        !licenseManager.canUseModel(model)
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                // Model name with lock icon
                HStack(spacing: 6) {
                    Text(model.displayName)
                        .font(.system(size: 14, weight: .semibold))

                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

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
            if isLocked {
                // Show upgrade button for locked models
                Button(action: {
                    NotificationCenter.default.post(
                        name: .showUpgradePrompt,
                        object: UpgradePromptView.PromptType.modelSwitching
                    )
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                        Text("Upgrade")
                            .font(.caption)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundColor(.orange)
            } else if isDownloading {
                VStack(spacing: 4) {
                    ProgressView(value: downloadProgress)
                        .frame(width: 80)
                    Text("\(Int(downloadProgress * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
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
            } else if !isSelected {
                Button(action: onSelect) {
                    Text("Use This")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Active")
                        .font(.caption)
                        .foregroundColor(.green)
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

                // Pro badge (moved to the right)
                if !licenseManager.canEditPrompts {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.caption2)
                        Text("Pro")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }

            // Display prompt with {language} replaced by actual language
            TextEditor(text: Binding(
                get: { viewModel.translationPrompt.replacingOccurrences(of: "{language}", with: viewModel.targetLanguage) },
                set: { newValue in
                    // When editing, replace the actual language back to {language} placeholder
                    viewModel.translationPrompt = newValue.replacingOccurrences(of: viewModel.targetLanguage, with: "{language}")
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
                .disabled(!licenseManager.canEditPrompts)
                .opacity(licenseManager.canEditPrompts ? 1.0 : 0.6)

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

                if !licenseManager.canEditPrompts {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.caption2)
                        Text("Pro")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
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
                .disabled(!licenseManager.canEditPrompts)
                .opacity(licenseManager.canEditPrompts ? 1.0 : 0.6)

            if prompt.isEmpty {
                Text(placeholder)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ProStatusSection: View {
    @ObservedObject var licenseManager = LicenseManager.shared
    let dismiss: DismissAction

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if licenseManager.isPro {
                // Pro Active State
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.green)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pro Active")
                            .font(.headline)
                            .fontWeight(.semibold)

                        if let email = licenseManager.licenseEmail {
                            Text(email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Button("Manage") {
                        NotificationCenter.default.post(name: .showLicenseActivation, object: nil)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    #if DEBUG
                    Button("Deactivate (Dev)") {
                        licenseManager.deactivateLicense()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundColor(.orange)
                    #endif
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            } else {
                // Free Tier State
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.orange)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Upgrade to Pro")
                                .font(.headline)
                                .fontWeight(.semibold)

                            Text("Download premium AI models & customize prompts")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }

                    HStack(spacing: 12) {
                        Button(action: {
                            dismiss()
                            // Small delay to ensure settings closes before upgrade prompt shows
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                NotificationCenter.default.post(
                                    name: .showUpgradePrompt,
                                    object: UpgradePromptView.PromptType.general
                                )
                            }
                        }) {
                            HStack {
                                Image(systemName: "cart.fill")
                                Text("Upgrade for $14.99")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                        Button("Enter License Key") {
                            dismiss()
                            // Small delay to ensure settings closes before activation prompt shows
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                NotificationCenter.default.post(name: .showLicenseActivation, object: nil)
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview

struct AISettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AISettingsView(viewModel: NoteViewModel())
            .environmentObject(AIEngine.shared)
    }
}
