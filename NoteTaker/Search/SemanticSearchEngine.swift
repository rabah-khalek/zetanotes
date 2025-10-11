//
//  SemanticSearchEngine.swift
//  NoteTaker
//
//  Semantic search using embedding similarity
//  Lightweight implementation without external dependencies
//

import Foundation
import CoreData

/// Search engine for finding semantically similar notes
/// Uses cosine similarity on cached embeddings for fast retrieval
class SemanticSearchEngine {
    private let embeddingService: EmbeddingService
    private let persistenceController: PersistenceController

    // MARK: - Configuration

    private struct Config {
        static let defaultResultLimit = 10
        static let minimumSimilarityThreshold: Float = 0.5
    }

    // MARK: - Initialization

    init(embeddingService: EmbeddingService, persistenceController: PersistenceController) {
        self.embeddingService = embeddingService
        self.persistenceController = persistenceController
    }

    // MARK: - Search

    /// Performs semantic search across all notes
    /// - Parameters:
    ///   - query: The search query string
    ///   - limit: Maximum number of results to return
    ///   - threshold: Minimum similarity threshold (0-1)
    /// - Returns: Array of search results sorted by relevance
    func search(query: String, limit: Int = Config.defaultResultLimit, threshold: Float = Config.minimumSimilarityThreshold) async -> [SearchResult] {
        // Generate query embedding
        guard let queryEmbedding = await embeddingService.generateEmbedding(for: query) else {
            print("⚠️ Failed to generate query embedding")
            return []
        }

        // Fetch all notes with embeddings
        let notes = await fetchNotesWithEmbeddings()

        // Compute similarities
        var results: [SearchResult] = []

        for note in notes {
            guard let embedding = note.embedding, let noteVector = embedding.vector else {
                continue
            }

            let similarity = embeddingService.cosineSimilarity(queryEmbedding, noteVector)

            if similarity >= threshold {
                results.append(SearchResult(note: note, similarity: similarity))
            }
        }

        // Sort by similarity (descending) and limit results
        results.sort { $0.similarity > $1.similarity }
        return Array(results.prefix(limit))
    }

    /// Finds notes similar to a given note
    /// - Parameters:
    ///   - note: The reference note
    ///   - limit: Maximum number of results
    /// - Returns: Array of similar notes
    func findSimilarNotes(to note: Note, limit: Int = 5) async -> [SearchResult] {
        guard let embedding = note.embedding, let noteVector = embedding.vector else {
            print("⚠️ Note has no embedding")
            return []
        }

        let allNotes = await fetchNotesWithEmbeddings()

        var results: [SearchResult] = []

        for otherNote in allNotes {
            // Skip the same note
            guard otherNote.id != note.id else { continue }

            guard let otherEmbedding = otherNote.embedding, let otherVector = otherEmbedding.vector else {
                continue
            }

            let similarity = embeddingService.cosineSimilarity(noteVector, otherVector)

            if similarity >= Config.minimumSimilarityThreshold {
                results.append(SearchResult(note: otherNote, similarity: similarity))
            }
        }

        results.sort { $0.similarity > $1.similarity }
        return Array(results.prefix(limit))
    }

    // MARK: - Hybrid Search

    /// Combines keyword search with semantic search for best results
    /// - Parameters:
    ///   - query: The search query
    ///   - limit: Maximum results to return
    /// - Returns: Combined and ranked search results
    func hybridSearch(query: String, limit: Int = Config.defaultResultLimit) async -> [SearchResult] {
        // Perform both searches in parallel
        async let semanticResults = search(query: query, limit: limit * 2)
        async let keywordNotes = performKeywordSearch(query: query)

        let semantic = await semanticResults
        let keyword = await keywordNotes

        // Combine results with scoring
        var scoreMap: [UUID: Float] = [:]

        // Semantic results get their similarity score
        for result in semantic {
            guard let noteId = result.note.id else { continue }
            scoreMap[noteId] = result.similarity
        }

        // Keyword matches get a boost
        for note in keyword {
            guard let noteId = note.id else { continue }

            if let existingScore = scoreMap[noteId] {
                // Boost existing score
                scoreMap[noteId] = existingScore + 0.2
            } else {
                // Add with base score
                scoreMap[noteId] = 0.3
            }
        }

        // Convert back to SearchResults
        var combined: [SearchResult] = []
        let allNotes = semantic.map { $0.note } + keyword

        let uniqueNotes = Dictionary(grouping: allNotes, by: { $0.id })
            .compactMapValues { $0.first }
            .values

        for note in uniqueNotes {
            guard let noteId = note.id, let score = scoreMap[noteId] else { continue }
            combined.append(SearchResult(note: note, similarity: score))
        }

        // Sort and limit
        combined.sort { $0.similarity > $1.similarity }
        return Array(combined.prefix(limit))
    }

    // MARK: - Indexing

    /// Ensures all notes have embeddings generated
    /// Call this periodically or after bulk imports
    func indexAllNotes() async {
        let context = persistenceController.newBackgroundContext()

        await context.perform {
            let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "embedding == nil")

            do {
                let notesWithoutEmbeddings = try context.fetch(fetchRequest)

                if !notesWithoutEmbeddings.isEmpty {
                    print("🔄 Indexing \(notesWithoutEmbeddings.count) notes...")
                    Task {
                        await self.embeddingService.batchGenerateEmbeddings(for: notesWithoutEmbeddings, in: context)
                    }
                }
            } catch {
                print("❌ Failed to fetch notes for indexing: \(error)")
            }
        }
    }

    /// Updates the embedding for a specific note
    /// - Parameter note: The note to reindex
    func reindexNote(_ note: Note) async {
        let context = persistenceController.newBackgroundContext()

        // Get the note in the background context
        guard let noteId = note.objectID as? NSManagedObjectID else { return }

        await context.perform {
            do {
                let bgNote = try context.existingObject(with: noteId) as? Note
                if let bgNote = bgNote {
                    Task {
                        await self.embeddingService.generateAndStoreEmbedding(for: bgNote, in: context)
                    }
                }
            } catch {
                print("❌ Failed to reindex note: \(error)")
            }
        }
    }

    // MARK: - Private Helpers

    private func fetchNotesWithEmbeddings() async -> [Note] {
        return await withCheckedContinuation { continuation in
            let context = persistenceController.container.viewContext

            context.perform {
                let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "embedding != nil")
                fetchRequest.relationshipKeyPathsForPrefetching = ["embedding"]

                do {
                    let notes = try context.fetch(fetchRequest)
                    continuation.resume(returning: notes)
                } catch {
                    print("❌ Failed to fetch notes with embeddings: \(error)")
                    continuation.resume(returning: [])
                }
            }
        }
    }

    private func performKeywordSearch(query: String) async -> [Note] {
        return await withCheckedContinuation { continuation in
            let context = persistenceController.container.viewContext

            context.perform {
                let notes = self.persistenceController.searchNotes(query: query)
                continuation.resume(returning: notes)
            }
        }
    }
}

// MARK: - Search Result

/// Represents a search result with relevance score
struct SearchResult: Identifiable {
    let note: Note
    let similarity: Float

    var id: UUID {
        note.id ?? UUID()
    }

    /// Relevance score as a percentage
    var relevancePercentage: Int {
        return Int(similarity * 100)
    }

    /// Human-readable relevance description
    var relevanceDescription: String {
        switch similarity {
        case 0.9...1.0:
            return "Highly relevant"
        case 0.7..<0.9:
            return "Very relevant"
        case 0.5..<0.7:
            return "Relevant"
        default:
            return "Somewhat relevant"
        }
    }
}
