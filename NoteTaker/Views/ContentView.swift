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
                ToolbarItem(placement: .principal) {
                    Group {
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

                ToolbarItem(placement: .automatic) {
                    Group {
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

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AIEngine.shared)
    }
}
