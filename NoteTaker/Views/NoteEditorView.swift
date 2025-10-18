//
//  NoteEditorView.swift
//  NoteTaker
//
//  Rich text editor with AI autocomplete suggestions
//

import AppKit
import SwiftUI

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

        // Update text if it differs (from switching notes or autocomplete acceptance)
        if textView.string != text {
            // Set flag to prevent textDidChange from triggering
            context.coordinator.isUpdatingProgrammatically = true

            textView.string = text

            // Set cursor position if specified (for autocomplete acceptance)
            if let desiredPosition = desiredCursorPosition {
                let newCursorPosition = min(desiredPosition, text.count)
                textView.setSelectedRange(NSRange(location: newCursorPosition, length: 0))
            }

            // Reset flag after update
            context.coordinator.isUpdatingProgrammatically = false
        }

        // Update ghost text
        textView.ghostText = ghostText

        // Update key handlers
        textView.onTabPressed = onTabPressed
        textView.onEscapePressed = onEscapePressed
        textView.onRightArrowPressed = onRightArrowPressed

        // Apply search highlighting if needed
        if let matchText = semanticMatchText, !matchText.isEmpty {
            // Semantic result: highlight the matched text
            highlightSearchResults(in: textView, query: matchText)
        } else if let searchQuery = searchQuery, !searchQuery.isEmpty {
            // Keyword: highlight search query as you type
            highlightSearchResults(in: textView, query: searchQuery)
        } else {
            // Clear highlighting
            clearHighlighting(in: textView)
        }
    }

    private func highlightSearchResults(in textView: NSTextView, query: String) {
        guard let textStorage = textView.textStorage else { return }

        let text = textStorage.string
        let searchRange = NSRange(location: 0, length: text.utf16.count)

        // First, remove any existing background colors
        textStorage.removeAttribute(.backgroundColor, range: searchRange)

        // Find all matches
        let searchOptions: NSString.CompareOptions = .caseInsensitive
        var searchStart = text.startIndex

        while searchStart < text.endIndex,
              let range = text.range(of: query, options: searchOptions, range: searchStart ..< text.endIndex) {
            let nsRange = NSRange(range, in: text)
            textStorage.addAttribute(
                .backgroundColor,
                value: NSColor.systemYellow.withAlphaComponent(0.4),
                range: nsRange
            )
            searchStart = range.upperBound
        }
    }

    private func clearHighlighting(in textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        let range = NSRange(location: 0, length: textStorage.length)
        textStorage.removeAttribute(.backgroundColor, range: range)
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

    var body: some View {
        VStack(spacing: 0) {
            // Title Field with AI Generate Button and Markdown Toggle
            HStack(spacing: 8) {
                // Generate Title Button (Recycle icon) - LEFT SIDE
                Button(action: {
                    Task {
                        await viewModel.generateTitle(for: note)
                    }
                }) {
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
                .buttonStyle(.plain)
                .disabled(content.count < 20 || viewModel.isGeneratingTitle)
                .help("Generate title from content")
                .opacity((content.count < 20 || viewModel.isGeneratingTitle) ? 0.3 : 1.0)

                TextField("Title", text: $title)
                    .font(.system(size: 22, weight: .semibold))
                    .textFieldStyle(.plain)
                    .onChange(of: title) { newValue in
                        note.title = newValue
                        viewModel.saveNote(note)
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
                MarkdownRenderer(text: content)
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

                        // Update both the state and note content
                        content = newValue
                        note.content = newValue
                        viewModel.saveNoteDebounced(note) // ✅ Use debounced save for typing

                        // Check if cursor is in base content (not in AI-generated sections)
                        if isInBaseContent(content: newValue, cursorPosition: cursorPosition) {
                            // Smart triggering: only suggest at natural pause points
                            if shouldTriggerAutocomplete(text: newValue, cursorPosition: cursorPosition) {
                                // Request autocomplete only if model is loaded
                                if aiEngine.isModelLoaded, newValue.count >= 10 {
                                    // Extract text up to cursor for better autocomplete accuracy
                                    let textUpToCursor = String(newValue.prefix(min(cursorPosition, newValue.count)))
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
        .onChange(of: note.content) { newContent in
            // Sync the @State content with note.content changes (e.g., from translation)
            if let newContent = newContent, newContent != content {
                content = newContent
            }
        }
        .onChange(of: note.title) { newTitle in
            // Sync the @State title with note.title changes (e.g., from AI generation)
            if let newTitle = newTitle, newTitle != title {
                title = newTitle
            }
        }
        .onDisappear {
            // Final save when editor view disappears
            note.content = content
            note.title = title
            viewModel.saveNote(note)
        }
    }

    // MARK: - Helpers

    private func loadNoteContent() {
        title = note.title ?? ""
        content = note.content ?? ""
        viewModel.dismissAutocomplete()
    }

    /// Check if cursor position is within base content (not in AI-generated sections)
    private func isInBaseContent(content: String, cursorPosition: Int) -> Bool {
        // Define all AI-generated section markers (prefix matching to support timestamps)
        let markers = [
            "\n\n--- Summary",
            "\n\n--- Translation to ",
            "\n\n--- Patched",
            "\n\n--- Reformulated"
        ]

        // Find the earliest AI section marker
        var firstAIPosition: Int?

        for marker in markers {
            if let range = content.range(of: marker) {
                let position = content.distance(from: content.startIndex, to: range.lowerBound)
                if firstAIPosition == nil || position < firstAIPosition! {
                    firstAIPosition = position
                }
            }
        }

        // If no AI sections found, cursor is always in base content
        guard let aiPosition = firstAIPosition else {
            return true
        }

        // Cursor is in base content if it's before the first AI section
        return cursorPosition < aiPosition
    }

    private func acceptAutocomplete() {
        if let suggestion = viewModel.acceptAutocomplete() {
            // Insert suggestion at current cursor position, followed by a space
            let insertPosition = min(currentCursorPosition, content.count)
            let index = content.index(content.startIndex, offsetBy: insertPosition)
            var newContent = content
            let suggestionWithSpace = suggestion + " "
            newContent.insert(contentsOf: suggestionWithSpace, at: index)

            // Set desired cursor position to be after the inserted suggestion + space
            let newCursorPos = insertPosition + suggestionWithSpace.count
            desiredCursorPosition = newCursorPos
            currentCursorPosition = newCursorPos

            content = newContent
            note.content = newContent
            viewModel.saveNoteDebounced(note) // ✅ Use debounced save

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

        // Find the first word boundary (space or punctuation)
        var firstWordEnd = suggestion.firstIndex(where: { char in
            char == " " || char == "." || char == "," || char == "!" || char == "?" || char == "\n"
        })

        // If found, include the delimiter; otherwise take the whole suggestion
        if let endIndex = firstWordEnd {
            // Include the space/punctuation
            firstWordEnd = suggestion.index(after: endIndex)
        }

        let oneWord = String(suggestion[..<(firstWordEnd ?? suggestion.endIndex)])

        // Insert the word at current cursor position
        let insertPosition = min(currentCursorPosition, content.count)
        let index = content.index(content.startIndex, offsetBy: insertPosition)
        var newContent = content

        // If the word ends with a sentence-ending punctuation, add a space
        var wordToInsert = oneWord
        if oneWord.last == "." || oneWord.last == "!" || oneWord.last == "?" {
            wordToInsert = oneWord + " "
        }

        newContent.insert(contentsOf: wordToInsert, at: index)

        // Set desired cursor position to be after the inserted word
        let newCursorPos = insertPosition + wordToInsert.count
        desiredCursorPosition = newCursorPos
        currentCursorPosition = newCursorPos

        content = newContent
        note.content = newContent
        viewModel.saveNoteDebounced(note) // ✅ Use debounced save

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
