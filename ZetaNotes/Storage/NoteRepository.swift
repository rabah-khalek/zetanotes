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
        if Self.calendar.isDateInToday(createdAt) {
            return "Today, \(Self.timeFormatter.string(from: createdAt))"
        } else if Self.calendar.isDateInYesterday(createdAt) {
            return "Yesterday, \(Self.timeFormatter.string(from: createdAt))"
        } else if Self.calendar.isDate(createdAt, equalTo: Date(), toGranularity: .year) {
            return Self.monthDayFormatter.string(from: createdAt)
        } else {
            return Self.fullDateFormatter.string(from: createdAt)
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
        guard let id = note.id, let createdAt = note.createdAt else { return nil }
        let title = note.displayTitle
        let preview: String
        if let summary = note.summary, !summary.isEmpty {
            preview = summary
        } else {
            preview = note.contentPreview
        }
        return NoteListItem(id: id, title: title, preview: preview, createdAt: createdAt)
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
