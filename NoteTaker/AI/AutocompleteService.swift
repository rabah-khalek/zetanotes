//
//  AutocompleteService.swift
//  NoteTaker
//
//  Real-time autocomplete suggestions while typing
//  Implements debouncing to avoid excessive inference calls
//

import Foundation
import Combine

/// Service providing intelligent autocomplete suggestions
/// Uses debouncing to ensure smooth, non-blocking experience
class AutocompleteService: AIService {
    let llmService: LLMInferenceService
    let config: AIGenerationConfig

    private var debounceTimer: Timer?
    private let debounceDelay: TimeInterval = 0.2 // 200ms debounce

    // MARK: - Configuration

    private struct Config {
        static let minCharacters = 10 // Minimum characters before suggesting
        static let maxTokens: Int = 20 // Maximum tokens to generate
        static let contextLength = 500 // Characters of context to use
    }

    // MARK: - Initialization

    init(llmService: LLMInferenceService) {
        self.llmService = llmService
        self.config = AIGenerationConfig(
            temperature: 0.3,
            maxTokens: Config.maxTokens,
            stopSequences: ["\n\n"]  // Stop at paragraph breaks
        )
    }

    // MARK: - AIService Protocol

    func buildPrompt(for text: String) -> String {
        // Get the last N characters for context
        let contextLength = min(text.count, Config.contextLength)
        let startIndex = text.index(text.endIndex, offsetBy: -contextLength)
        let context = String(text[startIndex...])

        // For autocomplete, we want natural continuation
        // Keep it simple - just provide context
        return """
        Continue the following text naturally. Write only the next few words that would logically follow.

        \(context)
        """
    }

    // MARK: - Autocomplete

    /// Generates an autocomplete suggestion for the given text
    /// - Parameter text: The current text content
    /// - Returns: Suggested completion text, or nil if no suggestion
    func generateSuggestion(for text: String) async -> String? {
        // Don't suggest if text is too short
        guard text.count >= Config.minCharacters else { return nil }

        return await process(text)
    }

    /// Generates autocomplete with debouncing
    /// Returns a publisher that emits suggestions after debounce period
    /// - Parameter text: The text to complete
    /// - Returns: Publisher emitting optional suggestion
    func debouncedSuggestion(for text: String) -> AnyPublisher<String?, Never> {
        return Future<String?, Never> { [weak self] promise in
            self?.debounceTimer?.invalidate()

            self?.debounceTimer = Timer.scheduledTimer(withTimeInterval: self?.debounceDelay ?? 0.2, repeats: false) { _ in
                Task {
                    let suggestion = await self?.generateSuggestion(for: text)
                    promise(.success(suggestion))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Cleanup

    func cancelPendingSuggestion() {
        debounceTimer?.invalidate()
        debounceTimer = nil
    }
}
