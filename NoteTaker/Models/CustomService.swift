//
//  CustomService.swift
//  NoteTaker
//
//  Custom AI services configurable by Pro users
//

import Foundation
import SwiftUI

/// Represents a custom AI service with user-defined prompt and keyboard shortcut
struct CustomService: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var icon: String
    var prompt: String
    var keyboardShortcut: String // Single character (e.g., "K", "L", "M")
    var color: ServiceColor
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        icon: String = "star.fill",
        prompt: String = "",
        keyboardShortcut: String = "",
        color: ServiceColor = .purple,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.prompt = prompt
        self.keyboardShortcut = keyboardShortcut
        self.color = color
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    mutating func touch() {
        modifiedAt = Date()
    }
}

/// Color options for custom services
enum ServiceColor: String, Codable, CaseIterable {
    case blue, green, orange, pink, purple, red, yellow, teal, indigo

    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .pink: return .pink
        case .purple: return .purple
        case .red: return .red
        case .yellow: return .yellow
        case .teal: return .teal
        case .indigo: return .indigo
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}

/// Manager for custom services persistence
class CustomServiceManager: ObservableObject {
    static let shared = CustomServiceManager()

    @Published var services: [CustomService] = []

    private let storageKey = "customServices"
    private let maxServices = 10

    private init() {
        loadServices()
    }

    func loadServices() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([CustomService].self, from: data) else {
            services = []
            return
        }
        services = decoded
    }

    func saveServices() {
        guard let encoded = try? JSONEncoder().encode(services) else {
            print("❌ Failed to encode custom services")
            return
        }
        UserDefaults.standard.set(encoded, forKey: storageKey)
        print("✅ Saved \(services.count) custom services")
    }

    func addService(_ service: CustomService) {
        guard services.count < maxServices else {
            print("⚠️ Maximum number of custom services reached")
            return
        }
        services.append(service)
        saveServices()
    }

    func updateService(_ service: CustomService) {
        if let index = services.firstIndex(where: { $0.id == service.id }) {
            services[index] = service
            saveServices()
        }
    }

    func deleteService(_ service: CustomService) {
        services.removeAll { $0.id == service.id }
        saveServices()
    }

    func canAddService() -> Bool {
        return services.count < maxServices
    }

    /// Check if a keyboard shortcut is already in use
    func isShortcutAvailable(_ shortcut: String, excluding serviceId: UUID? = nil) -> Bool {
        let normalizedShortcut = shortcut.uppercased()

        // Check against built-in shortcuts
        let reservedShortcuts = ["P", "R", "S", "T", "N"] // Patch, Rephrase, Summarize, Translate, New Note
        if reservedShortcuts.contains(normalizedShortcut) {
            return false
        }

        // Check against other custom services
        return !services.contains { service in
            service.keyboardShortcut.uppercased() == normalizedShortcut &&
            service.id != serviceId
        }
    }
}
