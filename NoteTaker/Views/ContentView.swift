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
    @EnvironmentObject var aiEngine: AIEngine
    @State private var showingSettings = false

    var body: some View {
        NavigationSplitView {
            // Sidebar: Note list (minimal Mac Notes style)
            NoteListView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 350)
        } detail: {
            // Main content: Note editor
            if let selectedNote = viewModel.selectedNote {
                NoteEditorView(note: selectedNote, viewModel: viewModel)
                    .id(selectedNote.id) // Force new view instance for each note
            } else {
                EmptyStateView()
            }
        }
            .toolbar {
                ToolbarItemGroup(placement: .principal) {
                    // AI Tool Buttons - Modern, compact design
                    HStack(alignment: .center, spacing: 6) {
                        // Autocomplete Toggle with Switch
                        AutocompleteToggle(isEnabled: $viewModel.isAutocompleteEnabled)
                            .help("Toggle Autocomplete")

                        Divider()
                            .frame(height: 20)
                            .padding(.horizontal, 4)

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
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    )
                }

                ToolbarItemGroup(placement: .automatic) {
                    HStack(spacing: 8) {
                        Button(action: { showingSettings.toggle() }) {
                            Image(systemName: "gear")
                                .font(.system(size: 16))
                        }
                        .buttonStyle(.plain)
                        .help("AI Settings & Prompts")

                        Button(action: {
                            NotificationCenter.default.post(name: .createNewNote, object: nil)
                        }) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 16))
                        }
                        .buttonStyle(.plain)
                        .help("New Note (⌘N)")
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    )
                }
            }
        .sheet(isPresented: $showingSettings) {
            AISettingsView(viewModel: viewModel)
        }
    }
}

// MARK: - Autocomplete Toggle Component

struct AutocompleteToggle: View {
    @Binding var isEnabled: Bool
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 6) {
            Text("Autocomplete")
                .font(.system(size: 11, weight: .medium))
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

// MARK: - AI Tool Button Component

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

                // Keyboard shortcut before label
                Text("⌘")
                    .font(.system(size: 10, weight: .medium, design: .default))
                    .foregroundColor(foregroundColor.opacity(0.7))

                // Label with first letter in bold
                Text(attributedLabel)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(foregroundColor)
            .scaleEffect(isHovered && isEnabled ? 1.03 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var attributedLabel: AttributedString {
        var result = AttributedString(label)

        // Make first character bold
        if let firstCharRange = result.range(of: String(label.prefix(1))) {
            result[firstCharRange].font = .system(size: 11, weight: .bold)
        }

        return result
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

// MARK: - Empty State (Minimal Mac style)

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "note.text")
                .font(.system(size: 56))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Note Selected")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)

            Text("Select a note or create a new one")
                .font(.system(size: 13))
                .foregroundColor(.secondary.opacity(0.8))

            Button(action: {
                NotificationCenter.default.post(name: .createNewNote, object: nil)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .semibold))
                    Text("New Note")
                        .font(.system(size: 13))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            // Note: Keyboard shortcut ⌘N is handled by toolbar button
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
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
