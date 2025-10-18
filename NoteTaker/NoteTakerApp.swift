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
    @AppStorage("preferredAppearance") private var preferredAppearance: String = "light"

    init() {
        // Setup memory pressure monitoring
        setupMemoryPressureHandler()

        // Configure vector cache limits
        NoteEmbedding.configureVectorCache()
    }

    private func setupMemoryPressureHandler() {
        // Monitor memory warnings (macOS doesn't have UIApplication memory warnings,
        // but we can handle this proactively)
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("MemoryWarning"),
            object: nil,
            queue: .main
        ) { _ in
            print("⚠️ Memory pressure detected, clearing caches...")
            NoteEmbedding.clearVectorCache()
        }
    }

    var body: some Scene {
        WindowGroup {
            CustomWindowContainer {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(aiEngine)
                    .frame(minWidth: 800, minHeight: 600)
                    .preferredColorScheme(colorScheme)
            }
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
    static let toggleChat = Notification.Name("toggleChat")
}
