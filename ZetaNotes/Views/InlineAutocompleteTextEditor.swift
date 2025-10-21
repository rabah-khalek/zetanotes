import AppKit
import SwiftUI

/// A SwiftUI wrapper for NSTextView that supports inline autocomplete ghost text at the cursor
/// Features:
/// - Ghost text rendering with proper alpha channel
/// - Typing pause detection (only generate suggestions when user stops typing)
/// - Consistent state management between text changes and suggestion updates
struct InlineAutocompleteTextEditor: NSViewRepresentable {
    @Binding var text: String
    var suggestion: String?
    var onAccept: (() -> Void)?
    var onDismiss: (() -> Void)?
    var onChange: ((String) -> Void)?

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: InlineAutocompleteTextEditor
        var ghostTextAttributes: [NSAttributedString.Key: Any] = [:]
        var isUserTyping = false
        var lastTextLength = 0

        init(_ parent: InlineAutocompleteTextEditor) {
            self.parent = parent
            super.init()
            setupGhostTextAttributes()
        }

        func setupGhostTextAttributes() {
            ghostTextAttributes = [
                .foregroundColor: NSColor.secondaryLabelColor.withAlphaComponent(0.5),
                .font: NSFont.systemFont(ofSize: NSFont.systemFontSize)
            ]
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }

            // Detect if user is actively typing (text length is increasing)
            let currentLength = textView.string.count
            isUserTyping = currentLength > lastTextLength
            lastTextLength = currentLength

            // Always dismiss old suggestion when text changes from typing
            if isUserTyping {
                parent.onDismiss?()
            }

            DispatchQueue.main.async {
                self.parent.text = textView.string
                self.parent.onChange?(textView.string)
            }
        }

        func textView(
            _ textView: NSTextView,
            shouldChangeTextIn affectedCharRange: NSRange,
            replacementString: String?
        ) -> Bool {
            // Handle Tab key to accept suggestion
            if replacementString == "\t", let suggestion = parent.suggestion, !suggestion.isEmpty {
                parent.onAccept?()
                return false // Don't insert the tab
            }
            // Handle Escape key to dismiss
            if replacementString == "\u{1B}" { // Escape character
                parent.onDismiss?()
                return false
            }

            // For any other typing (not Tab/Esc), dismiss old suggestion immediately
            if let replacement = replacementString, !replacement.isEmpty, replacement != "\t", replacement != "\u{1B}" {
                parent.onDismiss?()
            }

            return true
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

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
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: .greatestFiniteMagnitude
        )

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        // Only update text if it doesn't match (avoid fighting with user input)
        if textView.string != text {
            let selectedRange = textView.selectedRange()
            textView.string = text
            textView.setSelectedRange(selectedRange)
        }

        // Only show ghost text when user has stopped typing (not actively typing)
        if !context.coordinator.isUserTyping {
            updateGhostText(in: textView, context: context)
        }
    }

    func updateGhostText(in textView: NSTextView, context: Context) {
        guard let suggestion = suggestion, !suggestion.isEmpty else {
            removeGhostText(from: textView)
            return
        }

        let cursorPosition = textView.selectedRange().location
        guard cursorPosition == text.count else {
            // Only show suggestion at the end of text
            removeGhostText(from: textView)
            return
        }

        // Verify the textView content matches our binding before adding ghost text
        guard textView.string == text else {
            return
        }

        guard let textStorage = textView.textStorage else { return }

        // Create attributed string with ghost text
        let fullText = text + suggestion
        let attributedString = NSMutableAttributedString(string: fullText)

        // Apply normal style to existing text
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.labelColor,
            .font: NSFont.systemFont(ofSize: NSFont.systemFontSize)
        ]
        attributedString.addAttributes(normalAttributes, range: NSRange(location: 0, length: text.count))

        // Apply ghost style to suggestion with proper alpha
        attributedString.addAttributes(
            context.coordinator.ghostTextAttributes,
            range: NSRange(location: text.count, length: suggestion.count)
        )

        // Update text storage SAFELY with begin/end editing
        textStorage.beginEditing()
        textStorage.setAttributedString(attributedString)
        textStorage.endEditing()

        // Restore cursor position to end of actual text
        textView.setSelectedRange(NSRange(location: cursorPosition, length: 0))
    }

    func removeGhostText(from textView: NSTextView) {
        // Only remove if there's extra content (ghost text present)
        let currentText = textView.string
        if currentText != text {
            guard let textStorage = textView.textStorage else { return }
            let selectedRange = textView.selectedRange()

            // Safely update text storage
            textStorage.beginEditing()
            textStorage.mutableString.setString(text)
            textStorage.endEditing()

            // Restore cursor position after removing ghost text
            textView.setSelectedRange(NSRange(location: min(selectedRange.location, text.count), length: 0))
        }
    }
}
