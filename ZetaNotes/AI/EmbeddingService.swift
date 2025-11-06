//
//  EmbeddingService.swift
//  ZetaNotes
//
//  Generates and manages embeddings for semantic search
//  Uses TinyLlama to create dense vector representations
//

import CoreData
import Foundation

/// Service for generating text embeddings using the LLM
/// Embeddings enable semantic search across notes
final class EmbeddingService: @unchecked Sendable {
    private let llmService: LLMInferenceService
    // Embedding cache DISABLED - embeddings are already stored in CoreData
    // This saves ~1GB of memory fragmentation and SWAP usage

    // MARK: - Configuration

    private enum Config {
        static let embeddingDimensions = 2048 // TinyLlama embedding size
    }

    // MARK: - Initialization

    init(llmService: LLMInferenceService) {
        self.llmService = llmService
    }

    // MARK: - Embedding Generation

    /// Generates an embedding for the given text
    /// - Parameter text: The text to embed
    /// - Returns: Float array representing the embedding, or nil on failure
    func generateEmbedding(for text: String) async -> [Float]? {
        guard !text.isEmpty else { return nil }

        // Cache disabled - generate directly and rely on CoreData persistence
        // This significantly reduces memory usage
        guard let embedding = await llmService.generateEmbedding(for: text) else {
            return nil
        }

        return embedding
    }

    /// Generates and stores an embedding for a note
    /// - Parameter note: The note to generate an embedding for
    /// - Parameter context: The managed object context
    func generateAndStoreEmbedding(for note: Note, in context: NSManagedObjectContext) async {
        // Extract only base content (exclude AI-generated blocks)
        let baseContent = extractBaseContent(from: note.content ?? "")

        // Combine title and base content for embedding (limit to ~1500 chars = ~400 tokens)
        let combinedText = "\(note.title ?? "") \(baseContent)"
        let maxChars = 1500
        let textToEmbed = String(combinedText.prefix(maxChars))

        if combinedText.count > maxChars {
            print("⚠️ Content truncated to \(maxChars) chars for embedding generation")
        }

        guard let embedding = await generateEmbedding(for: textToEmbed) else {
            print("⚠️ Failed to generate embedding for note: \(note.id?.uuidString ?? "unknown")")
            return
        }

        // Store in Core Data
        let noteObjectID = note.objectID
        let embeddingToSave = embedding

        await context.perform {
            guard let noteInContext = try? context.existingObject(with: noteObjectID) as? Note else {
                print("❌ Failed to get note in context")
                return
            }

            let noteEmbedding: NoteEmbedding
            if let existing = noteInContext.embedding {
                noteEmbedding = existing
            } else {
                noteEmbedding = NoteEmbedding(context: context)
                noteEmbedding.id = UUID()
                noteEmbedding.note = noteInContext
            }

            noteEmbedding.setVector(embeddingToSave)
            noteEmbedding.version = 1

            do {
                try context.save()
            } catch {
                print("❌ Failed to save embedding: \(error)")
            }
        }
    }

    /// Batch generates embeddings for multiple notes
    /// - Parameters:
    ///   - notes: Array of notes to process
    ///   - context: Background context for Core Data operations
    func batchGenerateEmbeddings(for notes: [Note], in context: NSManagedObjectContext) async {
        print("🔄 Generating embeddings for \(notes.count) notes...")

        for (index, note) in notes.enumerated() {
            // Skip if embedding already exists and is current
            if note.embedding != nil {
                continue
            }

            await generateAndStoreEmbedding(for: note, in: context)

            // Progress logging
            if (index + 1) % 10 == 0 {
                print("   Processed \(index + 1)/\(notes.count) notes")
            }
        }

        print("✅ Embedding generation complete")
    }

    // MARK: - Similarity Computation

    /// Computes cosine similarity between two embeddings
    /// - Parameters:
    ///   - embedding1: First embedding vector
    ///   - embedding2: Second embedding vector
    /// - Returns: Similarity score between -1 and 1 (higher = more similar)
    func cosineSimilarity(_ embedding1: [Float], _ embedding2: [Float]) -> Float {
        guard embedding1.count == embedding2.count else { return 0 }

        var dotProduct: Float = 0
        var magnitude1: Float = 0
        var magnitude2: Float = 0

        for index in 0 ..< embedding1.count {
            dotProduct += embedding1[index] * embedding2[index]
            magnitude1 += embedding1[index] * embedding1[index]
            magnitude2 += embedding2[index] * embedding2[index]
        }

        let denominator = sqrt(magnitude1) * sqrt(magnitude2)
        return denominator > 0 ? dotProduct / denominator : 0
    }

    // MARK: - Utilities

    /// Extracts only the base content from a note, excluding all AI-generated blocks
    private func extractBaseContent(from content: String) -> String {
        // Define all AI-generated section markers (new format: #### ServiceName • timestamp)
        let markers = [
            "\n\n#### Summary",
            "\n\n#### Translation to ",
            "\n\n#### Patched",
            "\n\n#### Reformulated"
        ]

        // Find the earliest AI section marker
        var firstAIIndex: String.Index?

        for marker in markers {
            if let range = content.range(of: marker) {
                if firstAIIndex == nil || range.lowerBound < firstAIIndex! {
                    firstAIIndex = range.lowerBound
                }
            }
        }

        // Return only content before first AI section
        if let firstIndex = firstAIIndex {
            return String(content[..<firstIndex])
        }

        return content
    }

    private func floatArrayToData(_ array: [Float]) -> Data {
        return array.withUnsafeBytes { Data($0) }
    }

    private func dataToFloatArray(_ data: Data) -> [Float]? {
        guard data.count % MemoryLayout<Float>.stride == 0 else { return nil }

        let count = data.count / MemoryLayout<Float>.stride
        var array = [Float](repeating: 0, count: count)

        data.withUnsafeBytes { rawBufferPointer in
            let bufferPointer = rawBufferPointer.bindMemory(to: Float.self)
            array = Array(bufferPointer)
        }

        return array
    }

    /// Clears the embedding cache (no-op since cache is disabled)
    func clearCache() {
        // Cache disabled for memory savings - this is now a no-op
    }
}
