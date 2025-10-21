//
//  ZetaNotesApp.swift
//  ZetaNotes
//
//  AI-Powered Note Taking App for macOS
//  Optimized for Apple Silicon (M1/M2/M3)
//

import AppKit
import Sparkle
import SwiftUI

// MARK: - AppDelegate for macOS-specific lifecycle events

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        // This is called when the app is about to quit (Cmd+Q or Quit from menu)
        print("🛑 App terminating - performing final save...")

        // Force save any pending Core Data changes
        let context = PersistenceController.shared.container.viewContext
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Final save completed successfully")
            } catch {
                print("❌ Failed to save on termination: \(error)")
                // Log error but don't crash during termination
                ErrorLogger.shared.logError(
                    "Failed to save notes during app termination",
                    severity: .error,
                    operation: "App Quit",
                    details: error.localizedDescription
                )
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Standard macOS behavior - quit when last window closes
        return true
    }
}

@main
struct ZetaNotesApp: App {
    // Register AppDelegate for macOS lifecycle events
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    // Sparkle updater controller - handles automatic updates
    private let updaterController: SPUStandardUpdaterController

    // Persistence controller manages Core Data stack
    @StateObject private var persistenceController = PersistenceController.shared

    // AI Engine singleton - loads TinyLlama model on first access
    @StateObject private var aiEngine = AIEngine.shared

    // License Manager - handles Pro features
    @StateObject private var licenseManager = LicenseManager.shared

    // Appearance preference
    @AppStorage("preferredAppearance") private var preferredAppearance: String = "dark"

    // First-run state
    @AppStorage("hasCompletedFirstRun") private var hasCompletedFirstRun = false

    // Scene phase for lifecycle monitoring
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Initialize Sparkle updater controller
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

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
                if hasCompletedFirstRun {
                    ContentView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .environmentObject(aiEngine)
                        .frame(minWidth: AppTheme.Layout.minWindowWidth, minHeight: AppTheme.Layout.minWindowHeight)
                        .preferredColorScheme(colorScheme)
                } else {
                    FirstRunModelSetupView()
                        .environmentObject(aiEngine)
                        .frame(minWidth: AppTheme.Layout.minWindowWidth, minHeight: AppTheme.Layout.minWindowHeight)
                        .preferredColorScheme(colorScheme)
                }
            }
        }
        .defaultSize(width: AppTheme.Layout.defaultWindowWidth, height: AppTheme.Layout.defaultWindowHeight)
        .windowResizability(.contentMinSize)
        .commands {
            // Add custom menu commands
            CommandGroup(replacing: .newItem) {
                Button("New Note") {
                    NotificationCenter.default.post(name: .createNewNote, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            // Add Sparkle's Check for Updates menu item
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .onChange(of: scenePhase) { newPhase in
            handleScenePhaseChange(to: newPhase)
        }
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

    // MARK: - Lifecycle Handling

    private func handleScenePhaseChange(to newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            // App is moving to background (minimized or hidden)
            // Save any pending changes
            print("📱 App entering background - saving pending changes...")
            saveAllPendingChanges()

        case .inactive:
            // App is becoming inactive (user switching apps, Cmd+Tab, etc.)
            // Good time to save as well
            print("⏸️ App becoming inactive - saving pending changes...")
            saveAllPendingChanges()

        case .active:
            // App is active and in foreground
            print("✅ App is active")

        @unknown default:
            break
        }
    }

    private func saveAllPendingChanges() {
        // Immediately flush any pending debounced saves by triggering them now
        // This ensures the view context is up-to-date before we save

        // Save Core Data context if there are any unsaved changes
        if persistenceController.container.viewContext.hasChanges {
            print("💾 Saving Core Data changes to disk...")
            persistenceController.save()
            print("✅ Core Data saved successfully")
        } else {
            print("ℹ️ No unsaved changes to persist")
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
