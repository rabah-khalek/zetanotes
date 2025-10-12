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
    @Published var isTranslating = false
    @Published var isGeneratingTitle = false
    @Published var isAutoCorrecting = false
    @Published var isReformulating = false
    @Published var isAutocompleteEnabled = true

    // AI Prompt Customization
    @Published var autocompletePrompt = "Continue this text naturally:"
    @Published var summarizationPrompt = "Summarize this text in one clear sentence:"
    @Published var translationPrompt = "Translate this text to {language}. Only output the translation:"
    @Published var titleGenerationPrompt = "Generate a short, concise title for this text (5 words max):"
    @Published var autoCorrectPrompt = "Copy this text EXACTLY. Only fix obvious spelling mistakes. Do NOT change any words. Do NOT rephrase."
    @Published var reformulatePrompt = "Reformulate this text to make it clearer and more professional. Keep the same meaning:"
    @Published var targetLanguage = "Spanish"

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

        // Reload all notes from Core Data to ensure single source of truth
        loadNotes()

        // Select the newly created note
        selectedNote = newNote
        print("✅ Note created: \(newNote.id?.uuidString ?? "unknown")")
    }

    func deleteNote(_ note: Note) {
        let deletedNoteId = note.id
        persistenceController.deleteNote(note)

        // Reload all notes from Core Data to ensure single source of truth
        loadNotes()

        // Select first note if the deleted note was selected
        if selectedNote?.id == deletedNoteId {
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

        // Force UI update by triggering objectWillChange
        objectWillChange.send()

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
        // Don't generate if autocomplete is disabled
        guard isAutocompleteEnabled else {
            autocompleteSuggestion = nil
            return
        }

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
        guard aiEngine.isModelLoaded else {
            print("⚠️ Cannot summarize: Model not loaded")
            return
        }
        guard let originalContent = note.content, !originalContent.isEmpty else {
            print("⚠️ Cannot summarize: Content is empty")
            return
        }

        print("🔄 Starting summarization for content: \(originalContent.prefix(100))...")

        // Extract content sections
        let sections = extractContentSections(from: originalContent)

        await MainActor.run {
            self.isGeneratingSummary = true
        }

        // Use the SummarizationService for better fallback handling
        let summary = await aiEngine.summarize(sections.baseContent, maxLength: 200)

        await MainActor.run {
            if let summary = summary, !summary.isEmpty {
                print("✅ Summary generated: \(summary)")

                // Reconstruct note content with updated summary block
                let summaryBlock = "\n\n--- Summary ---\n\n" + summary
                note.content = reconstructContent(
                    base: sections.baseContent,
                    summary: summaryBlock,
                    translation: sections.translationBlock,
                    autoCorrect: sections.autoCorrectedBlock,
                    reformulated: sections.reformulatedBlock
                )

                self.persistenceController.save()
            } else {
                print("❌ Summary generation returned nil or empty")
            }
            self.isGeneratingSummary = false
        }
    }

    /// Generates embeddings for all notes (background operation)
    func indexAllNotes() async {
        await searchEngine.indexAllNotes()
    }

    /// Generates a translation for the given note
    func generateTranslation(for note: Note) async {
        guard aiEngine.isModelLoaded else { return }
        guard let originalContent = note.content, !originalContent.isEmpty else { return }

        print("🔄 Starting translation to \(targetLanguage) for content: \(originalContent.prefix(100))...")

        // Extract content sections
        let sections = extractContentSections(from: originalContent)

        await MainActor.run {
            self.isTranslating = true
        }

        // Build a more explicit translation prompt with language name repetition
        let prompt = """
        Translate the following text from English to \(targetLanguage). Provide only the \(targetLanguage) translation:

        \(sections.baseContent)

        \(targetLanguage) translation:
        """

        // Generate translation with more tokens and lower temperature for accuracy
        let translation = await aiEngine.llmService.generate(
            prompt: prompt,
            maxTokens: 800,
            temperature: 0.3,
            stopSequences: ["---", "###", "\n\n\n", "English"]
        )

        await MainActor.run {
            if let translation = translation, !translation.isEmpty {
                // Clean up the translation
                let cleanedTranslation = translation
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "Translation:", with: "")
                    .replacingOccurrences(of: "\(targetLanguage) translation:", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                print("✅ Translation generated: \(cleanedTranslation.prefix(100))...")

                // Reconstruct note content with updated translation block
                let translationBlock = "\n\n--- Translation to \(targetLanguage) ---\n\n" + cleanedTranslation
                note.content = reconstructContent(
                    base: sections.baseContent,
                    summary: sections.summaryBlock,
                    translation: translationBlock,
                    autoCorrect: sections.autoCorrectedBlock,
                    reformulated: sections.reformulatedBlock
                )

                self.persistenceController.save()
            } else {
                print("❌ Translation generation returned nil or empty")
            }
            self.isTranslating = false
        }
    }

    // MARK: - AI Generation Helpers

    /// Common structure for extracting content sections from a note
    private struct ContentSections {
        var baseContent: String
        var summaryBlock: String
        var translationBlock: String
        var autoCorrectedBlock: String
        var reformulatedBlock: String
    }

    /// Extracts and separates the different sections of note content
    private func extractContentSections(from content: String) -> ContentSections {
        var baseContent = content
        var summaryBlock = ""
        var translationBlock = ""
        var autoCorrectedBlock = ""
        var reformulatedBlock = ""

        // Define all AI-generated section markers
        let markers = [
            "\n\n--- Summary ---",
            "\n\n--- Translation to ",
            "\n\n--- Patched ---",
            "\n\n--- Reformulated ---"
        ]

        // Find the earliest AI section to determine where base content ends
        var firstAIIndex: String.Index? = nil

        for marker in markers {
            if let range = content.range(of: marker) {
                if firstAIIndex == nil || range.lowerBound < firstAIIndex! {
                    firstAIIndex = range.lowerBound
                }
            }
        }

        // Extract base content (everything before first AI section)
        if let firstIndex = firstAIIndex {
            baseContent = String(content[..<firstIndex])
            let aiSections = String(content[firstIndex...])

            // Extract each block individually
            if let summaryStart = aiSections.range(of: "\n\n--- Summary ---") {
                let summaryContent = String(aiSections[summaryStart.lowerBound...])
                // Find where summary block ends (next marker or end)
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

    /// Reconstructs note content from sections
    private func reconstructContent(base: String, summary: String, translation: String, autoCorrect: String = "", reformulated: String = "") -> String {
        return base + autoCorrect + reformulated + summary + translation
    }

    /// Generates a title for the given note based on its content
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

        // Extract only the base content for title generation
        let sections = extractContentSections(from: originalContent)
        let contentForTitle = String(sections.baseContent.prefix(300)) // Use first 300 chars for title

        await MainActor.run {
            self.isGeneratingTitle = true
        }

        // Build a clearer, more direct title generation prompt
        let prompt = """
        Create a short title (maximum 5 words) for this text:

        \(contentForTitle)

        Title:
        """

        // Generate title with limited tokens and low temperature
        let generatedTitle = await aiEngine.llmService.generate(
            prompt: prompt,
            maxTokens: 15,
            temperature: 0.3,
            stopSequences: ["\n", ".", "---", "###"]
        )

        await MainActor.run {
            if let generatedTitle = generatedTitle, !generatedTitle.isEmpty {
                // Clean up the title
                var cleanedTitle = generatedTitle
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "Title:", with: "")
                    .replacingOccurrences(of: "\"", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                // Limit to first 5 words if longer
                let words = cleanedTitle.split(separator: " ")
                if words.count > 5 {
                    cleanedTitle = words.prefix(5).joined(separator: " ")
                }

                if !cleanedTitle.isEmpty {
                    print("✅ Title generated: \(cleanedTitle)")
                    note.title = cleanedTitle
                    self.persistenceController.save()
                } else {
                    // Fallback: use first few words from content
                    let fallbackTitle = extractFallbackTitle(from: sections.baseContent)
                    print("⚠️ Using fallback title: \(fallbackTitle)")
                    note.title = fallbackTitle
                    self.persistenceController.save()
                }
            } else {
                // Fallback: use first few words from content
                let fallbackTitle = extractFallbackTitle(from: sections.baseContent)
                print("⚠️ Title generation failed, using fallback: \(fallbackTitle)")
                note.title = fallbackTitle
                self.persistenceController.save()
            }
            self.isGeneratingTitle = false
        }
    }

    /// Extracts a fallback title from content (first 5 words)
    private func extractFallbackTitle(from content: String) -> String {
        let words = content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")
            .prefix(5)
            .map(String.init)

        return words.isEmpty ? "Untitled Note" : words.joined(separator: " ")
    }

    /// Patchs grammar and spelling in the note content
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

        // Extract content sections
        let sections = extractContentSections(from: originalContent)

        // Limit content size to prevent batch size overflow (approx 1500 chars = ~400 tokens)
        let maxChars = 1500
        let contentToCorrect = String(sections.baseContent.prefix(maxChars))
        let wasTruncated = sections.baseContent.count > maxChars

        if wasTruncated {
            print("⚠️ Content truncated to \(maxChars) chars to fit model batch size")
        }

        await MainActor.run {
            self.isAutoCorrecting = true
        }

        // Build a very explicit prompt - copy the text exactly, fix only obvious typos
        let prompt = """
        Copy this text EXACTLY. Only fix obvious spelling mistakes. Do NOT change any words. Do NOT rephrase. Copy word-for-word:

        \(contentToCorrect)

        Corrected version (copy exactly, fix only spelling):
        """

        // Generate corrected text with extremely low temperature
        let correctedText = await aiEngine.llmService.generate(
            prompt: prompt,
            maxTokens: 800,
            temperature: 0.05,  // Extremely low temperature for minimal changes
            stopSequences: ["---", "###", "\n\n\n\n"]
        )

        await MainActor.run {
            if let correctedText = correctedText, !correctedText.isEmpty {
                // Clean up the corrected text
                var cleanedText = correctedText
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "Corrected text:", with: "")
                    .replacingOccurrences(of: "Fixed text:", with: "")
                    .replacingOccurrences(of: "Fixed text (with only grammar/spelling corrections):", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                // Log the correction
                print("✅ Patching completed: \(cleanedText.prefix(100))...")

                // Update only the patch block, preserve all others
                let correctionBlock = "\n\n--- Patched ---\n\n" + cleanedText
                note.content = reconstructContent(
                    base: sections.baseContent,
                    summary: sections.summaryBlock,
                    translation: sections.translationBlock,
                    autoCorrect: correctionBlock,
                    reformulated: sections.reformulatedBlock
                )

                self.persistenceController.save()
            } else {
                print("❌ Patching returned nil or empty")
            }
            self.isAutoCorrecting = false
        }
    }

    /// Reformulates the note content to make it clearer and more professional
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

        // Extract content sections
        let sections = extractContentSections(from: originalContent)

        // Limit content size to prevent batch size overflow (approx 1500 chars = ~400 tokens)
        let maxChars = 1500
        let contentToReformulate = String(sections.baseContent.prefix(maxChars))
        let wasTruncated = sections.baseContent.count > maxChars

        if wasTruncated {
            print("⚠️ Content truncated to \(maxChars) chars to fit model batch size")
        }

        await MainActor.run {
            self.isReformulating = true
        }

        // Build reformulate prompt
        let prompt = """
        \(reformulatePrompt)

        \(contentToReformulate)

        Reformulated text:
        """

        // Generate reformulated text with moderate token limit and moderate temperature
        let reformulatedText = await aiEngine.llmService.generate(
            prompt: prompt,
            maxTokens: 800,
            temperature: 0.4,
            stopSequences: ["---", "###", "\n\n\n"]
        )

        await MainActor.run {
            if let reformulatedText = reformulatedText, !reformulatedText.isEmpty {
                // Clean up the reformulated text
                let cleanedText = reformulatedText
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "Reformulated text:", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                print("✅ Reformulation completed: \(cleanedText.prefix(100))...")

                // Update only the reformulated block, preserve all others
                let reformulationBlock = "\n\n--- Reformulated ---\n\n" + cleanedText
                note.content = reconstructContent(
                    base: sections.baseContent,
                    summary: sections.summaryBlock,
                    translation: sections.translationBlock,
                    autoCorrect: sections.autoCorrectedBlock,
                    reformulated: reformulationBlock
                )

                self.persistenceController.save()
            } else {
                print("❌ Reformulation returned nil or empty")
            }
            self.isReformulating = false
        }
    }

    /// Resets all prompts to default values
    func resetPromptsToDefaults() {
        autocompletePrompt = "Continue this text naturally:"
        summarizationPrompt = "Summarize this text in one clear sentence:"
        translationPrompt = "Translate this text to {language}. Only output the translation:"
        titleGenerationPrompt = "Generate a short, concise title for this text (5 words max):"
        autoCorrectPrompt = "Copy this text EXACTLY. Only fix obvious spelling mistakes. Do NOT change any words. Do NOT rephrase."
        reformulatePrompt = "Reformulate this text to make it clearer and more professional. Keep the same meaning:"
        targetLanguage = "Spanish"
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
