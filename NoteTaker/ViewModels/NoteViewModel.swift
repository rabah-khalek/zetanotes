//
//  NoteViewModel.swift
//  NoteTaker
//
//  ViewModel coordinating note operations and AI features
//

import Foundation
import CoreData
import Combine

// MARK: - Default AI Prompts

/// Centralized default prompts for all AI features
/// These are the instruction portions that come AFTER the content
struct DefaultPrompts {
    static let autocomplete = "Continue naturally:"

    static let summarization = "Summarize in one clear sentence:"

    static let translation = "Translate to {language}. Write ONLY the {language} translation. Do not include the original text. Do not add labels or explanations."

    static let titleGeneration = "Create a short title (maximum 5 words). Write only the title, nothing else."

    static let autoCorrect = "Fix only spelling mistakes. Copy everything else exactly. Do not add labels or explanations. Write only the corrected text."

    static let reformulate = "Rewrite to be clearer and more professional. Keep the same meaning. Do not add labels or explanations. Write only the rewritten text."
}

/// ViewModel managing note state and AI operations
/// Bridges UI layer with data and AI services
@MainActor
class NoteViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var noteListItems: [NoteListItem] = []
    @Published private(set) var searchItemResults: [NoteListItem] = []
    @Published private(set) var selectedNote: Note? {
        willSet {
            // Save the current note before switching to a new one
            if let currentNote = selectedNote, newValue?.id != currentNote.id {
                persistenceController.save()
                print("💾 Saved note before switching: \(currentNote.displayTitle)")
            }
        }
    }
    @Published var selectedNoteID: UUID? {
        didSet {
            updateSelectedNote()
        }
    }
    @Published var searchQuery = ""
    @Published var isSearching = false
    @Published var searchResults: [SearchResult] = []

    @Published var autocompleteSuggestion: String?
    @Published var isGeneratingSummary = false
    @Published var isTranslating = false
    @Published var isGeneratingTitle = false
    @Published var isAutoCorrecting = false
    @Published var isReformulating = false
    @Published var isAutocompleteEnabled = true

    // AI Prompt Customization
    @Published var autocompletePrompt = DefaultPrompts.autocomplete
    @Published var summarizationPrompt = DefaultPrompts.summarization
    @Published var translationPrompt = DefaultPrompts.translation
    @Published var titleGenerationPrompt = DefaultPrompts.titleGeneration
    @Published var autoCorrectPrompt = DefaultPrompts.autoCorrect
    @Published var reformulatePrompt = DefaultPrompts.reformulate
    @Published var targetLanguage = "Spanish"

    // MARK: - Dependencies

    private let persistenceController: PersistenceController
    private let aiEngine: AIEngine
    private let repository: NoteRepository
    private lazy var searchEngine: SemanticSearchEngine = {
        SemanticSearchEngine(
            embeddingService: aiEngine.embeddingService,
            persistenceController: persistenceController
        )
    }()

    private var noteCache: [UUID: Note] = [:]
    private var cancellables = Set<AnyCancellable>()
    private var debounceTimer: Timer?

    // MARK: - Initialization

    init(persistenceController: PersistenceController = .shared, aiEngine: AIEngine = .shared) {
        self.persistenceController = persistenceController
        self.aiEngine = aiEngine
        self.repository = NoteRepository(persistenceController: persistenceController)

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
        NotificationCenter.default.publisher(for: .createNewNote)
            .sink { [weak self] _ in
                self?.createNewNote()
            }
            .store(in: &cancellables)

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
        let fetchedNotes = repository.fetchAllNotes()
        noteCache = Dictionary(uniqueKeysWithValues: fetchedNotes.compactMap { note in
            guard let id = note.id else { return nil }
            return (id, note)
        })

        noteListItems = fetchedNotes.compactMap { repository.makeListItem(from: $0) }
            .sorted(by: { $0.createdAt > $1.createdAt })

        if let existingID = selectedNoteID, noteCache[existingID] != nil {
            updateSelectedNote()
        } else {
            selectedNoteID = noteListItems.first?.id
            if selectedNoteID == nil {
                selectedNote = nil
            }
        }
    }

    func createNewNote() {
        print("📝 Creating new note...")
        let newNote = repository.createNote()

        guard let newItem = repository.makeListItem(from: newNote) else {
            print("⚠️ Failed to create list item for new note")
            return
        }

        noteCache[newItem.id] = newNote
        noteListItems.insert(newItem, at: 0)
        noteListItems.sort(by: { $0.createdAt > $1.createdAt })
        selectedNoteID = newItem.id
        print("✅ Note created: \(newNote.id?.uuidString ?? "unknown")")
    }

    func deleteNote(_ note: Note) {
        guard let id = note.id else { return }
        deleteNote(id: id)
    }

    func deleteNote(id: UUID) {
        guard let note = noteCache[id] else { return }

        let wasSelected = selectedNoteID == id
        repository.deleteNote(note)
        noteCache.removeValue(forKey: id)
        noteListItems.removeAll(where: { $0.id == id })
        searchItemResults.removeAll(where: { $0.id == id })

        if wasSelected {
            selectedNoteID = noteListItems.first?.id
        } else {
            updateSelectedNote()
        }
    }

    func saveNote(_ note: Note) {
        note.touch()
        repository.saveContext()

        if note.title?.isEmpty ?? true {
            note.generateTitleFromContent()
            repository.saveContext()
        }

        if let noteID = note.id {
            NotificationCenter.default.post(
                name: Notification.Name("NoteUpdated"),
                object: noteID
            )
        }

        if let updatedItem = repository.makeListItem(from: note) {
            noteCache[updatedItem.id] = note
            upsertListItem(updatedItem)
            updateSearchItemIfNeeded(updatedItem)
        }

        Task {
            await searchEngine.reindexNote(note)
        }
    }

    // MARK: - Search

    func performSearch(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            searchItemResults = []
            isSearching = false
            return
        }

        isSearching = true

        let results = await searchEngine.hybridSearch(query: query, limit: 20)

        await MainActor.run {
            self.searchResults = results
            self.searchItemResults = results.compactMap { result in
                guard let noteID = result.note.id else { return nil }
                self.noteCache[noteID] = result.note
                return self.repository.makeListItem(from: result.note)
            }
            self.isSearching = false
        }
    }

    func clearSearch() {
        searchQuery = ""
        searchResults = []
        searchItemResults = []
        isSearching = false
    }

    // MARK: - AI Features

    func requestAutocomplete(for text: String) {
        guard isAutocompleteEnabled else {
            autocompleteSuggestion = nil
            return
        }

        debounceTimer?.invalidate()

        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            guard let self = self else { return }

            Task {
                await self.generateAutocomplete(for: text)
            }
        }
    }

    private func generateAutocomplete(for text: String) async {
        guard aiEngine.isModelLoaded else { return }

        // Get the last 500 characters for context
        let contextLength = min(text.count, 500)
        let startIndex = text.index(text.endIndex, offsetBy: -contextLength)
        let context = String(text[startIndex...])

        let prompt = """
        Here is the content:

        \(context)

        Task: \(autocompletePrompt)
        """

        let suggestion = await aiEngine.llmService.generate(
            prompt: prompt,
            maxTokens: 20,
            temperature: 0.3,
            stopSequences: ["\n\n", "###"]
        )

        await MainActor.run {
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

    func generateSummary(for note: Note) async {
        guard aiEngine.isModelLoaded else {
            print("⚠️ Cannot summarize: Model not loaded")
            return
        }
        guard let originalContent = note.content, !originalContent.isEmpty else {
            print("⚠️ Cannot summarize: Content is empty")
            return
        }

        print("🔄 Starting summarization for content: \(originalContent.prefix(100))...")

        let sections = extractContentSections(from: originalContent)

        await MainActor.run {
            self.isGeneratingSummary = true
        }

        let prompt = """
        Here is the content:

        \(sections.baseContent)

        Task: \(summarizationPrompt)
        """

        let summary = await aiEngine.llmService.generate(
            prompt: prompt,
            maxTokens: 100,
            temperature: 0.3,
            stopSequences: ["---", "###", "\n\n"]
        )

        await MainActor.run {
            if let summary = summary, !summary.isEmpty {
                print("✅ Summary generated: \(summary)")

                let summaryBlock = "\n\n--- Summary ---\n\n" + summary
                note.content = reconstructContent(
                    base: sections.baseContent,
                    summary: summaryBlock,
                    translation: sections.translationBlock,
                    autoCorrect: sections.autoCorrectedBlock,
                    reformulated: sections.reformulatedBlock
                )

                self.saveNote(note)
            } else {
                print("❌ Summary generation returned nil or empty")
            }
            self.isGeneratingSummary = false
        }
    }

    func indexAllNotes() async {
        await searchEngine.indexAllNotes()
    }

    func generateTranslation(for note: Note) async {
        guard aiEngine.isModelLoaded else { return }
        guard let originalContent = note.content, !originalContent.isEmpty else { return }

        print("🔄 Starting translation to \(targetLanguage) for content: \(originalContent.prefix(100))...")

        let sections = extractContentSections(from: originalContent)

        await MainActor.run {
            self.isTranslating = true
        }

        let prompt = """
        Here is the content:

        \(sections.baseContent)

        Task: \(translationPrompt.replacingOccurrences(of: "{language}", with: targetLanguage))
        """

        let translation = await aiEngine.llmService.generate(
            prompt: prompt,
            maxTokens: 800,
            temperature: 0.3,
            stopSequences: ["---", "###", "\n\n\n", "English"]
        )

        await MainActor.run {
            if let translation = translation, !translation.isEmpty {
                print("✅ Translation generated: \(translation.prefix(100))...")

                let translationBlock = "\n\n--- Translation to \(targetLanguage) ---\n\n" + translation
                note.content = reconstructContent(
                    base: sections.baseContent,
                    summary: sections.summaryBlock,
                    translation: translationBlock,
                    autoCorrect: sections.autoCorrectedBlock,
                    reformulated: sections.reformulatedBlock
                )

                self.saveNote(note)
            } else {
                print("❌ Translation generation returned nil or empty")
            }
            self.isTranslating = false
        }
    }

    func autoCorrect(for note: Note) async {
        guard aiEngine.isModelLoaded else {
            print("⚠️ Cannot patch: Model not loaded")
            return
        }
        guard let originalContent = note.content, !originalContent.isEmpty else {
            print("⚠️ Cannot patch: Content is empty")
            return
        }

        print("🔄 Starting patching for content: \(originalContent.prefix(100))...")

        let sections = extractContentSections(from: originalContent)

        let contentToCorrect = sections.baseContent

        await MainActor.run {
            self.isAutoCorrecting = true
        }

        let prompt = """
        Here is the content:

        \(contentToCorrect)

        Task: \(autoCorrectPrompt)
        """

        let correctedText = await aiEngine.llmService.generate(
            prompt: prompt,
            maxTokens: 800,
            temperature: 0.05,
            stopSequences: ["---", "###", "\n\n\n\n"]
        )

        await MainActor.run {
            if let correctedText = correctedText, !correctedText.isEmpty {
                print("✅ Patching completed: \(correctedText.prefix(100))...")

                let correctionBlock = "\n\n--- Patched ---\n\n" + correctedText
                note.content = reconstructContent(
                    base: sections.baseContent,
                    summary: sections.summaryBlock,
                    translation: sections.translationBlock,
                    autoCorrect: correctionBlock,
                    reformulated: sections.reformulatedBlock
                )

                self.saveNote(note)
            } else {
                print("❌ Patching returned nil or empty")
            }
            self.isAutoCorrecting = false
        }
    }

    func reformulate(for note: Note) async {
        guard aiEngine.isModelLoaded else {
            print("⚠️ Cannot reformulate: Model not loaded")
            return
        }
        guard let originalContent = note.content, !originalContent.isEmpty else {
            print("⚠️ Cannot reformulate: Content is empty")
            return
        }

        print("🔄 Starting reformulation for content: \(originalContent.prefix(100))...")

        let sections = extractContentSections(from: originalContent)

        let contentToReformulate = sections.baseContent

        await MainActor.run {
            self.isReformulating = true
        }

        let prompt = """
        Here is the content:

        \(contentToReformulate)

        Task: \(reformulatePrompt)
        """

        let reformulatedText = await aiEngine.llmService.generate(
            prompt: prompt,
            maxTokens: 800,
            temperature: 0.4,
            stopSequences: ["---", "###", "\n\n\n"]
        )

        await MainActor.run {
            if let reformulatedText = reformulatedText, !reformulatedText.isEmpty {
                print("✅ Reformulation completed: \(reformulatedText.prefix(100))...")

                let reformulationBlock = "\n\n--- Reformulated ---\n\n" + reformulatedText
                note.content = reconstructContent(
                    base: sections.baseContent,
                    summary: sections.summaryBlock,
                    translation: sections.translationBlock,
                    autoCorrect: sections.autoCorrectedBlock,
                    reformulated: reformulationBlock
                )

                self.saveNote(note)
            } else {
                print("❌ Reformulation returned nil or empty")
            }
            self.isReformulating = false
        }
    }

    func resetPromptsToDefaults() {
        autocompletePrompt = DefaultPrompts.autocomplete
        summarizationPrompt = DefaultPrompts.summarization
        translationPrompt = DefaultPrompts.translation
        titleGenerationPrompt = DefaultPrompts.titleGeneration
        autoCorrectPrompt = DefaultPrompts.autoCorrect
        reformulatePrompt = DefaultPrompts.reformulate
        targetLanguage = "Spanish"
    }

    func generateTitle(for note: Note) async {
        guard aiEngine.isModelLoaded else {
            print("⚠️ Cannot generate title: Model not loaded")
            return
        }
        guard let originalContent = note.content, !originalContent.isEmpty else {
            print("⚠️ Cannot generate title: Content is empty")
            return
        }

        print("🔄 Starting title generation for content: \(originalContent.prefix(100))...")

        let sections = extractContentSections(from: originalContent)
        let contentForTitle = String(sections.baseContent.prefix(300))

        await MainActor.run {
            self.isGeneratingTitle = true
        }

        let prompt = """
        Here is the content:

        \(contentForTitle)

        Task: \(titleGenerationPrompt)
        """

        let generatedTitle = await aiEngine.llmService.generate(
            prompt: prompt,
            maxTokens: 15,
            temperature: 0.3,
            stopSequences: ["\n", ".", "---", "###"]
        )

        await MainActor.run {
            if let generatedTitle = generatedTitle, !generatedTitle.isEmpty {
                if !generatedTitle.isEmpty {
                    print("✅ Title generated: \(generatedTitle)")
                    note.title = generatedTitle
                    self.saveNote(note)
                } else {
                    let fallbackTitle = self.extractFallbackTitle(from: sections.baseContent)
                    print("⚠️ Using fallback title: \(fallbackTitle)")
                    note.title = fallbackTitle
                    self.saveNote(note)
                }
            } else {
                let fallbackTitle = self.extractFallbackTitle(from: sections.baseContent)
                print("⚠️ Title generation failed, using fallback: \(fallbackTitle)")
                note.title = fallbackTitle
                self.saveNote(note)
            }
            self.isGeneratingTitle = false
        }
    }

    func reindex(note: Note) async {
        await searchEngine.reindexNote(note)
    }

    private func extractFallbackTitle(from content: String) -> String {
        let words = content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")
            .prefix(5)
            .map(String.init)

        return words.isEmpty ? "Untitled Note" : words.joined(separator: " ")
    }

    private struct ContentSections {
        var baseContent: String
        var summaryBlock: String
        var translationBlock: String
        var autoCorrectedBlock: String
        var reformulatedBlock: String
    }

    private func extractContentSections(from content: String) -> ContentSections {
        var baseContent = content
        var summaryBlock = ""
        var translationBlock = ""
        var autoCorrectedBlock = ""
        var reformulatedBlock = ""

        let markers = [
            "\n\n--- Summary ---",
            "\n\n--- Translation to ",
            "\n\n--- Patched ---",
            "\n\n--- Reformulated ---"
        ]

        var firstAIIndex: String.Index? = nil

        for marker in markers {
            if let range = content.range(of: marker) {
                if firstAIIndex == nil || range.lowerBound < firstAIIndex! {
                    firstAIIndex = range.lowerBound
                }
            }
        }

        if let firstIndex = firstAIIndex {
            baseContent = String(content[..<firstIndex])
            let aiSections = String(content[firstIndex...])

            if let summaryStart = aiSections.range(of: "\n\n--- Summary ---") {
                let summaryContent = String(aiSections[summaryStart.lowerBound...])
                var summaryEnd = summaryContent.endIndex

                for marker in ["\n\n--- Translation to ", "\n\n--- Patched ---", "\n\n--- Reformulated ---"] {
                    if let nextRange = summaryContent.range(of: marker) {
                        if nextRange.lowerBound < summaryEnd {
                            summaryEnd = nextRange.lowerBound
                        }
                    }
                }
                summaryBlock = String(summaryContent[..<summaryEnd])
            }

            if let translationStart = aiSections.range(of: "\n\n--- Translation to ") {
                let translationContent = String(aiSections[translationStart.lowerBound...])
                var translationEnd = translationContent.endIndex

                for marker in ["\n\n--- Summary ---", "\n\n--- Patched ---", "\n\n--- Reformulated ---"] {
                    if let nextRange = translationContent.range(of: marker) {
                        if nextRange.lowerBound < translationEnd {
                            translationEnd = nextRange.lowerBound
                        }
                    }
                }
                translationBlock = String(translationContent[..<translationEnd])
            }

            if let autoCorrectedStart = aiSections.range(of: "\n\n--- Patched ---") {
                let autoCorrectedContent = String(aiSections[autoCorrectedStart.lowerBound...])
                var autoCorrectedEnd = autoCorrectedContent.endIndex

                for marker in ["\n\n--- Summary ---", "\n\n--- Translation to ", "\n\n--- Reformulated ---"] {
                    if let nextRange = autoCorrectedContent.range(of: marker) {
                        if nextRange.lowerBound < autoCorrectedEnd {
                            autoCorrectedEnd = nextRange.lowerBound
                        }
                    }
                }
                autoCorrectedBlock = String(autoCorrectedContent[..<autoCorrectedEnd])
            }

            if let reformulatedStart = aiSections.range(of: "\n\n--- Reformulated ---") {
                let reformulatedContent = String(aiSections[reformulatedStart.lowerBound...])
                var reformulatedEnd = reformulatedContent.endIndex

                for marker in ["\n\n--- Summary ---", "\n\n--- Translation to ", "\n\n--- Patched ---"] {
                    if let nextRange = reformulatedContent.range(of: marker) {
                        if nextRange.lowerBound < reformulatedEnd {
                            reformulatedEnd = nextRange.lowerBound
                        }
                    }
                }
                reformulatedBlock = String(reformulatedContent[..<reformulatedEnd])
            }
        }

        return ContentSections(
            baseContent: baseContent,
            summaryBlock: summaryBlock,
            translationBlock: translationBlock,
            autoCorrectedBlock: autoCorrectedBlock,
            reformulatedBlock: reformulatedBlock
        )
    }

    private func reconstructContent(base: String, summary: String, translation: String, autoCorrect: String = "", reformulated: String = "") -> String {
        return base + autoCorrect + reformulated + summary + translation
    }

    var displayItems: [NoteListItem] {
        if !searchQuery.isEmpty {
            return searchItemResults
        }
        return noteListItems
    }

    var hasNotes: Bool {
        return !noteListItems.isEmpty
    }

    func note(for id: UUID) -> Note? {
        noteCache[id]
    }

    private func upsertListItem(_ item: NoteListItem) {
        if let index = noteListItems.firstIndex(where: { $0.id == item.id }) {
            noteListItems[index] = item
        } else {
            noteListItems.append(item)
        }
        noteListItems.sort(by: { $0.createdAt > $1.createdAt })
    }

    private func updateSearchItemIfNeeded(_ item: NoteListItem) {
        guard let index = searchItemResults.firstIndex(where: { $0.id == item.id }) else { return }
        searchItemResults[index] = item
    }

    private func updateSelectedNote() {
        if let selectedID = selectedNoteID, let note = noteCache[selectedID] {
            selectedNote = note
        } else {
            selectedNote = nil
        }
    }
}
