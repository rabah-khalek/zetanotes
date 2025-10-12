//
//  NoteRepository.swift
//  NoteTaker
//
//  Centralized Core Data access for Note entities
//

import Foundation
import CoreData

struct NoteListItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let preview: String
    let createdAt: Date

    var displayTitle: String {
        title.isEmpty ? "Untitled" : title
    }

    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        if calendar.isDateInToday(createdAt) {
            formatter.timeStyle = .short
            return "Today, \(formatter.string(from: createdAt))"
        } else if calendar.isDateInYesterday(createdAt) {
            formatter.timeStyle = .short
            return "Yesterday, \(formatter.string(from: createdAt))"
        } else if calendar.isDate(createdAt, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "MMM d"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
        }
        return formatter.string(from: createdAt)
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
