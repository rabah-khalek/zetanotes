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
class AutocompleteService {
    private let llmService: LLMInferenceService
    private var debounceTimer: Timer?
    private let debounceDelay: TimeInterval = 0.2 // 200ms debounce

    // MARK: - Configuration

    private struct Config {
        static let minCharacters = 10 // Minimum characters before suggesting
        static let maxTokens: Int = 20 // Maximum tokens to generate
        static let temperature: Float = 0.3 // Lower temperature for more deterministic suggestions
    }

    // MARK: - Initialization

    init(llmService: LLMInferenceService) {
        self.llmService = llmService
    }

    // MARK: - Autocomplete

    /// Generates an autocomplete suggestion for the given text
    /// - Parameters:
    ///   - text: The current text content
    ///   - maxTokens: Maximum tokens to generate
    /// - Returns: Suggested completion text, or nil if no suggestion
    func generateSuggestion(for text: String, maxTokens: Int = Config.maxTokens) async -> String? {
        // Don't suggest if text is too short
        guard text.count >= Config.minCharacters else { return nil }

        // Get the last 100 characters for context (more efficient)
        let contextLength = min(text.count, 500)
        let startIndex = text.index(text.endIndex, offsetBy: -contextLength)
        let context = String(text[startIndex...])

        // Build prompt for autocomplete
        let prompt = buildAutocompletePrompt(context: context)

        // Generate completion
        guard let completion = await llmService.generate(
            prompt: prompt,
            maxTokens: maxTokens,
            temperature: Config.temperature,
            stopSequences: ["\n\n", "###"]
        ) else {
            return nil
        }

        return cleanCompletion(completion)
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

    // MARK: - Prompt Engineering

    private func buildAutocompletePrompt(context: String) -> String {
        return """
        \(context)

        Continue naturally:
        """
    }

    private func cleanCompletion(_ completion: String) -> String {
        // No postprocessing - return raw output
        return completion
    }

    // MARK: - Cleanup

    func cancelPendingSuggestion() {
        debounceTimer?.invalidate()
        debounceTimer = nil
    }
}
