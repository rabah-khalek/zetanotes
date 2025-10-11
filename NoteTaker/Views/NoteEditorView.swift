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
}

// MARK: - Simple Text Editor

/// A clean SwiftUI wrapper for NSTextView - no ghost text complications
/// Suggestions shown in separate tooltip to keep editor smooth
struct SimpleTextEditor: NSViewRepresentable {
    @Binding var text: String
    var onChange: ((String) -> Void)?
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

            DispatchQueue.main.async {
                self.parent.text = currentText
                self.parent.onChange?(currentText)
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
            // Title Field
            TextField("Title", text: $title, axis: .vertical)
                .font(.title)
                .fontWeight(.bold)
                .textFieldStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 8)
                .onChange(of: title) { newValue in
                    note.title = newValue
                    viewModel.saveNote(note)
                }

            Divider()

            // Content Editor (Simple, No Ghost Text)
            ZStack(alignment: .topLeading) {
                SimpleTextEditor(
                    text: $content,
                    onChange: { newValue in
                        // Update both the state and note content
                        content = newValue
                        note.content = newValue
                        viewModel.saveNote(note)

                        // Extract last sentence for context
                        let context = extractLastSentence(from: newValue)

                        // Request autocomplete only if model is loaded and sufficient context
                        if aiEngine.isModelLoaded && context.count >= 10 {
                            viewModel.requestAutocomplete(for: context)
                        } else {
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
                .padding(.horizontal, 8)
                .padding(.vertical, 8)

                // Suggestion Tooltip (Shown Below Cursor)
                if let suggestion = viewModel.autocompleteSuggestion, !suggestion.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(suggestion)
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                            .lineLimit(3)
                            .padding(8)

                        HStack(spacing: 8) {
                            Label("Tab", systemImage: "keyboard")
                            Text("to accept")
                            Spacer()
                            Label("Esc", systemImage: "escape")
                            Text("to dismiss")
                        }
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 6)
                    }
                    .frame(maxWidth: 300)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 2)
                    .padding(.leading, 20)
                    .padding(.top, 40)
                }
            }

            Divider()

            // Bottom Toolbar
            HStack(spacing: 16) {
                // Summary Section
                if let summary = note.summary, !summary.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .foregroundColor(.accentColor)

                        Text(summary)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)
                }

                Spacer()

                // AI Actions
                Button(action: {
                    Task {
                        await viewModel.generateSummary(for: note)
                    }
                }) {
                    HStack(spacing: 4) {
                        if viewModel.isGeneratingSummary {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 12, height: 12)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text("Summarize")
                            .font(.caption)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(content.count < 50 || viewModel.isGeneratingSummary)

                // Word/Character Count
                Text("\(wordCount(content)) words")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Character Count
                Text("\(content.count) chars")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .onAppear {
            loadNoteContent()
        }
        .onChange(of: note.id) { _ in
            loadNoteContent()
        }
    }

    // MARK: - Helpers

    private func loadNoteContent() {
        title = note.title ?? ""
        content = note.content ?? ""
        viewModel.dismissAutocomplete()
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
