//
//  NoteListView.swift
//  NoteTaker
//
//  Sidebar displaying list of notes with search
//

import SwiftUI

struct NoteListView: View {
    @ObservedObject var viewModel: NoteViewModel

    // Extract List content to avoid compiler crash
    private var noteListContent: some View {
        List(selection: $viewModel.selectedNoteID) {
            ForEach(viewModel.displayItems) { item in
                noteRowContent(for: item)
                    .tag(item.id)
                    .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            }
            .onDelete { indexSet in
                let items = viewModel.displayItems
                for index in indexSet {
                    viewModel.deleteNote(id: items[index].id)
                }
            }
        }
    }

    // Extract row content with context menu
    private func noteRowContent(for item: NoteListItem) -> some View {
        NoteRowView(item: item) {
            viewModel.deleteNote(id: item.id)
        }
        .contextMenu {
            contextMenuItems(for: item)
        }
    }

    // Extract context menu
    @ViewBuilder
    private func contextMenuItems(for item: NoteListItem) -> some View {
        Button {
            if let note = viewModel.note(for: item.id) {
                Task {
                    await viewModel.generateSummary(for: note)
                }
            }
        } label: {
            Label("Summarize", systemImage: "doc.text.magnifyingglass")
        }

        Button {
            if let note = viewModel.note(for: item.id) {
                Task {
                    await viewModel.generateTranslation(for: note)
                }
            }
        } label: {
            Label("Translate", systemImage: "globe")
        }

        Divider()

        Button(role: .destructive) {
            viewModel.deleteNote(id: item.id)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar (Mac Notes style - minimal)
            SearchBarView(searchQuery: $viewModel.searchQuery, isSearching: $viewModel.isSearching)
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Note List (Clean Mac Notes style)
            if viewModel.hasNotes {
                noteListContent
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
    let item: NoteListItem
    let onDelete: () -> Void
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(item.displayTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)

                    Spacer()

                    Text(item.formattedCreatedDate)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.7))
                }

                Text(item.preview)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding(.vertical, 2)

            if isHovering {
                Button(action: onDelete) {
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
