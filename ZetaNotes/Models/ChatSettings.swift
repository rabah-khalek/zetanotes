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
        systemPrompt: "Respond only with the requested output.",
        generationTimeout: 120.0  // 2 minutes - increased from 10s to prevent truncation
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

            var needsSave = false

            // Migration: Update old 10-60 second timeouts to new 120 second default
            // This fixes the "output cut short" issue for existing users
            if decoded.generationTimeout <= 60.0 {
                let oldTimeout = decoded.generationTimeout
                decoded.generationTimeout = 120.0
                print("⚠️ Migrated chat timeout from \(oldTimeout)s to 120s to prevent truncation")
                needsSave = true
            }

            // Ensure timeout is reasonable (between 1 and 300 seconds / 5 minutes)
            if decoded.generationTimeout < 1.0 || decoded.generationTimeout > 300.0 {
                decoded.generationTimeout = 120.0
                needsSave = true
            }

            // Save migrated settings
            if needsSave {
                decoded.save()
            }

            return decoded
        }
        return .default
    }
}
