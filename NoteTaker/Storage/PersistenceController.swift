//
//  PersistenceController.swift
//  NoteTaker
//
//  Core Data stack and persistence management
//  Optimized for low-latency operations on Apple Silicon
//

import CoreData
import Foundation

/// Manages the Core Data stack for storing notes, embeddings, and tags
/// Singleton pattern ensures single source of truth for data
class PersistenceController: ObservableObject {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    // MARK: - Initialization

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "NotesDataModel")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        // Configure for performance on Apple Silicon
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.loadPersistentStores { description, error in
            if let error = error {
                // In production, handle this error appropriately
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }

        // Configure view context for UI operations
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Enable undo for better user experience
        container.viewContext.undoManager = UndoManager()
    }

    // MARK: - Preview Helper

    /// Creates a preview instance with sample data for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        // Create sample notes for preview
        for i in 1...5 {
            let note = Note(context: context)
            note.id = UUID()
            note.title = "Sample Note \(i)"
            note.content = "This is sample content for note \(i). It demonstrates the note-taking interface."
            note.createdAt = Date().addingTimeInterval(-Double(i * 86400))
            note.updatedAt = Date()
        }

        do {
            try context.save()
        } catch {
            print("Failed to save preview data: \(error)")
        }

        return controller
    }()

    // MARK: - Core Data Operations

    /// Saves the context if there are changes
    /// - Parameter context: The managed object context to save (defaults to view context)
    func save(context: NSManagedObjectContext? = nil) {
        let targetContext = context ?? container.viewContext

        guard targetContext.hasChanges else { return }

        do {
            try targetContext.save()
        } catch {
            print("Failed to save context: \(error)")
            // In production, implement proper error handling
        }
    }

    /// Creates a background context for heavy operations (like embedding generation)
    /// - Returns: A new background context
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    /// Performs a batch delete for cleaning up old data
    /// - Parameter fetchRequest: The fetch request defining what to delete
    func batchDelete<T: NSManagedObject>(_ fetchRequest: NSFetchRequest<T>) async throws {
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
        deleteRequest.resultType = .resultTypeObjectIDs

        let context = newBackgroundContext()

        try await context.perform {
            let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
            guard let objectIDs = result?.result as? [NSManagedObjectID] else { return }

            let changes = [NSDeletedObjectsKey: objectIDs]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.container.viewContext])
        }
    }

    // MARK: - Note Operations

    /// Creates a new note with default values
    /// - Returns: The newly created note
    @discardableResult
    func createNote() -> Note {
        let context = container.viewContext
        let note = Note(context: context)
        note.id = UUID()
        note.title = "Untitled"
        note.content = ""
        note.createdAt = Date()
        note.updatedAt = Date()

        save()
        return note
    }

    /// Deletes a note and its associated embeddings
    /// - Parameter note: The note to delete
    func deleteNote(_ note: Note) {
        let context = container.viewContext
        context.delete(note)
        save()
    }

    /// Fetches all notes sorted by update date
    /// - Returns: Array of notes
    func fetchAllNotes() -> [Note] {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Note.updatedAt, ascending: false)]

        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Failed to fetch notes: \(error)")
            return []
        }
    }

    /// Fetches notes matching a search query (simple text search)
    /// - Parameter query: The search string
    /// - Returns: Array of matching notes
    func searchNotes(query: String) -> [Note] {
        guard !query.isEmpty else { return fetchAllNotes() }

        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.predicate = NSPredicate(format: "title CONTAINS[cd] %@ OR content CONTAINS[cd] %@", query, query)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Note.updatedAt, ascending: false)]

        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Failed to search notes: \(error)")
            return []
        }
    }
}
