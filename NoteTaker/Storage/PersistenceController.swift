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
        container.persistentStoreDescriptions.first?.setOption(
            true as NSNumber,
            forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
        )

        // Enable data encryption at rest for security (macOS)
        // On macOS, Core Data encryption is handled at the file system level
        // Data is encrypted when FileVault is enabled
        // For additional security, we ensure the store is not accessible to other apps
        if !inMemory {
            // Set file protection attributes after store creation
            // This will be done in the completion handler
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                // In production, handle this error appropriately
                fatalError("Failed to load Core Data stack: \(error)")
            }

            // Set file permissions for additional security (macOS)
            if let storeURL = description.url, !inMemory {
                do {
                    // Set file attributes to protect the database file
                    let attributes: [FileAttributeKey: Any] = [
                        .posixPermissions: 0o600 // Owner read/write only
                    ]
                    try FileManager.default.setAttributes(attributes, ofItemAtPath: storeURL.path)
                    print("✅ Core Data store secured with restricted permissions")
                } catch {
                    print("⚠️ Failed to set file permissions: \(error)")
                }
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
        for noteNumber in 1 ... 5 {
            let note = Note(context: context)
            note.id = UUID()
            note.title = "Sample Note \(noteNumber)"
            note.content = "This is sample content for note \(noteNumber). It demonstrates the note-taking interface."
            note.createdAt = Date().addingTimeInterval(-Double(noteNumber * 86400))
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
    /// Implements retry logic for merge conflicts
    /// - Parameter context: The managed object context to save (defaults to view context)
    func save(context: NSManagedObjectContext? = nil) {
        let targetContext = context ?? container.viewContext

        guard targetContext.hasChanges else { return }

        var retryCount = 0
        let maxRetries = 3

        while retryCount < maxRetries {
            do {
                try targetContext.save()
                return // Success!
            } catch let error as NSError {
                // Check if it's a merge conflict
                if error.domain == NSCocoaErrorDomain, error.code == NSManagedObjectMergeError {
                    print(
                        "⚠️ Merge conflict detected, attempting to resolve (attempt \(retryCount + 1)/\(maxRetries))..."
                    )

                    // Refresh all objects to get latest data and merge changes
                    for object in targetContext.registeredObjects {
                        targetContext.refresh(object, mergeChanges: true)
                    }

                    retryCount += 1

                    // If still have changes after refresh, try again
                    if !targetContext.hasChanges {
                        print("✅ Merge conflict resolved, no changes after refresh")
                        return
                    }
                    continue
                } else {
                    // Non-recoverable error
                    print("❌ Failed to save context: \(error.localizedDescription)")
                    print("   Error details: \(error)")

                    // For critical errors, we must handle gracefully
                    // Don't crash the app, but ensure data integrity
                    targetContext.rollback()
                    return
                }
            }
        }

        // If we exhausted retries, roll back to prevent corruption
        print("❌ Failed to save after \(maxRetries) attempts, rolling back changes")
        targetContext.rollback()
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
        guard let fetchRequest = fetchRequest as? NSFetchRequest<NSFetchRequestResult> else {
            throw NSError(
                domain: "PersistenceController",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid fetch request"]
            )
        }
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
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

        // Prefetch relationships to avoid N+1 queries
        request.relationshipKeyPathsForPrefetching = ["embedding", "tags"]

        // Limit results for better performance with large datasets
        request.fetchLimit = 1000

        // Use property-level fault optimization
        request.returnsObjectsAsFaults = false

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

        // Prefetch relationships to avoid N+1 queries
        request.relationshipKeyPathsForPrefetching = ["embedding", "tags"]

        // Limit search results
        request.fetchLimit = 100

        // Use property-level fault optimization
        request.returnsObjectsAsFaults = false

        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Failed to search notes: \(error)")
            return []
        }
    }
}
