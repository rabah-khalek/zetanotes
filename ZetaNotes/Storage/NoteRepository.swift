//
//  NoteRepository.swift
//  ZetaNotes
//
//  Centralized Core Data access for Note entities
//

import CoreData
import Foundation

struct NoteListItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let preview: String
    let createdAt: Date
    let updatedAt: Date

    // Static cached formatters to avoid repeated allocation
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    private static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()

    private static let calendar = Calendar.current

    var displayTitle: String {
        title.isEmpty ? "Untitled" : title
    }

    var formattedCreatedDate: String {
        // Display updatedAt instead of createdAt for more relevant sorting
        if Self.calendar.isDateInToday(updatedAt) {
            return "Today, \(Self.timeFormatter.string(from: updatedAt))"
        } else if Self.calendar.isDateInYesterday(updatedAt) {
            return "Yesterday, \(Self.timeFormatter.string(from: updatedAt))"
        } else if Self.calendar.isDate(updatedAt, equalTo: Date(), toGranularity: .year) {
            return Self.monthDayFormatter.string(from: updatedAt)
        } else {
            return Self.fullDateFormatter.string(from: updatedAt)
        }
    }
}

final class NoteRepository {
    private let persistenceController: PersistenceController

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    func fetchAllNotes() -> [Note] {
        persistenceController.fetchAllNotes()
    }

    func makeListItem(from note: Note) -> NoteListItem? {
        guard let id = note.id,
              let createdAt = note.createdAt,
              let updatedAt = note.updatedAt else { return nil }
        let title = note.displayTitle
        let preview: String
        if let summary = note.summary, !summary.isEmpty {
            preview = summary
        } else {
            preview = note.contentPreview
        }
        return NoteListItem(id: id, title: title, preview: preview, createdAt: createdAt, updatedAt: updatedAt)
    }

    @discardableResult
    func createNote() -> Note {
        persistenceController.createNote()
    }

    func deleteNote(_ note: Note) {
        persistenceController.deleteNote(note)
    }

    func saveContext() {
        persistenceController.save()
    }
}
