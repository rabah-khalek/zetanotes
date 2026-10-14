//
//  ChatManager.swift
//  ZetaNotes
//
//  Manages chat conversation history and persistence
//

import Combine
import Foundation

class ChatManager: ObservableObject {
    static let shared = ChatManager()

    @Published var messages: [ChatMessage] = []
    @Published var settings: ChatSettings

    private let fileManager = FileManager.default
    private var chatHistoryURL: URL {
        // Use Application Support directory (sandboxed) instead of Documents directory
        let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let zetaNotesDirectory = appSupportDirectory.appendingPathComponent("ZetaNotes")

        // Ensure the directory exists
        try? fileManager.createDirectory(at: zetaNotesDirectory, withIntermediateDirectories: true, attributes: nil)

        return zetaNotesDirectory.appendingPathComponent("chat_history.json")
    }

    private init() {
        settings = ChatSettings.load()
        loadHistory()
    }

    // MARK: - Message Management

    /// Adds a new message to the conversation
    func addMessage(role: ChatMessage.Role, content: String) {
        let message = ChatMessage(role: role, content: content)
        messages.append(message)
        saveHistory()
    }

    /// Clears all messages from the conversation
    func clearMessages() {
        messages.removeAll()
        saveHistory()
    }

    /// Exports the conversation to markdown format with timestamp
    func exportToMarkdown() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, h:mm a"
        let dateString = dateFormatter.string(from: Date())

        var markdown = "#### Chat • \(dateString)\n\n"

        for message in messages {
            // Skip system messages in export
            if message.role == .system {
                continue
            }

            markdown += message.markdownFormat + "\n\n"
        }

        return markdown
    }

    // MARK: - Persistence

    /// Loads chat history from disk
    private func loadHistory() {
        guard fileManager.fileExists(atPath: chatHistoryURL.path) else {
            print("No chat history found")
            return
        }

        do {
            let data = try Data(contentsOf: chatHistoryURL)
            let decoded = try JSONDecoder().decode([ChatMessage].self, from: data)
            messages = decoded
            print("Loaded \(messages.count) chat messages")
        } catch {
            print("Failed to load chat history: \(error)")
        }
    }

    /// Saves chat history to disk
    private func saveHistory() {
        do {
            let encoded = try JSONEncoder().encode(messages)
            try encoded.write(to: chatHistoryURL)
            print("Saved \(messages.count) chat messages")
        } catch {
            print("Failed to save chat history: \(error)")
        }
    }

    // MARK: - Settings Management

    /// Updates chat settings
    func updateSettings(_ newSettings: ChatSettings) {
        settings = newSettings
        settings.save()
    }
}
