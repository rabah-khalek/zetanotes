//
//  NoteViewModel.swift
//  NoteTaker
//
//  ViewModel coordinating note operations and AI features
//

import Foundation
import CoreData
import Combine

/// ViewModel managing note state and AI operations
/// Bridges UI layer with data and AI services
@MainActor
class NoteViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var notes: [Note] = []
    @Published var selectedNote: Note?
    @Published var searchQuery = ""
    @Published var isSearching = false
    @Published var searchResults: [SearchResult] = []

    @Published var autocompleteSuggestion: String?
    @Published var isGeneratingSummary = false

    // MARK: - Dependencies

    private let persistenceController: PersistenceController
    private let aiEngine: AIEngine
    private lazy var searchEngine: SemanticSearchEngine = {
        SemanticSearchEngine(
            embeddingService: aiEngine.embeddingService,
            persistenceController: persistenceController
        )
    }()

    private var cancellables = Set<AnyCancellable>()
    private var debounceTimer: Timer?

    // MARK: - Initialization

    init(persistenceController: PersistenceController = .shared, aiEngine: AIEngine = .shared) {
        self.persistenceController = persistenceController
        self.aiEngine = aiEngine

        setupObservers()
        loadNotes()
        setupSearchDebouncing()

        // Load AI model asynchronously
        Task {
            await aiEngine.loadModel()
        }
    }

    // MARK: - Setup

    private func setupObservers() {
        // Observe new note creation requests
        NotificationCenter.default.publisher(for: .createNewNote)
            .sink { [weak self] _ in
                self?.createNewNote()
            }
            .store(in: &cancellables)

        // Observe note deletion requests
        NotificationCenter.default.publisher(for: .deleteNote)
            .sink { [weak self] notification in
                if let note = notification.object as? Note {
                    self?.deleteNote(note)
                }
            }
            .store(in: &cancellables)
    }

    private func setupSearchDebouncing() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                Task {
                    await self?.performSearch(query: query)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Note Management

    func loadNotes() {
        notes = persistenceController.fetchAllNotes()
    }

    func createNewNote() {
        print("📝 Creating new note...")
        let newNote = persistenceController.createNote()
        notes.insert(newNote, at: 0)
        selectedNote = newNote
        print("✅ Note created: \(newNote.id?.uuidString ?? "unknown")")
    }

    func deleteNote(_ note: Note) {
        persistenceController.deleteNote(note)
        notes.removeAll { $0.id == note.id }

        if selectedNote?.id == note.id {
            selectedNote = notes.first
        }
    }

    func saveNote(_ note: Note) {
        note.touch()
        persistenceController.save()

        // Regenerate title if empty
        if note.title?.isEmpty ?? true {
            note.generateTitleFromContent()
            persistenceController.save()
        }

        // Reindex for semantic search (async, non-blocking)
        Task {
            await searchEngine.reindexNote(note)
        }
    }

    // MARK: - Search

    func performSearch(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true

        // Perform hybrid search (semantic + keyword)
        let results = await searchEngine.hybridSearch(query: query, limit: 20)

        await MainActor.run {
            self.searchResults = results
            self.isSearching = false
        }
    }

    func clearSearch() {
        searchQuery = ""
        searchResults = []
        isSearching = false
    }

    // MARK: - AI Features

    /// Generates autocomplete suggestion for current note content
    /// Implements typing pause detection - only generates suggestions after user stops typing
    /// This reduces overhead and avoids generating suggestions while actively typing
    func requestAutocomplete(for text: String) {
        // Cancel any existing timer
        debounceTimer?.invalidate()

        // DON'T clear existing suggestion - let the new one replace it
        // This prevents race condition when Tab is pressed

        // Start new debounce timer (500ms pause before generating)
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            guard let self = self else { return }

            Task {
                await self.generateAutocomplete(for: text)
            }
        }
    }

    private func generateAutocomplete(for text: String) async {
        guard aiEngine.isModelLoaded else { return }

        // Generate suggestion only when user has paused typing
        let suggestion = await aiEngine.autocomplete(for: text, maxTokens: 20)

        await MainActor.run {
            // Only set suggestion if it's valid and non-empty
            if let suggestion = suggestion, !suggestion.isEmpty {
                self.autocompleteSuggestion = suggestion
            } else {
                self.autocompleteSuggestion = nil
            }
        }
    }

    func acceptAutocomplete() -> String? {
        let suggestion = autocompleteSuggestion
        autocompleteSuggestion = nil
        return suggestion
    }

    func dismissAutocomplete() {
        autocompleteSuggestion = nil
    }

    /// Generates a summary for the given note
    func generateSummary(for note: Note) async {
        guard aiEngine.isModelLoaded else { return }
        guard let content = note.content, !content.isEmpty else { return }

        await MainActor.run {
            self.isGeneratingSummary = true
        }

        let summary = await aiEngine.summarize(content, maxLength: 150)

        await MainActor.run {
            note.summary = summary
            self.persistenceController.save()
            self.isGeneratingSummary = false
        }
    }

    /// Generates embeddings for all notes (background operation)
    func indexAllNotes() async {
        await searchEngine.indexAllNotes()
    }

    // MARK: - Utility

    var displayNotes: [Note] {
        if !searchResults.isEmpty {
            return searchResults.map { $0.note }
        }
        return notes
    }

    var hasNotes: Bool {
        return !notes.isEmpty
    }
}
