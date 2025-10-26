//
//  NoteListView.swift
//  ZetaNotes
//
//  Sidebar displaying list of notes with search
//

import SwiftUI

struct NoteListView: View {
    @ObservedObject var viewModel: NoteViewModel

    // Extract List content to avoid compiler crash
    private var noteListContent: some View {
        ScrollViewReader { proxy in
            List(selection: $viewModel.selectedNoteID) {
                ForEach(viewModel.displayItems) { item in
                    noteRowContent(for: item)
                        .tag(item.id)
                        .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                        .id(item.id)
                }
                .onDelete { indexSet in
                    let items = viewModel.displayItems
                    for index in indexSet {
                        viewModel.deleteNote(id: items[index].id)
                    }
                }
            }
            .onChange(of: viewModel.selectedNoteID) { newID in
                if let id = newID {
                    withAnimation {
                        proxy.scrollTo(id, anchor: .center)
                    }
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
            // Compact header with title bar spacing
            VStack(spacing: 8) {
                // Search Bar only
                SearchBarView(searchQuery: $viewModel.searchQuery, isSearching: $viewModel.isSearching)
                    .padding(.horizontal, 12)
                    .padding(.top, 40) // Increased to account for title bar area
                    .padding(.bottom, 6)
            }

            // Note List (Modern glass morphism style)
            if viewModel.hasNotes {
                noteListContent
                    .listStyle(.sidebar)
                    .scrollContentBackground(.hidden)
                    .background(Color(nsColor: .textBackgroundColor))
            } else {
                // Compact empty state
                VStack(spacing: 14) {
                    Image(systemName: "note.text")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.6))

                    Text("No Notes")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)

                    Button(action: {
                        viewModel.createNewNote()
                    }) {
                        Text("Create Note")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
    }
}

// MARK: - Note Row (Clean and compact)

struct NoteRowView: View {
    let item: NoteListItem
    let onDelete: () -> Void
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.displayTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)

                    Spacer()

                    Text(item.formattedCreatedDate)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.7))
                }

                Text(item.preview)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding(.vertical, 2)

            // Always show button but with opacity
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
            .help("Delete note")
            .opacity(isHovering ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.15), value: isHovering)
        }
        .contentShape(Rectangle()) // Make entire row detect hover
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
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
