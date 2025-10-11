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
            // Search Bar
            SearchBarView(searchQuery: $viewModel.searchQuery, isSearching: $viewModel.isSearching)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)

            Divider()

            // Note List
            if viewModel.hasNotes {
                List(selection: $viewModel.selectedNote) {
                    ForEach(viewModel.displayNotes, id: \.id) { note in
                        NoteRowView(note: note)
                            .tag(note)
                            .contextMenu {
                                Button(action: {
                                    Task {
                                        await viewModel.generateSummary(for: note)
                                    }
                                }) {
                                    Label("Generate Summary", systemImage: "doc.text.magnifyingglass")
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
            } else {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No Notes")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Button(action: {
                        viewModel.createNewNote()
                    }) {
                        Label("Create First Note", systemImage: "plus")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Notes")
    }
}

// MARK: - Note Row

struct NoteRowView: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.displayTitle)
                .font(.headline)
                .lineLimit(1)

            if let summary = note.summary, !summary.isEmpty {
                Text(summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            } else {
                Text(note.contentPreview)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Text(note.formattedUpdatedDate)
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding(.vertical, 4)
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
