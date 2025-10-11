//
//  Note+Extensions.swift
//  NoteTaker
//
//  Extensions for Core Data Note entity
//

import Foundation
import CoreData

// MARK: - Note Extensions

extension Note {
    /// Computed property for display title (shows "Untitled" if title is empty)
    var displayTitle: String {
        return title?.isEmpty == false ? title! : "Untitled"
    }

    /// Computed property for content preview (first 100 characters)
    var contentPreview: String {
        guard let content = content, !content.isEmpty else {
            return "No content"
        }

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 100 {
            return String(trimmed.prefix(100)) + "..."
        }
        return trimmed
    }

    /// Returns formatted creation date
    var formattedCreatedDate: String {
        guard let date = createdAt else { return "" }
        return formatDate(date)
    }

    /// Returns formatted update date
    var formattedUpdatedDate: String {
        guard let date = updatedAt else { return "" }
        return formatDate(date)
    }

    /// Helper to format dates consistently
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()

        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            formatter.timeStyle = .short
            return "Today, \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            formatter.timeStyle = .short
            return "Yesterday, \(formatter.string(from: date))"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "MMM d"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
        }

        return formatter.string(from: date)
    }

    /// Updates the note's timestamp
    func touch() {
        updatedAt = Date()
    }

    /// Generates a title from content if title is empty
    func generateTitleFromContent() {
        guard title?.isEmpty ?? true, let content = content, !content.isEmpty else { return }

        // Take first line or first 50 characters as title
        let firstLine = content.components(separatedBy: .newlines).first ?? ""
        let trimmed = firstLine.trimmingCharacters(in: .whitespaces)

        if trimmed.count > 50 {
            title = String(trimmed.prefix(50)) + "..."
        } else if !trimmed.isEmpty {
            title = trimmed
        }
    }
}

// MARK: - NoteEmbedding Extensions

extension NoteEmbedding {
    /// Converts binary data to float array for vector operations
    var vector: [Float]? {
        guard let data = embeddingData else { return nil }

        let count = data.count / MemoryLayout<Float>.stride
        var array = [Float](repeating: 0, count: count)

        data.withUnsafeBytes { rawBufferPointer in
            let bufferPointer = rawBufferPointer.bindMemory(to: Float.self)
            array = Array(bufferPointer)
        }

        return array
    }

    /// Sets the embedding from a float array
    func setVector(_ vector: [Float]) {
        let data = vector.withUnsafeBytes { Data($0) }
        embeddingData = data
    }

    /// Computes cosine similarity with another embedding
    /// - Parameter other: Another embedding to compare with
    /// - Returns: Similarity score between -1 and 1 (higher is more similar)
    func cosineSimilarity(with other: NoteEmbedding) -> Float {
        guard let vec1 = self.vector, let vec2 = other.vector, vec1.count == vec2.count else {
            return 0
        }

        var dotProduct: Float = 0
        var magnitude1: Float = 0
        var magnitude2: Float = 0

        for i in 0..<vec1.count {
            dotProduct += vec1[i] * vec2[i]
            magnitude1 += vec1[i] * vec1[i]
            magnitude2 += vec2[i] * vec2[i]
        }

        let denominator = sqrt(magnitude1) * sqrt(magnitude2)
        return denominator > 0 ? dotProduct / denominator : 0
    }
}

// MARK: - Tag Extensions

extension Tag {
    /// Computed property for display name
    var displayName: String {
        return name ?? "Unnamed Tag"
    }

    /// Returns notes sorted by update date
    var sortedNotes: [Note] {
        guard let notesSet = notes as? Set<Note> else { return [] }
        return notesSet.sorted { ($0.updatedAt ?? Date.distantPast) > ($1.updatedAt ?? Date.distantPast) }
    }
}
