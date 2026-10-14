//
//  DataExportManager.swift
//  ZetaNotes
//
//  Manages user data export functionality
//

import CoreData
import Foundation

// MARK: - DateFormatter Extension

extension DateFormatter {
    static let timestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        return formatter
    }()
}

// MARK: - DataExportManager

@MainActor
class DataExportManager: ObservableObject {
    static let shared = DataExportManager()

    @Published var isExporting = false
    @Published var exportProgress: Double = 0.0
    @Published var exportStatus = ""

    private init() {}

    /// Exports all user data to a folder structure
    /// - Parameter destinationURL: The destination URL for the export folder
    /// - Returns: True if export was successful
    func exportAllData(to destinationURL: URL) async -> Bool {
        isExporting = true
        exportProgress = 0.0
        exportStatus = "Preparing export..."

        do {
            // Create export directory
            let exportDir = destinationURL
                .appendingPathComponent("ZetaNotes-Export-\(DateFormatter.timestamp.string(from: Date()))")
            try FileManager.default.createDirectory(at: exportDir, withIntermediateDirectories: true, attributes: nil)

            exportStatus = "Exporting notes..."
            exportProgress = 0.2

            // Export notes database
            try await exportNotesDatabase(to: exportDir)

            exportStatus = "Exporting chat history..."
            exportProgress = 0.4

            // Export chat history
            try exportChatHistory(to: exportDir)

            exportStatus = "Exporting settings..."
            exportProgress = 0.6

            // Export settings and preferences
            try exportSettings(to: exportDir)

            exportStatus = "Exporting AI models list..."
            exportProgress = 0.7

            // Export AI models information
            try exportModelsInfo(to: exportDir)

            exportStatus = "Creating export metadata..."
            exportProgress = 0.9

            // Create metadata file
            try createExportMetadata(in: exportDir)

            // Create README file
            try createReadmeFile(in: exportDir)

            exportStatus = "Export completed successfully!"
            exportProgress = 1.0

            // Reset status after delay
            Task {
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                self.isExporting = false
                self.exportProgress = 0.0
                self.exportStatus = ""
            }

            print("Export completed successfully to: \(exportDir.path)")
            return true

        } catch {
            exportStatus = "Export failed: \(error.localizedDescription)"

            Task {
                try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                self.isExporting = false
                self.exportProgress = 0.0
                self.exportStatus = ""
            }

            print("Export failed: \(error)")
            return false
        }
    }

    // MARK: - Export Functions

    private func exportNotesDatabase(to exportDir: URL) async throws {
        let notesExportURL = exportDir.appendingPathComponent("notes.json")

        // Get notes data from Core Data in background
        let exportData = try await withCheckedThrowingContinuation { continuation in
            let context = PersistenceController.shared.container.newBackgroundContext()
            context.perform {
                do {
                    let request: NSFetchRequest<Note> = Note.fetchRequest()
                    request.sortDescriptors = [NSSortDescriptor(keyPath: \Note.updatedAt, ascending: false)]
                    let fetchedNotes = try context.fetch(request)

                    // Convert to export data while still in the context
                    let data = fetchedNotes.map { note in
                        return [
                            "id": note.id?.uuidString ?? "",
                            "title": note.title ?? "",
                            "content": note.content ?? "",
                            "createdAt": Self.iso8601Formatter.string(from: note.createdAt ?? Date()),
                            "updatedAt": Self.iso8601Formatter.string(from: note.updatedAt ?? Date())
                        ]
                    }

                    continuation.resume(returning: data)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }

        let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        try jsonData.write(to: notesExportURL)

        print("Exported \(exportData.count) notes")
    }

    private func exportChatHistory(to exportDir: URL) throws {
        let chatManager = ChatManager.shared
        let chatExportURL = exportDir.appendingPathComponent("chat_history.json")

        let chatData = [
            "messages": chatManager.messages.map { message in
                [
                    "role": message.role.rawValue,
                    "content": message.content,
                    "timestamp": Self.iso8601Formatter.string(from: message.timestamp)
                ]
            },
            "settings": [
                "temperature": chatManager.settings.temperature,
                "maxTokens": chatManager.settings.maxTokens,
                "topP": chatManager.settings.topP,
                "topK": chatManager.settings.topK,
                "repeatPenalty": chatManager.settings.repeatPenalty,
                "systemPrompt": chatManager.settings.systemPrompt
            ]
        ] as [String: Any]

        let jsonData = try JSONSerialization.data(withJSONObject: chatData, options: .prettyPrinted)
        try jsonData.write(to: chatExportURL)

        print("Exported chat history with \(chatManager.messages.count) messages")
    }

    private func exportSettings(to exportDir: URL) throws {
        let settingsExportURL = exportDir.appendingPathComponent("settings.json")

        // Export relevant UserDefaults
        let userDefaults = UserDefaults.standard
        let settingsData = [
            "preferredAppearance": userDefaults.string(forKey: "preferredAppearance") ?? "dark",
            "hasCompletedFirstRun": userDefaults.bool(forKey: "hasCompletedFirstRun"),
            "selectedModelIdentifier": userDefaults.string(forKey: "selectedModelIdentifier") ?? "",
            "chatSettings": userDefaults.data(forKey: "chatSettings")?.base64EncodedString() ?? "",
            "autocompleteLlmConfigData": userDefaults.data(forKey: "autocompleteLlmConfigData")?
                .base64EncodedString() ?? "",
            "summarizationPrompt": userDefaults.string(forKey: "summarizationPrompt") ?? "",
            "translationPrompt": userDefaults.string(forKey: "translationPrompt") ?? "",
            "titleGenerationPrompt": userDefaults.string(forKey: "titleGenerationPrompt") ?? "",
            "autoCorrectPrompt": userDefaults.string(forKey: "autoCorrectPrompt") ?? "",
            "reformulatePrompt": userDefaults.string(forKey: "reformulatePrompt") ?? "",
            "targetLanguage": userDefaults.string(forKey: "targetLanguage") ?? "Spanish"
        ] as [String: Any]

        let jsonData = try JSONSerialization.data(withJSONObject: settingsData, options: .prettyPrinted)
        try jsonData.write(to: settingsExportURL)

        print("Exported user settings")
    }

    private func exportModelsInfo(to exportDir: URL) throws {
        let modelsExportURL = exportDir.appendingPathComponent("models_info.json")

        // Get information about downloaded models
        let fileManager = FileManager.default
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw ExportError.fileSystemError("Could not access Application Support directory")
        }

        let modelsDir = appSupport.appendingPathComponent("ZetaNotes/Models")
        var modelFiles: [[String: Any]] = []

        if fileManager.fileExists(atPath: modelsDir.path) {
            let contents = try fileManager.contentsOfDirectory(
                at: modelsDir,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )

            for modelFile in contents {
                modelFiles.append([
                    "filename": modelFile.lastPathComponent,
                    "path": modelFile.path
                ])
            }
        }

        let modelsData = [
            "downloadedModels": modelFiles,
            "selectedModel": AIEngine.shared.selectedModel.rawValue,
            "note": "Model files are not included in export due to their large size. " +
                "You can re-download them from AI Settings."
        ] as [String: Any]

        let jsonData = try JSONSerialization.data(withJSONObject: modelsData, options: .prettyPrinted)
        try jsonData.write(to: modelsExportURL)

        print("Exported models information for \(modelFiles.count) models")
    }

    private func createExportMetadata(in exportDir: URL) throws {
        let metadataURL = exportDir.appendingPathComponent("export_metadata.json")

        let metadata = [
            "exportedAt": Self.iso8601Formatter.string(from: Date()),
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            "buildNumber": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown",
            "platform": "macOS",
            "exportVersion": "1.0",
            "description": "ZetaNotes user data export containing notes, chat history, " +
                "settings, and AI models information."
        ] as [String: Any]

        let jsonData = try JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted)
        try jsonData.write(to: metadataURL)

        print("Created export metadata")
    }

    private func createReadmeFile(in exportDir: URL) throws {
        let readmeURL = exportDir.appendingPathComponent("README.txt")

        let readmeContent = """
        ZetaNotes Data Export
        ====================

        This folder contains an export of your ZetaNotes data.

        Files included:
        - notes.json: All your notes in JSON format
        - chat_history.json: Chat conversation history and settings
        - settings.json: App preferences and AI prompts
        - models_info.json: Information about downloaded AI models
        - export_metadata.json: Export information and app version

        Notes:
        - AI model files are not included due to their large size
        - You can re-download AI models from the AI Settings in ZetaNotes
        - This export is in human-readable JSON format
        - To import this data, use the import feature in ZetaNotes settings

        Export created: \(DateFormatter.timestamp.string(from: Date()))
        ZetaNotes version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
        """

        try readmeContent.write(to: readmeURL, atomically: true, encoding: .utf8)

        print("Created README file")
    }

    // MARK: - Formatters

    private nonisolated(unsafe) static let iso8601Formatter = ISO8601DateFormatter()
}

// MARK: - Export Errors

extension DataExportManager {
    enum ExportError: LocalizedError {
        case noData
        case fileSystemError(String)

        var errorDescription: String? {
            switch self {
            case .noData:
                return "No data available to export"
            case let .fileSystemError(message):
                return "File system error: \(message)"
            }
        }
    }
}
