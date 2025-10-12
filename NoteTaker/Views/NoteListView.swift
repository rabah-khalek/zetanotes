//
//  NoteListView.swift
//  NoteTaker
//
//  Sidebar displaying list of notes with search
//

import SwiftUI

struct NoteListView: View {
    @ObservedObject var viewModel: NoteViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar (Mac Notes style - minimal)
            SearchBarView(searchQuery: $viewModel.searchQuery, isSearching: $viewModel.isSearching)
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Note List (Clean Mac Notes style)
            if viewModel.hasNotes {
                List(selection: $viewModel.selectedNote) {
                    ForEach(viewModel.displayNotes, id: \.objectID) { note in
                        NoteRowView(note: note)
                            .tag(note)
                            .id(note.objectID) // Force refresh on changes
                            .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                            .contextMenu {
                                Button(action: {
                                    Task {
                                        await viewModel.generateSummary(for: note)
                                    }
                                }) {
                                    Label("Summarize", systemImage: "doc.text.magnifyingglass")
                                }

                                Button(action: {
                                    Task {
                                        await viewModel.generateTranslation(for: note)
                                    }
                                }) {
                                    Label("Translate", systemImage: "globe")
                                }

                                Divider()

                                Button(role: .destructive, action: {
                                    viewModel.deleteNote(note)
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let note = viewModel.displayNotes[index]
                            viewModel.deleteNote(note)
                        }
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
            } else {
                // Empty state (minimal)
                VStack(spacing: 16) {
                    Image(systemName: "note.text")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary.opacity(0.6))

                    Text("No Notes")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)

                    Button(action: {
                        viewModel.createNewNote()
                    }) {
                        Text("Create Note")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Notes")
    }
}

// MARK: - Note Row (Mac Notes style - clean and minimal)

struct NoteRowView: View {
    @ObservedObject var note: Note
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                // Title and date on same line
                HStack {
                    Text(note.displayTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)

                    Spacer()

                    Text(note.formattedUpdatedDate)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.7))
                }

                // Preview text (either summary or content)
                if let summary = note.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                } else {
                    Text(note.contentPreview)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 2)

            // Delete button (shown on hover)
            if isHovering {
                Button(action: {
                    NotificationCenter.default.post(name: .deleteNote, object: note)
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
                .help("Delete note")
            }
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Preview

struct NoteListView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = NoteViewModel(persistenceController: .preview)

        NavigationSplitView {
            NoteListView(viewModel: viewModel)
        } detail: {
            Text("Select a note")
        }
    }
}
