//
//  MarkdownRenderer.swift
//  NoteTaker
//
//  Simple Markdown renderer using SwiftUI's native Markdown support
//

import SwiftUI

struct MarkdownRenderer: View {
    let text: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(parseMarkdown(), id: \.id) { element in
                    renderElement(element)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func parseMarkdown() -> [MarkdownElement] {
        var elements: [MarkdownElement] = []
        let lines = text.components(separatedBy: .newlines)
        var lineIndex = 0

        while lineIndex < lines.count {
            let line = lines[lineIndex]
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            // Skip empty lines
            if trimmedLine.isEmpty {
                lineIndex += 1
                continue
            }

            // Check for headings
            if trimmedLine.hasPrefix("#") {
                let level = trimmedLine.prefix(while: { $0 == "#" }).count
                let title = trimmedLine.dropFirst(level).trimmingCharacters(in: .whitespaces)
                elements.append(MarkdownElement(type: .heading(level: level, text: title)))
                lineIndex += 1
                continue
            }

            // Check for code blocks
            if trimmedLine.hasPrefix("```") {
                var codeLines: [String] = []
                lineIndex += 1
                while lineIndex < lines.count, !lines[lineIndex].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    codeLines.append(lines[lineIndex])
                    lineIndex += 1
                }
                elements.append(MarkdownElement(type: .codeBlock(code: codeLines.joined(separator: "\n"))))
                lineIndex += 1
                continue
            }

            // Check for bullet lists
            if trimmedLine.hasPrefix("- ") || trimmedLine.hasPrefix("* ") || trimmedLine.hasPrefix("+ ") {
                let item = String(trimmedLine.dropFirst(2))
                elements.append(MarkdownElement(type: .bulletItem(text: item)))
                lineIndex += 1
                continue
            }

            // Check for numbered lists
            if let firstChar = trimmedLine.first, firstChar.isNumber {
                if let dotIndex = trimmedLine.firstIndex(of: ".") {
                    let item = String(trimmedLine[trimmedLine.index(after: dotIndex)...])
                        .trimmingCharacters(in: .whitespaces)
                    elements.append(MarkdownElement(type: .numberedItem(text: item)))
                    lineIndex += 1
                    continue
                }
            }

            // Check for blockquotes
            if trimmedLine.hasPrefix(">") {
                let quote = trimmedLine.dropFirst().trimmingCharacters(in: .whitespaces)
                elements.append(MarkdownElement(type: .blockquote(text: quote)))
                lineIndex += 1
                continue
            }

            // Check for horizontal rule
            if trimmedLine == "---" || trimmedLine == "***" || trimmedLine == "___" {
                elements.append(MarkdownElement(type: .horizontalRule))
                lineIndex += 1
                continue
            }

            // Regular paragraph
            elements.append(MarkdownElement(type: .paragraph(text: line)))
            lineIndex += 1
        }

        return elements
    }

    @ViewBuilder
    private func renderElement(_ element: MarkdownElement) -> some View {
        switch element.type {
        case let .heading(level, text):
            headingView(level: level, text: text)
        case let .paragraph(text):
            // Use SwiftUI's native Markdown rendering via LocalizedStringKey
            Text(LocalizedStringKey(text))
                .textSelection(.enabled)
        case let .codeBlock(code):
            codeBlockView(code: code)
        case let .bulletItem(text):
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(.body)
                Text(LocalizedStringKey(text))
                    .textSelection(.enabled)
            }
        case let .numberedItem(text):
            HStack(alignment: .top, spacing: 8) {
                Text("1.")
                    .font(.body)
                Text(LocalizedStringKey(text))
                    .textSelection(.enabled)
            }
        case let .blockquote(text):
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 4)
                Text(LocalizedStringKey(text))
                    .italic()
                    .textSelection(.enabled)
            }
            .padding(.vertical, 4)
        case .horizontalRule:
            Divider()
                .padding(.vertical, 8)
        }
    }

    private func headingView(level: Int, text: String) -> some View {
        let fontSize: CGFloat = {
            switch level {
            case 1: return 28
            case 2: return 24
            case 3: return 20
            case 4: return 18
            case 5: return 16
            default: return 14
            }
        }()

        return Text(LocalizedStringKey(text))
            .font(.system(size: fontSize, weight: .bold))
            .textSelection(.enabled)
    }

    private func codeBlockView(code: String) -> some View {
        Text(code)
            .font(.system(.body, design: .monospaced))
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(4)
            .textSelection(.enabled)
    }
}

struct MarkdownElement {
    let id = UUID()
    let type: MarkdownElementType
}

enum MarkdownElementType {
    case heading(level: Int, text: String)
    case paragraph(text: String)
    case codeBlock(code: String)
    case bulletItem(text: String)
    case numberedItem(text: String)
    case blockquote(text: String)
    case horizontalRule
}
