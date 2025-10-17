//
//  ChatService.swift
//  NoteTaker
//
//  Handles streaming chat completions with conversation context
//

import Foundation

class ChatService {
    private let llmService: LLMInferenceService

    init(llmService: LLMInferenceService) {
        self.llmService = llmService
    }

    /// Generates a streaming chat response
    /// - Parameters:
    ///   - messages: The conversation history
    ///   - settings: Chat settings (temperature, max tokens, etc.)
    ///   - onToken: Callback for each generated token
    /// - Returns: The complete generated response
    func generateResponse(
        messages: [ChatMessage],
        settings: ChatSettings,
        onToken: @escaping (String) -> Void
    ) async -> String? {
        // Build the prompt from conversation history
        let prompt = buildPrompt(from: messages, systemPrompt: settings.systemPrompt)

        print("🤖 Generating chat response...")
        print("📊 Settings: temp=\(settings.temperature), maxTokens=\(settings.maxTokens)")

        // Generate with streaming via the LLM service
        // Note: The current LLMInferenceService doesn't expose token-by-token streaming
        // so we'll use the standard generate method and return the full response
        // For true streaming, we'd need to modify LLMInferenceService to expose a streaming API

        // Ensure temperature is at least 0.01 to avoid division by zero or sampling issues
        let safeTemperature = max(Float(settings.temperature), 0.01)

        let response = await llmService.generate(
            prompt: prompt,
            maxTokens: settings.maxTokens,
            temperature: safeTemperature,
            stopSequences: ["<|im_end|>", "</s>", "<|endoftext|>"]
        )

        // For now, we'll call onToken once with the full response
        // In a future enhancement, we could modify LLMInferenceService to support true token streaming
        if let response = response {
            onToken(response)
        }

        return response
    }

    /// Builds a chat prompt from conversation history
    /// Uses the ChatML format which is widely supported by instruction-tuned models
    private func buildPrompt(from messages: [ChatMessage], systemPrompt: String) -> String {
        var prompt = ""

        // Add system message
        prompt += "<|im_start|>system\n\(systemPrompt)<|im_end|>\n"

        // Add conversation history (limit to last 10 messages to fit context)
        let recentMessages = messages.suffix(10)
        for message in recentMessages {
            let role = message.role == .user ? "user" : "assistant"
            prompt += "<|im_start|>\(role)\n\(message.content)<|im_end|>\n"
        }

        // Add assistant prompt
        prompt += "<|im_start|>assistant\n"

        return prompt
    }

    /// Alternative prompt format for models that don't support ChatML
    private func buildAlternativePrompt(from messages: [ChatMessage], systemPrompt: String) -> String {
        var prompt = "\(systemPrompt)\n\n"

        // Add conversation history
        let recentMessages = messages.suffix(10)
        for message in recentMessages {
            if message.role == .user {
                prompt += "User: \(message.content)\n\n"
            } else if message.role == .assistant {
                prompt += "Assistant: \(message.content)\n\n"
            }
        }

        prompt += "Assistant:"

        return prompt
    }
}
