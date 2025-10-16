//
//  NoteTakerApp.swift
//  NoteTaker
//
//  AI-Powered Note Taking App for macOS
//  Optimized for Apple Silicon (M1/M2/M3)
//

import SwiftUI

@main
struct NoteTakerApp: App {
    // Persistence controller manages Core Data stack
    @StateObject private var persistenceController = PersistenceController.shared

    // AI Engine singleton - loads TinyLlama model on first access
    @StateObject private var aiEngine = AIEngine.shared

    // License Manager - handles Pro features
    @StateObject private var licenseManager = LicenseManager.shared

    // Appearance preference
    @AppStorage("preferredAppearance") private var preferredAppearance: String = "auto"

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(aiEngine)
                .frame(minWidth: 800, minHeight: 600)
                .preferredColorScheme(colorScheme)
        }
        .commands {
            // Add custom menu commands
            CommandGroup(replacing: .newItem) {
                Button("New Note") {
                    NotificationCenter.default.post(name: .createNewNote, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
    }

    private var colorScheme: ColorScheme? {
        switch preferredAppearance {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil // Auto - follows system
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let createNewNote = Notification.Name("createNewNote")
    static let deleteNote = Notification.Name("deleteNote")
    static let triggerSearch = Notification.Name("triggerSearch")
    static let showUpgradePrompt = Notification.Name("showUpgradePrompt")
}
