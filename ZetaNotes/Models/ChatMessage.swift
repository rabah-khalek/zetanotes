//
//  ChatMessage.swift
//  ZetaNotes
//
//  Chat message model for AI chat feature
//

import Foundation

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let role: Role
    let content: String
    let timestamp: Date

    enum Role: String, Codable {
        case user
        case assistant
        case system
    }

    init(id: UUID = UUID(), role: Role, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }

    /// Formats the timestamp in the style "Oct 17, 10:10 PM"
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: timestamp)
    }

    /// Formats the message for markdown export
    var markdownFormat: String {
        let roleLabel = role == .user ? "You" : "Assistant"
        return "**\(roleLabel)** • \(formattedTimestamp)\n\n\(content)"
    }
}
