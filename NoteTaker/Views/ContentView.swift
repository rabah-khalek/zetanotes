//
//  ContentView.swift
//  NoteTaker
//
//  Main application view with three-column layout
//  Sidebar: Note list | Main: Editor | Inspector: AI features
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = NoteViewModel()
    @EnvironmentObject var aiEngine: AIEngine

    var body: some View {
        NavigationSplitView {
            // Sidebar: Note list
            NoteListView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } detail: {
            // Main content: Note editor
            if let selectedNote = viewModel.selectedNote {
                NoteEditorView(note: selectedNote, viewModel: viewModel)
            } else {
                EmptyStateView()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                // AI Status Indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(aiEngine.isModelLoaded ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)

                    Text(aiEngine.statusDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // New Note Button
                Button(action: {
                    viewModel.createNewNote()
                }) {
                    Label("New Note", systemImage: "square.and.pencil")
                }
                .keyboardShortcut("n", modifiers: .command)

                // Index Notes Button
                Button(action: {
                    Task {
                        await viewModel.indexAllNotes()
                    }
                }) {
                    Label("Index Notes", systemImage: "arrow.triangle.2.circlepath")
                }
                .help("Generate embeddings for semantic search")
            }
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "note.text")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No Note Selected")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Select a note from the sidebar or create a new one")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: {
                NotificationCenter.default.post(name: .createNewNote, object: nil)
            }) {
                Label("Create Note", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut("n", modifiers: .command)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
