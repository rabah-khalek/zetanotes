//
//  NoteEditorView.swift
//  ZetaNotes
//
//  Rich text editor with AI autocomplete suggestions
//

import AppKit
import SwiftUI
import MarkdownUI

// MARK: - Custom Text View with Key Handling

class AutocompleteTextView: NSTextView {
    var onTabPressed: (() -> Void)?
    var onEscapePressed: (() -> Void)?
    var onRightArrowPressed: (() -> Void)?
    var ghostText: String? {
        didSet {
            setNeedsDisplay(bounds)
        }
    }

    override func keyDown(with event: NSEvent) {
        // Handle Tab key (keyCode 48) - accept full suggestion
        if event.keyCode == 48 {
            if ghostText != nil, let onTab = onTabPressed {
                onTab()
                return // Don't call super - we handled it
            }
        }
        // Handle Escape key (keyCode 53) - dismiss suggestion
        else if event.keyCode == 53 {
            if ghostText != nil, let onEscape = onEscapePressed {
                onEscape()
                return // Don't call super - we handled it
            }
        }
        // Handle Right Arrow key (keyCode 124) - accept one word
        else if event.keyCode == 124 {
            // Intercept if we have a suggestion (regardless of cursor position)
            if ghostText != nil, let onRightArrow = onRightArrowPressed {
                onRightArrow()
                return // Don't call super - we handled it
            }
        }

        super.keyDown(with: event)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Draw ghost text if available
        guard let ghostText = ghostText, !ghostText.isEmpty else { return }

        // Get cursor position
        let cursorRange = selectedRange()
        guard cursorRange.length == 0 else { return } // Only show if no selection

        // Calculate where to draw ghost text
        guard let layoutManager = layoutManager,
              let textContainer = textContainer else { return }

        let glyphIndex = layoutManager.glyphIndexForCharacter(at: cursorRange.location)
        let glyphRect = layoutManager.boundingRect(
            forGlyphRange: NSRange(location: glyphIndex, length: 0),
            in: textContainer
        )

        // Create attributed string for ghost text
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize),
            .foregroundColor: NSColor.placeholderTextColor.withAlphaComponent(0.5)
        ]

        let attributedGhostText = NSAttributedString(string: ghostText, attributes: attributes)

        // Draw ghost text at cursor position
        let drawPoint = NSPoint(
            x: glyphRect.maxX + textContainerInset.width,
            y: glyphRect.minY + textContainerInset.height
        )

        attributedGhostText.draw(at: drawPoint)
    }
}

// MARK: - Simple Text Editor

/// A clean SwiftUI wrapper for NSTextView with ghost text support
struct SimpleTextEditor: NSViewRepresentable {
    @Binding var text: String
    var ghostText: String?
    var desiredCursorPosition: Int? // New: optional desired cursor position
    var onChange: ((String, Int) -> Void)? // Now includes cursor position
    var onTabPressed: (() -> Void)?
    var onEscapePressed: (() -> Void)?
    var onRightArrowPressed: (() -> Void)?
    var searchQuery: String? // Search query for highlighting
    var semanticMatchText: String? // Matched text for semantic search

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SimpleTextEditor
        var isUpdatingProgrammatically = false
        var lastCursorPosition: Int = 0

        init(_ parent: SimpleTextEditor) {
            self.parent = parent
            super.init()
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }

            // Don't notify onChange if we're updating programmatically
            guard !isUpdatingProgrammatically else { return }

            let currentText = textView.string
            let cursorPosition = textView.selectedRange().location

            DispatchQueue.main.async {
                self.parent.text = currentText
                self.parent.onChange?(currentText, cursorPosition)
            }

            lastCursorPosition = cursorPosition
        }

        // Detect cursor position changes (clicking, arrow keys, etc.)
        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }

            // Don't notify if we're updating programmatically
            guard !isUpdatingProgrammatically else { return }

            let cursorPosition = textView.selectedRange().location

            // Only trigger if cursor actually moved (not just selection changes)
            guard cursorPosition != lastCursorPosition else { return }

            lastCursorPosition = cursorPosition
            let currentText = textView.string

            // Trigger autocomplete on cursor position change
            DispatchQueue.main.async {
                self.parent.onChange?(currentText, cursorPosition)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = AutocompleteTextView()

        textView.isRichText = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        textView.delegate = context.coordinator
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.drawsBackground = true
        textView.textColor = NSColor.labelColor
        textView.string = text
        textView.allowsUndo = true
        textView.autoresizingMask = [.width, .height]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: .greatestFiniteMagnitude
        )

        // Set up key handlers
        textView.onTabPressed = onTabPressed
        textView.onEscapePressed = onEscapePressed
        textView.onRightArrowPressed = onRightArrowPressed

        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.backgroundColor = .textBackgroundColor
        scrollView.drawsBackground = true

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? AutocompleteTextView else { return }

        // FIX: Only update text if it differs significantly to reduce layout storms
        if textView.string != text {
            // Set flag to prevent textDidChange from triggering
            context.coordinator.isUpdatingProgrammatically = true

            // FIX: Use replaceCharacters for better performance on large texts
            if let textStorage = textView.textStorage {
                // Bounds check to prevent crashes on concurrent modifications
                let currentLength = textStorage.length
                guard currentLength >= 0 else {
                    // Fallback to direct string assignment if storage is in invalid state
                    textView.string = text
                    context.coordinator.isUpdatingProgrammatically = false
                    return
                }

                let fullRange = NSRange(location: 0, length: currentLength)

                // Create attributed string with proper text color for dark mode
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: textView.font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize),
                    .foregroundColor: NSColor.labelColor
                ]
                let attributedText = NSAttributedString(string: text, attributes: attributes)

                // Use beginEditing/endEditing for atomic updates
                textStorage.beginEditing()
                textStorage.replaceCharacters(in: fullRange, with: attributedText)
                textStorage.endEditing()
            } else {
                textView.string = text
            }

            // Set cursor position if specified (for autocomplete acceptance)
            if let desiredPosition = desiredCursorPosition {
                let newCursorPosition = min(desiredPosition, text.count)
                textView.setSelectedRange(NSRange(location: newCursorPosition, length: 0))
            }

            // Reset flag after update
            context.coordinator.isUpdatingProgrammatically = false
        }

        // Update ghost text only if changed
        if textView.ghostText != ghostText {
            textView.ghostText = ghostText
        }

        // Update key handlers (these are cheap to update)
        textView.onTabPressed = onTabPressed
        textView.onEscapePressed = onEscapePressed
        textView.onRightArrowPressed = onRightArrowPressed

        // FIX: Optimize highlighting updates - only update if search query changed
        let currentMatchText = semanticMatchText ?? ""
        let currentSearchQuery = searchQuery ?? ""

        if !currentMatchText.isEmpty {
            // Semantic result: highlight the matched text
            highlightSearchResults(in: textView, query: currentMatchText)
        } else if !currentSearchQuery.isEmpty {
            // Keyword: highlight search query as you type
            highlightSearchResults(in: textView, query: currentSearchQuery)
        } else {
            // Clear highlighting
            clearHighlighting(in: textView)
        }
    }

    private func highlightSearchResults(in textView: NSTextView, query: String) {
        guard let textStorage = textView.textStorage else { return }

        let text = textStorage.string
        // Bounds check to prevent crashes
        guard text.utf16.count == textStorage.length else {
            print("Text storage length mismatch, skipping highlight")
            return
        }

        let searchRange = NSRange(location: 0, length: textStorage.length)

        // Use atomic editing for thread safety
        textStorage.beginEditing()

        // First, remove any existing background colors
        textStorage.removeAttribute(.backgroundColor, range: searchRange)

        // Find all matches
        let searchOptions: NSString.CompareOptions = .caseInsensitive
        var searchStart = text.startIndex

        while searchStart < text.endIndex,
              let range = text.range(of: query, options: searchOptions, range: searchStart ..< text.endIndex) {
            let nsRange = NSRange(range, in: text)
            // Bounds check before applying attribute
            if nsRange.location >= 0, nsRange.upperBound <= textStorage.length {
                textStorage.addAttribute(
                    .backgroundColor,
                    value: NSColor.systemYellow.withAlphaComponent(0.4),
                    range: nsRange
                )
            }
            searchStart = range.upperBound
        }

        textStorage.endEditing()
    }

    private func clearHighlighting(in textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        let currentLength = textStorage.length
        guard currentLength >= 0 else { return }

        let range = NSRange(location: 0, length: currentLength)
        textStorage.beginEditing()
        textStorage.removeAttribute(.backgroundColor, range: range)
        textStorage.endEditing()
    }
}

// MARK: - Note Editor View

struct NoteEditorView: View {
    @ObservedObject var viewModel: NoteViewModel
    @ObservedObject var aiEngine: AIEngine
    var note: Note

    // Search parameters
    @Binding var searchQuery: String
    var isSearching: Bool
    @Binding var semanticMatchText: String

    @State private var title: String = ""
    @State private var content: String = ""
    @State private var showMarkdownPreview: Bool = false
    @State private var currentCursorPosition: Int = 0
    @State private var desiredCursorPosition: Int?
    @State private var lastContentLength: Int = 0
    @State private var isLoading: Bool = false

    // FIX: Add debounce for expensive operations
    @State private var autocompleteDebounceTimer: Timer?
    private let autocompleteDebounceDelay: TimeInterval = 0.3 // Wait 300ms after last keystroke

    var body: some View {
        VStack(spacing: 0) {
            // Title Field with AI Generate Button and Markdown Toggle
            HStack(spacing: 8) {
                // Generate Title Button with Cmd+G shortcut
                Button(action: {
                    Task {
                        await viewModel.generateTitle(for: note)
                    }
                }) {
                    VStack(spacing: 2) {
                        // Keyboard shortcut badge
                        HStack(spacing: 1) {
                            Text("⌘")
                                .font(.system(size: 7, weight: .medium))
                            Text("G")
                                .font(.system(size: 8, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 2.5)
                                .fill(Color.blue.opacity(0.85))
                        )

                        // Icon
                        if viewModel.isGeneratingTitle {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                    }
                }
                .buttonStyle(.plain)
                .keyboardShortcut("g", modifiers: .command)
                .disabled(content.count < 20 || viewModel.isGeneratingTitle || !aiEngine.isModelLoaded)
                .help("Generate title from content (⌘G)")
                .opacity((content.count < 20 || viewModel.isGeneratingTitle || !aiEngine.isModelLoaded) ? 0.3 : 1.0)

                TextField("Title", text: $title)
                    .font(.system(size: 22, weight: .semibold))
                    .textFieldStyle(.plain)
                    .onChange(of: title) { newValue in
                        guard !isLoading else { return } // Don't save when loading note

                        // Update note on main thread (Core Data objects must stay on their context's thread)
                        note.title = newValue
                        note.touch() // Update timestamp when title changes

                        // Debounced list update (same timing as save to avoid excessive updates)
                        viewModel.updateListItemDebounced(for: note)
                        viewModel.saveNoteDebounced(note)
                    }

                // Markdown Preview Toggle - RIGHT SIDE
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showMarkdownPreview.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: showMarkdownPreview ? "pencil" : "eye")
                            .font(.system(size: 11))
                        Text(showMarkdownPreview ? "Edit" : "Preview")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(showMarkdownPreview ? AppTheme.Colors.accentGreen : AppTheme.Colors.accentBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill((showMarkdownPreview ? AppTheme.Colors.accentGreen : AppTheme.Colors.accentBlue)
                                .opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(
                                        (showMarkdownPreview ? AppTheme.Colors.accentGreen : AppTheme.Colors.accentBlue)
                                            .opacity(0.2),
                                        lineWidth: 0.5
                                    )
                            )
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showMarkdownPreview)
                }
                .buttonStyle(.plain)
                .help(showMarkdownPreview ? "Switch to edit mode" : "Preview Markdown formatting")
            }
            .padding(.horizontal, 24)
            .padding(
                .top,
                isSearching ? AppTheme.Spacing.noteTitleTopPaddingWhileSearching : AppTheme.Spacing.noteTitleTopPadding
            ) // Extra space when search bar is showing
            .padding(.bottom, AppTheme.Spacing.noteTitleBottomPadding)

            // Content Editor or Markdown Preview
            if showMarkdownPreview {
                ZStack {
                    Color(nsColor: .textBackgroundColor)
                        .ignoresSafeArea()

                    ScrollView {
                        Markdown(content)
                            .markdownTheme(.docC)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                }
                .frame(minHeight: 200)
                .transition(.opacity)
            } else {
                SimpleTextEditor(
                    text: $content,
                    ghostText: viewModel.autocompleteSuggestion,
                    desiredCursorPosition: desiredCursorPosition,
                    onChange: { newValue, cursorPosition in
                        // Track cursor position
                        currentCursorPosition = cursorPosition

                        // Clear desired cursor position once it's been applied
                        desiredCursorPosition = nil

                        // Detect large text changes (paste operations)
                        let textLengthChange = abs(newValue.count - lastContentLength)
                        let isPasteOperation = textLengthChange > 50 // More than 50 chars changed at once
                        lastContentLength = newValue.count

                        // Update content and note on main thread (Core Data thread safety)
                        content = newValue
                        note.content = newValue
                        note.touch() // Update timestamp

                        // Debounced list update (same timing as save to avoid excessive updates)
                        viewModel.updateListItemDebounced(for: note)

                        // Debounced save to disk (reduces I/O during typing)
                        viewModel.saveNoteDebounced(note)

                        // Disable autocomplete on paste to prevent crashes
                        if isPasteOperation {
                            viewModel.dismissAutocomplete()
                            return
                        }

                        // FIX: Throttle autocomplete checks to reduce string operations
                        guard !newValue.isEmpty else {
                            viewModel.dismissAutocomplete()
                            return
                        }

                        // FIX: Debounce autocomplete to reduce CPU usage
                        // Cancel any pending autocomplete request
                        autocompleteDebounceTimer?.invalidate()

                        // Schedule new autocomplete check after delay
                        autocompleteDebounceTimer = Timer.scheduledTimer(
                            withTimeInterval: autocompleteDebounceDelay,
                            repeats: false
                        ) { [weak viewModel] _ in
                            // FIX: Dispatch to main actor for main-actor isolated calls
                            DispatchQueue.main.async {
                                guard let viewModel = viewModel else { return }

                                // Check if cursor is in base content (not in AI-generated sections)
                                // FIX: Use cached check result to avoid expensive string operations
                                let isBaseContent = isInBaseContent(content: newValue, cursorPosition: cursorPosition)

                                if isBaseContent {
                                    // Smart triggering: only suggest at natural pause points
                                    if shouldTriggerAutocomplete(text: newValue, cursorPosition: cursorPosition) {
                                        // Request autocomplete only if model is loaded
                                        if aiEngine.isModelLoaded, newValue.count >= 10 {
                                            // FIX: Extract text more efficiently
                                            let safePosition = min(cursorPosition, newValue.count)
                                            let textUpToCursor = String(newValue.prefix(safePosition))
                                            viewModel.requestAutocomplete(for: textUpToCursor)
                                        } else {
                                            viewModel.dismissAutocomplete()
                                        }
                                    } else {
                                        viewModel.dismissAutocomplete()
                                    }
                                } else {
                                    // Dismiss autocomplete when in AI-generated sections
                                    viewModel.dismissAutocomplete()
                                }
                            }
                        }
                    },
                    onTabPressed: {
                        if viewModel.autocompleteSuggestion != nil {
                            acceptAutocomplete()
                        }
                    },
                    onEscapePressed: {
                        if viewModel.autocompleteSuggestion != nil {
                            viewModel.dismissAutocomplete()
                        }
                    },
                    onRightArrowPressed: {
                        if viewModel.autocompleteSuggestion != nil {
                            acceptOneWord()
                        }
                    },
                    searchQuery: isSearching ? searchQuery : nil,
                    semanticMatchText: isSearching ? semanticMatchText : nil
                )
                .frame(minHeight: 200)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .transition(.opacity)
            }
        }
        .onAppear {
            // Load note content when view appears
            loadNoteContent()
        }
        .onReceive(note.objectWillChange) { _ in
            // Sync the @State content with note.content changes (e.g., from translation)
            if let newContent = note.content, newContent != content {
                content = newContent
            }
            // Sync the @State title with note.title changes (e.g., from AI generation)
            if let newTitle = note.title, newTitle != title {
                title = newTitle
            }
        }
        .onDisappear {
            // FIX: Clean up debounce timer when view disappears
            autocompleteDebounceTimer?.invalidate()
            autocompleteDebounceTimer = nil

            // Note: Saving is handled by NoteViewModel.selectedNote.willSet
            // No need to save here - it would be redundant and cause double-saves
            // The willSet already cancels timers and saves immediately when switching notes
        }
    }

    // MARK: - Helpers

    private func loadNoteContent() {
        isLoading = true
        title = note.title ?? ""
        content = note.content ?? ""
        lastContentLength = content.count
        viewModel.dismissAutocomplete()
        isLoading = false
    }

    // FIX: Cache for AI section position to avoid repeated string searches
    @State private var cachedAISectionPosition: Int?
    @State private var cachedContentForAICheck: String = ""

    /// Check if cursor position is within base content (not in AI-generated sections)
    /// OPTIMIZED: Uses caching to avoid expensive string operations on every keystroke
    private func isInBaseContent(content: String, cursorPosition: Int) -> Bool {
        // FIX: Use cached position if content hasn't changed significantly
        if content == cachedContentForAICheck, let cachedPos = cachedAISectionPosition {
            return cursorPosition < cachedPos
        }

        // Define all AI-generated section markers (prefix matching to support timestamps)
        let markers = [
            "\n\n--- Summary",
            "\n\n--- Translation to ",
            "\n\n--- Patched",
            "\n\n--- Reformulated"
        ]

        // FIX: Use NSString for faster range finding
        let nsContent = content as NSString
        var firstAIPosition: Int = content.count // Default to end of content
        var foundMarker = false

        for marker in markers {
            let range = nsContent.range(of: marker)
            if range.location != NSNotFound {
                foundMarker = true
                if range.location < firstAIPosition {
                    firstAIPosition = range.location
                }
            }
        }

        // Cache the result
        if foundMarker {
            cachedAISectionPosition = firstAIPosition
        } else {
            cachedAISectionPosition = nil
        }
        cachedContentForAICheck = content

        // If no AI sections found, cursor is always in base content
        guard foundMarker else {
            return true
        }

        // Cursor is in base content if it's before the first AI section
        return cursorPosition < firstAIPosition
    }

    private func acceptAutocomplete() {
        if let suggestion = viewModel.acceptAutocomplete() {
            // FIX: Use NSString for faster string manipulation
            let insertPosition = min(currentCursorPosition, content.count)
            let suggestionWithSpace = suggestion + " "

            // FIX: Use NSMutableString for better performance
            let mutableContent = NSMutableString(string: content)
            mutableContent.insert(suggestionWithSpace, at: insertPosition)
            let newContent = mutableContent as String

            // Set desired cursor position to be after the inserted suggestion + space
            let newCursorPos = insertPosition + suggestionWithSpace.count
            desiredCursorPosition = newCursorPos
            currentCursorPosition = newCursorPos

            content = newContent
            note.content = newContent
            viewModel.saveNoteDebounced(note)

            // Request new autocomplete with updated text
            if aiEngine.isModelLoaded, shouldTriggerAutocomplete(text: newContent, cursorPosition: newCursorPos) {
                let textUpToCursor = String(newContent.prefix(min(newCursorPos, newContent.count)))
                viewModel.requestAutocomplete(for: textUpToCursor)
            }
        }
    }

    /// Accept one word from the suggestion (right arrow key)
    private func acceptOneWord() {
        guard let suggestion = viewModel.autocompleteSuggestion else { return }

        // FIX: Use NSString for faster searching
        let nsSuggestion = suggestion as NSString
        let wordBoundaryChars = CharacterSet(charactersIn: " .,!?\n")
        let range = nsSuggestion.rangeOfCharacter(from: wordBoundaryChars)

        let oneWord: String
        if range.location != NSNotFound {
            // Include the delimiter
            let endIndex = min(range.location + 1, nsSuggestion.length)
            oneWord = nsSuggestion.substring(to: endIndex)
        } else {
            oneWord = suggestion
        }

        // Insert the word at current cursor position
        let insertPosition = min(currentCursorPosition, content.count)

        // If the word ends with a sentence-ending punctuation, add a space
        var wordToInsert = oneWord
        if let last = oneWord.last, ".,!?".contains(last) {
            wordToInsert = oneWord + " "
        }

        // FIX: Use NSMutableString for performance
        let mutableContent = NSMutableString(string: content)
        mutableContent.insert(wordToInsert, at: insertPosition)
        let newContent = mutableContent as String

        // Set desired cursor position to be after the inserted word
        let newCursorPos = insertPosition + wordToInsert.count
        desiredCursorPosition = newCursorPos
        currentCursorPosition = newCursorPos

        content = newContent
        note.content = newContent
        viewModel.saveNoteDebounced(note)

        // Update the suggestion to remove the accepted word (original, not with added space)
        viewModel.acceptPartialAutocomplete(oneWord)

        // Request new autocomplete with updated text (if there's no remaining suggestion)
        if viewModel.autocompleteSuggestion == nil || viewModel.autocompleteSuggestion?.isEmpty == true {
            if aiEngine.isModelLoaded, shouldTriggerAutocomplete(text: newContent, cursorPosition: newCursorPos) {
                let textUpToCursor = String(newContent.prefix(min(newCursorPos, newContent.count)))
                viewModel.requestAutocomplete(for: textUpToCursor)
            }
        }
    }

    /// Smart triggering: only suggest autocomplete at natural pause points
    /// This prevents suggestions mid-word and reduces unnecessary inference calls
    private func shouldTriggerAutocomplete(text: String, cursorPosition: Int) -> Bool {
        guard cursorPosition > 0, cursorPosition <= text.count else { return false }

        // Get the character just before cursor
        let index = text.index(text.startIndex, offsetBy: cursorPosition - 1)
        let charBeforeCursor = text[index]

        // Natural pause points where autocomplete makes sense
        let naturalPausePoints: Set<Character> = [" ", ".", ",", ":", ";", "!", "?", "\n"]

        // Only trigger if we're at a natural pause point (after space, punctuation, etc.)
        return naturalPausePoints.contains(charBeforeCursor)
    }

    /// OLD - Kept for reference but no longer used
    /// Context extraction is now handled by AutocompleteService
    private func extractLastSentence(from text: String) -> String {
        guard !text.isEmpty else { return "" }

        // TinyLlama context: 2048 tokens × 4 chars/token ≈ 8000 chars
        let maxContextChars = 8000

        // If text is within context window, use all of it
        if text.count <= maxContextChars {
            return text
        }

        // Otherwise, take the last maxContextChars to fit in context window
        let startIndex = text.index(text.endIndex, offsetBy: -maxContextChars)
        return String(text[startIndex...])
    }

    private func wordCount(_ text: String) -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }
}
