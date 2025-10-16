//
//  NoteViewModel.swift
//  NoteTaker
//
//  ViewModel coordinating note operations and AI features
//

import Foundation
import CoreData
import Combine
import SwiftUI

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
    @Published var isExecutingCustomService = false
    @Published var executingCustomServiceId: UUID? = nil

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

    /// Generate a friendly timestamp for AI tool outputs
    /// Format: "Jan 15, 3:45 PM"
    private func generateTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: Date())
    }

    func requestAutocomplete(for text: String) {
        guard isAutocompleteEnabled else {
            autocompleteSuggestion = nil
            return
        }

        // Immediately clear old suggestion when new request comes in
        autocompleteSuggestion = nil

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

        // Use the AutocompleteService directly instead of duplicating logic
        let suggestion = await aiEngine.autocompleteService.generateSuggestion(for: text)

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

    func acceptPartialAutocomplete(_ acceptedPart: String) {
        guard let currentSuggestion = autocompleteSuggestion else { return }

        // Remove the accepted part from the suggestion
        let remaining = String(currentSuggestion.dropFirst(acceptedPart.count))

        // Update suggestion with remaining text, or clear if nothing left
        if remaining.isEmpty {
            autocompleteSuggestion = nil
        } else {
            autocompleteSuggestion = remaining
        }
    }

    func dismissAutocomplete() {
        autocompleteSuggestion = nil
    }

    func generateSummary(for note: Note) async {
        guard let content = note.content, !content.isEmpty else { return }

        let sections = extractContentSections(from: content)

        await MainActor.run {
            self.isGeneratingSummary = true
        }

        // Use custom prompt if provided, otherwise use service default
        let summary: String?
        if !summarizationPrompt.isEmpty {
            summary = await aiEngine.summarizationService.process(sections.baseContent, customPrompt: summarizationPrompt)
        } else {
            summary = await aiEngine.summarizationService.summarize(sections.baseContent)
        }

        if let summary = summary {
            await MainActor.run {
                let timestamp = self.generateTimestamp()
                let summaryBlock = "\n\n--- Summary (\(timestamp)) ---\n\n" + summary
                note.content = reconstructContent(
                    base: sections.baseContent,
                    summary: summaryBlock,
                    translation: sections.translationBlock,
                    autoCorrect: sections.autoCorrectedBlock,
                    reformulated: sections.reformulatedBlock,
                    customServices: sections.customServiceBlocks
                )
                self.saveNote(note)
                self.isGeneratingSummary = false
            }
        } else {
            await MainActor.run {
                self.isGeneratingSummary = false
            }
        }
    }

    func indexAllNotes() async {
        await searchEngine.indexAllNotes()
    }

    func generateTranslation(for note: Note) async {
        guard let content = note.content, !content.isEmpty else { return }

        let sections = extractContentSections(from: content)

        await MainActor.run {
            self.isTranslating = true
        }

        // Set target language and translate using custom prompt
        aiEngine.translationService.setTargetLanguage(targetLanguage)

        // Use custom prompt if provided, otherwise use default
        let translation: String?
        if !translationPrompt.isEmpty {
            translation = await aiEngine.translationService.translate(sections.baseContent, withPrompt: translationPrompt)
        } else {
            translation = await aiEngine.translationService.translate(sections.baseContent)
        }

        if let translation = translation {
            await MainActor.run {
                let timestamp = self.generateTimestamp()
                let translationBlock = "\n\n--- Translation to \(targetLanguage) (\(timestamp)) ---\n\n" + translation
                note.content = reconstructContent(
                    base: sections.baseContent,
                    summary: sections.summaryBlock,
                    translation: translationBlock,
                    autoCorrect: sections.autoCorrectedBlock,
                    reformulated: sections.reformulatedBlock,
                    customServices: sections.customServiceBlocks
                )
                self.saveNote(note)
                self.isTranslating = false
            }
        } else {
            await MainActor.run {
                self.isTranslating = false
            }
        }
    }

    func autoCorrect(for note: Note) async {
        guard let content = note.content, !content.isEmpty else { return }

        let sections = extractContentSections(from: content)

        await MainActor.run {
            self.isAutoCorrecting = true
        }

        // Use custom prompt if provided, otherwise use service default
        let corrected: String?
        if !autoCorrectPrompt.isEmpty {
            corrected = await aiEngine.autoCorrectService.process(sections.baseContent, customPrompt: autoCorrectPrompt)
        } else {
            corrected = await aiEngine.autoCorrectService.correct(sections.baseContent)
        }

        if let corrected = corrected {
            await MainActor.run {
                let timestamp = self.generateTimestamp()
                let correctedBlock = "\n\n--- Patched (\(timestamp)) ---\n\n" + corrected
                note.content = reconstructContent(
                    base: sections.baseContent,
                    summary: sections.summaryBlock,
                    translation: sections.translationBlock,
                    autoCorrect: correctedBlock,
                    reformulated: sections.reformulatedBlock,
                    customServices: sections.customServiceBlocks
                )
                self.saveNote(note)
                self.isAutoCorrecting = false
            }
        } else {
            await MainActor.run {
                self.isAutoCorrecting = false
            }
        }
    }

    func reformulate(for note: Note) async {
        guard let content = note.content, !content.isEmpty else { return }

        let sections = extractContentSections(from: content)

        await MainActor.run {
            self.isReformulating = true
        }

        // Use custom prompt if provided, otherwise use service default
        let reformulated: String?
        if !reformulatePrompt.isEmpty {
            reformulated = await aiEngine.reformulationService.process(sections.baseContent, customPrompt: reformulatePrompt)
        } else {
            reformulated = await aiEngine.reformulationService.reformulate(sections.baseContent)
        }

        if let reformulated = reformulated {
            await MainActor.run {
                let timestamp = self.generateTimestamp()
                let reformulatedBlock = "\n\n--- Reformulated (\(timestamp)) ---\n\n" + reformulated
                note.content = reconstructContent(
                    base: sections.baseContent,
                    summary: sections.summaryBlock,
                    translation: sections.translationBlock,
                    autoCorrect: sections.autoCorrectedBlock,
                    reformulated: reformulatedBlock,
                    customServices: sections.customServiceBlocks
                )
                self.saveNote(note)
                self.isReformulating = false
            }
        } else {
            await MainActor.run {
                self.isReformulating = false
            }
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
        guard let content = note.content, !content.isEmpty else { return }

        let sections = extractContentSections(from: content)

        await MainActor.run {
            self.isGeneratingTitle = true
        }

        // Use custom prompt if provided, otherwise use service default
        let title: String
        if !titleGenerationPrompt.isEmpty {
            title = await aiEngine.titleGenerationService.generateTitleWithFallback(for: sections.baseContent, customPrompt: titleGenerationPrompt)
        } else {
            title = await aiEngine.titleGenerationService.generateTitleWithFallback(for: sections.baseContent)
        }

        await MainActor.run {
            note.title = title
            self.saveNote(note)
            self.isGeneratingTitle = false
        }
    }

    func reindex(note: Note) async {
        await searchEngine.reindexNote(note)
    }

    /// Execute a custom service on a note
    func executeCustomService(_ service: CustomService, for note: Note) async {
        guard let content = note.content, !content.isEmpty else { return }

        let sections = extractContentSections(from: content)

        await MainActor.run {
            self.isExecutingCustomService = true
            self.executingCustomServiceId = service.id
        }

        // Format prompt like other services: instruction + content + trigger
        // The custom prompt is the instruction, followed by the content to process
        let prompt = "\(service.prompt)\n\n\(sections.baseContent)\n\nResult:"

        // Calculate dynamic max tokens based on input length (with buffer for potential expansion)
        let estimatedInputTokens = sections.baseContent.count / 4 // Rough estimate: 1 token ≈ 4 chars
        let maxTokens = min(max(estimatedInputTokens + 200, 300), 1024) // At least 300, at most 1024

        let result = await aiEngine.llmService.generate(
            prompt: prompt,
            maxTokens: maxTokens,
            temperature: 0.7
        )

        if let result = result, !result.isEmpty {
            // Post-process the result to remove common unwanted prefixes/suffixes
            let cleanedResult = cleanCustomServiceOutput(result)

            if !cleanedResult.isEmpty {
                await MainActor.run {
                    let timestamp = self.generateTimestamp()
                    let resultBlock = "\n\n--- \(service.name) (\(timestamp)) ---\n\n" + cleanedResult

                    // Update custom service blocks, replacing existing block for this service
                    var updatedCustomServices = sections.customServiceBlocks
                    updatedCustomServices[service.name] = resultBlock

                    // Reconstruct content with updated custom service block
                    note.content = reconstructContent(
                        base: sections.baseContent,
                        summary: sections.summaryBlock,
                        translation: sections.translationBlock,
                        autoCorrect: sections.autoCorrectedBlock,
                        reformulated: sections.reformulatedBlock,
                        customServices: updatedCustomServices
                    )
                    self.saveNote(note)
                    self.isExecutingCustomService = false
                    self.executingCustomServiceId = nil
                }
            } else {
                await MainActor.run {
                    self.isExecutingCustomService = false
                    self.executingCustomServiceId = nil
                }
            }
        } else {
            await MainActor.run {
                self.isExecutingCustomService = false
                self.executingCustomServiceId = nil
            }
        }
    }

    // MARK: - Custom Service Post-processing

    private func cleanCustomServiceOutput(_ output: String) -> String {
        var cleaned = output.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove common unwanted prefixes
        let prefixes = [
            "Result:",
            "Here is the result:",
            "The result is:",
            "Output:",
            "Here is:",
            "Here's the",
            "Here's",
            "result:"
        ]

        for prefix in prefixes {
            if cleaned.lowercased().hasPrefix(prefix.lowercased()) {
                cleaned = String(cleaned.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // Stop at common ending markers
        let stopMarkers = [
            "\n\nNote:",
            "\n\nThe ",
            "\n\nHere is",
            "\n\n---"
        ]

        for marker in stopMarkers {
            if let range = cleaned.range(of: marker) {
                cleaned = String(cleaned[..<range.lowerBound])
            }
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }


    private struct ContentSections {
        var baseContent: String
        var summaryBlock: String
        var translationBlock: String
        var autoCorrectedBlock: String
        var reformulatedBlock: String
        var customServiceBlocks: [String: String] = [:] // Service name -> block content
    }

    private func extractContentSections(from content: String) -> ContentSections {
        var baseContent = content
        var summaryBlock = ""
        var translationBlock = ""
        var autoCorrectedBlock = ""
        var reformulatedBlock = ""
        var customServiceBlocks: [String: String] = [:]

        // Find the first AI-generated section marker
        let markerPrefix = "\n\n--- "
        var firstAIIndex: String.Index? = nil

        if let range = content.range(of: markerPrefix) {
            firstAIIndex = range.lowerBound
        }

        if let firstIndex = firstAIIndex {
            baseContent = String(content[..<firstIndex])
            let aiSections = String(content[firstIndex...])

            // Split by section markers
            let sectionPattern = "\n\n--- "
            let parts = aiSections.components(separatedBy: sectionPattern)

            for (index, part) in parts.enumerated() {
                if index == 0 && part.isEmpty { continue } // Skip empty first part

                // Extract section name from the header line
                let lines = part.components(separatedBy: "\n")
                guard let headerLine = lines.first else { continue }

                // Reconstruct the full block with marker
                let fullBlock = (index > 0 || !part.isEmpty) ? sectionPattern + part : part

                // Categorize the block by its header
                if headerLine.hasPrefix("Summary") {
                    summaryBlock = fullBlock
                } else if headerLine.hasPrefix("Translation to ") {
                    translationBlock = fullBlock
                } else if headerLine.hasPrefix("Patched") {
                    autoCorrectedBlock = fullBlock
                } else if headerLine.hasPrefix("Reformulated") {
                    reformulatedBlock = fullBlock
                } else {
                    // This is a custom service block
                    // Extract service name from "ServiceName (timestamp) ---"
                    if let nameEnd = headerLine.range(of: " (") {
                        let serviceName = String(headerLine[..<nameEnd.lowerBound])
                        customServiceBlocks[serviceName] = fullBlock
                    }
                }
            }
        }

        return ContentSections(
            baseContent: baseContent,
            summaryBlock: summaryBlock,
            translationBlock: translationBlock,
            autoCorrectedBlock: autoCorrectedBlock,
            reformulatedBlock: reformulatedBlock,
            customServiceBlocks: customServiceBlocks
        )
    }

    private func reconstructContent(base: String, summary: String, translation: String, autoCorrect: String = "", reformulated: String = "", customServices: [String: String] = [:]) -> String {
        var result = base + autoCorrect + reformulated + summary + translation

        // Append custom service blocks in a consistent order (alphabetically by service name)
        let sortedServiceNames = customServices.keys.sorted()
        for serviceName in sortedServiceNames {
            if let block = customServices[serviceName] {
                result += block
            }
        }

        return result
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
