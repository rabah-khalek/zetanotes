//
//  AISettingsView.swift
//  NoteTaker
//
//  AI prompt customization settings
//

import SwiftUI

struct AISettingsView: View {
    @ObservedObject var viewModel: NoteViewModel
    @EnvironmentObject var aiEngine: AIEngine
    @StateObject private var modelDownloader = ModelDownloader()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("AI Settings")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // Settings Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Model Selection Section
                    ModelSelectionSection(
                        aiEngine: aiEngine,
                        modelDownloader: modelDownloader
                    )

                    Divider()

                    // Autocomplete Prompt
                    PromptSection(
                        title: "Autocomplete",
                        icon: "text.cursor",
                        prompt: $viewModel.autocompletePrompt,
                        placeholder: "Enter prompt for text completion...",
                        defaultPrompt: "Continue this text naturally:"
                    )

                    Divider()

                    // Title Generation Prompt
                    PromptSection(
                        title: "Title Generation",
                        icon: "arrow.triangle.2.circlepath",
                        prompt: $viewModel.titleGenerationPrompt,
                        placeholder: "Enter prompt for title generation...",
                        defaultPrompt: "Generate a short, concise title for this text (5 words max):"
                    )

                    Divider()

                    // Summarization Prompt
                    PromptSection(
                        title: "Summarization",
                        icon: "doc.text.magnifyingglass",
                        prompt: $viewModel.summarizationPrompt,
                        placeholder: "Enter prompt for summarization...",
                        defaultPrompt: "Summarize the following text in one concise sentence:"
                    )

                    Divider()

                    // Translation Prompt
                    PromptSection(
                        title: "Translation",
                        icon: "globe",
                        prompt: $viewModel.translationPrompt,
                        placeholder: "Enter prompt for translation...",
                        defaultPrompt: "Translate the following text to {language}:"
                    )

                    Divider()

                    // Patch Prompt
                    PromptSection(
                        title: "Patch",
                        icon: "checkmark.circle",
                        prompt: $viewModel.autoCorrectPrompt,
                        placeholder: "Enter prompt for patching...",
                        defaultPrompt: "Correct only the grammar and spelling errors in this text. Keep the same meaning and style:"
                    )

                    Divider()

                    // Reformulate Prompt
                    PromptSection(
                        title: "Reformulate",
                        icon: "arrow.2.squarepath",
                        prompt: $viewModel.reformulatePrompt,
                        placeholder: "Enter prompt for reformulation...",
                        defaultPrompt: "Reformulate this text to make it clearer and more professional. Keep the same meaning:"
                    )

                    // Language Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Target Language", systemImage: "globe")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Picker("Language", selection: $viewModel.targetLanguage) {
                            Text("English — High confidence").tag("English")
                            Text("Chinese — High confidence").tag("Chinese")
                            Text("Spanish — Medium confidence").tag("Spanish")
                            Text("French — Medium confidence").tag("French")
                            Text("German — Medium confidence").tag("German")
                            Text("Portuguese — Medium confidence").tag("Portuguese")
                            Text("Italian — Medium confidence").tag("Italian")
                            Text("Dutch — Medium confidence").tag("Dutch")
                            Text("Japanese — Low–Medium confidence").tag("Japanese")
                            Text("Korean — Low–Medium confidence").tag("Korean")
                            Text("Russian — Low confidence").tag("Russian")
                            Text("Arabic — Low confidence").tag("Arabic")
                        }
                        .pickerStyle(.menu)
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                }
                .padding()
            }

            Divider()

            // Footer
            HStack {
                Button("Reset to Defaults") {
                    viewModel.resetPromptsToDefaults()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding()
        }
        .frame(width: 650, height: 650)
    }
}

// MARK: - Model Selection Section

struct ModelSelectionSection: View {
    @ObservedObject var aiEngine: AIEngine
    @ObservedObject var modelDownloader: ModelDownloader

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("AI Model", systemImage: "cpu")
                .font(.headline)
                .fontWeight(.semibold)

            Text("Choose between fast lightweight mode or high-quality mode")
                .font(.caption)
                .foregroundColor(.secondary)

            // Model Cards
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
        .padding()
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
}

// MARK: - Model Card Component

struct ModelCard: View {
    let model: AIModel
    let isSelected: Bool
    let isDownloaded: Bool
    let isDownloading: Bool
    let downloadProgress: Double
    let onSelect: () -> Void
    let onDownload: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .secondary)
                .font(.title3)

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
            if isDownloading {
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

// MARK: - Prompt Section Component

struct PromptSection: View {
    let title: String
    let icon: String
    @Binding var prompt: String
    let placeholder: String
    let defaultPrompt: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .fontWeight(.medium)

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

// MARK: - Preview

struct AISettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AISettingsView(viewModel: NoteViewModel())
    }
}
