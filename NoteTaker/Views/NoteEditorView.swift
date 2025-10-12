//
//  NoteEditorView.swift
//  NoteTaker
//
//  Rich text editor with AI autocomplete suggestions
//

import SwiftUI
import AppKit

// MARK: - Custom Text View with Key Handling

class AutocompleteTextView: NSTextView {
    var onTabPressed: (() -> Void)?
    var onEscapePressed: (() -> Void)?
    var ghostText: String? {
        didSet {
            setNeedsDisplay(bounds)
        }
    }

    override func keyDown(with event: NSEvent) {
        // Handle Tab key (keyCode 48)
        if event.keyCode == 48 {
            if let onTab = onTabPressed {
                onTab()
                return // Don't call super - we handled it
            }
        }
        // Handle Escape key (keyCode 53)
        else if event.keyCode == 53 {
            if let onEscape = onEscapePressed {
                onEscape()
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
        let glyphRect = layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 0), in: textContainer)

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
    var onChange: ((String, Int) -> Void)?  // Now includes cursor position
    var onTabPressed: (() -> Void)?
    var onEscapePressed: (() -> Void)?

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SimpleTextEditor

        init(_ parent: SimpleTextEditor) {
            self.parent = parent
            super.init()
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
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
        textView.backgroundColor = .clear
        textView.textColor = NSColor.labelColor
        textView.string = text
        textView.allowsUndo = true
        textView.autoresizingMask = [.width, .height]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: .greatestFiniteMagnitude)

        // Set up key handlers
        textView.onTabPressed = onTabPressed
        textView.onEscapePressed = onEscapePressed

        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? AutocompleteTextView else { return }

        // Update text if it differs from what's in the view
        // This handles both programmatic updates (like accepting autocomplete) and external changes
        if textView.string != text {
            let oldLength = textView.string.count

            // Update the text
            textView.string = text

            // Move cursor to the end if we appended text (autocomplete case)
            if text.count > oldLength {
                textView.setSelectedRange(NSRange(location: text.count, length: 0))
            }
        }

        // Update ghost text
        textView.ghostText = ghostText

        // Update key handlers
        textView.onTabPressed = onTabPressed
        textView.onEscapePressed = onEscapePressed
    }
}

// MARK: - Note Editor View

struct NoteEditorView: View {
    let note: Note
    @ObservedObject var viewModel: NoteViewModel
    @EnvironmentObject var aiEngine: AIEngine

    @State private var title: String = ""
    @State private var content: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Title Field with AI Generate Button
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
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
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
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 12)

            // Content Editor (Clean, minimal Mac style with ghost text)
            SimpleTextEditor(
                text: $content,
                ghostText: viewModel.autocompleteSuggestion,
                onChange: { newValue, cursorPosition in
                    // Update both the state and note content
                    content = newValue
                    note.content = newValue
                    viewModel.saveNote(note)

                    // Check if cursor is in base content (not in AI-generated sections)
                    if isInBaseContent(content: newValue, cursorPosition: cursorPosition) {
                        // Extract last sentence for context
                        let context = extractLastSentence(from: newValue)

                        // Request autocomplete only if model is loaded and sufficient context
                        if aiEngine.isModelLoaded && context.count >= 10 {
                            viewModel.requestAutocomplete(for: context)
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
                }
            )
            .frame(minHeight: 200)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Bottom Toolbar (Minimal Mac Notes style - Stats only)
            HStack(spacing: 0) {
                // Stats
                HStack(spacing: 12) {
                    Text("\(wordCount(content)) words")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary.opacity(0.5))

                    Text("\(content.count) characters")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
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
        // Define all AI-generated section markers
        let markers = [
            "\n\n--- Summary ---",
            "\n\n--- Translation to ",
            "\n\n--- Patched ---",
            "\n\n--- Reformulated ---"
        ]

        // Find the earliest AI section marker
        var firstAIPosition: Int? = nil

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
            // Append suggestion to content
            let newContent = content + suggestion
            content = newContent
            note.content = newContent
            viewModel.saveNote(note)
        }
    }

    /// Extract context for autocomplete using TinyLlama's full context window
    /// TinyLlama 1.1B supports 2,048 tokens ≈ 8,000 characters (using 4 chars/token approximation)
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
