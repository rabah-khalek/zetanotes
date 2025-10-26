//
//  ChatSettings.swift
//  ZetaNotes
//
//  Chat-specific AI parameters and settings
//

import Foundation

struct ChatSettings: Codable {
    var temperature: Double
    var maxTokens: Int
    var topP: Double
    var topK: Int
    var repeatPenalty: Double
    var systemPrompt: String
    var generationTimeout: Double // Timeout in seconds for AI generation

    /// Default chat settings optimized for conversation
    static let `default` = ChatSettings(
        temperature: 0.7,
        maxTokens: 2048,
        topP: 0.95,
        topK: 40,
        repeatPenalty: 1.1,
        systemPrompt: "You are a helpful AI assistant. Provide clear, concise, and accurate responses.",
        generationTimeout: 10.0
    )

    /// Saves the current settings to UserDefaults
    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: "chatSettings")
        }
    }

    /// Loads settings from UserDefaults or returns default
    static func load() -> ChatSettings {
        if let data = UserDefaults.standard.data(forKey: "chatSettings"),
           var decoded = try? JSONDecoder().decode(ChatSettings.self, from: data) {
            // Ensure temperature is at least 0.01 to prevent crashes
            if decoded.temperature < 0.01 {
                decoded.temperature = 0.01
            }
            // Ensure timeout is reasonable (between 1 and 60 seconds)
            if decoded.generationTimeout < 1.0 || decoded.generationTimeout > 60.0 {
                decoded.generationTimeout = 10.0
            }
            return decoded
        }
        return .default
    }
}
