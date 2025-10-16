//
//  LicenseManager.swift
//  NoteTaker
//
//  Manages Pro license validation and feature access
//  Integrates with Gumroad for license key validation
//

import Foundation
import Security

/// Manages Pro license validation and feature access control
class LicenseManager: ObservableObject {
    static let shared = LicenseManager()

    // MARK: - Published Properties

    @Published var isPro: Bool = false
    @Published var licenseEmail: String?
    @Published var licenseKey: String?

    // MARK: - Constants

    private let keychainService = "com.notetaker.license"
    private let keychainAccount = "pro-license"

    // For development/testing
    #if DEBUG
    private let allowTestLicense = true
    private let testLicenseKey = "TEST"
    private let testLicenseEmail = "ADMIN"
    #endif

    // MARK: - Initialization

    private init() {
        loadLicenseFromKeychain()
    }

    // MARK: - License Validation

    /// Validates a license key with Gumroad
    /// - Parameters:
    ///   - key: The license key to validate
    ///   - email: The email associated with the purchase
    /// - Returns: True if license is valid
    func validateLicense(key: String, email: String) async -> Bool {
        // Clean up the key
        let cleanKey = key.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        #if DEBUG
        // Allow test license in debug mode
        print("🔍 DEBUG: Checking test credentials...")
        print("   Input key: '\(cleanKey)' (length: \(cleanKey.count))")
        print("   Expected key: '\(testLicenseKey)' (length: \(testLicenseKey.count))")
        print("   Keys match: \(cleanKey == testLicenseKey)")
        print("   Input email: '\(cleanEmail)' (length: \(cleanEmail.count))")
        print("   Expected email: '\(testLicenseEmail.lowercased())' (length: \(testLicenseEmail.lowercased().count))")
        print("   Emails match: \(cleanEmail == testLicenseEmail.lowercased())")
        print("   allowTestLicense: \(allowTestLicense)")

        if allowTestLicense && cleanKey == testLicenseKey && cleanEmail == testLicenseEmail.lowercased() {
            await saveLicense(key: cleanKey, email: cleanEmail)
            print("✅ Test license activated (DEV MODE)")
            return true
        } else if allowTestLicense {
            print("⚠️ Test credentials don't match - continuing to API validation")
        }
        #endif

        // Validate with LemonSqueezy API
        let isValid = await validateWithLemonSqueezy(key: cleanKey, email: cleanEmail)

        if isValid {
            await saveLicense(key: cleanKey, email: cleanEmail)
            print("✅ Pro license activated for \(cleanEmail)")
            // Note: Analytics tracking removed to avoid circular dependency
        } else {
            print("❌ Invalid license key attempted: \(cleanKey)")
            // Note: Analytics tracking removed to avoid circular dependency
        }

        return isValid
    }

    /// Validates license key with LemonSqueezy API
    private func validateWithLemonSqueezy(key: String, email: String) async -> Bool {
        // TODO: Replace with your actual Gumroad product permalink
        // Get this from: https://app.gumroad.com/products -> Your Product -> Settings
        let productPermalink = "notetaker-pro" // CHANGE THIS

        // Gumroad license verification endpoint
        let urlString = "https://api.gumroad.com/v2/licenses/verify"

        guard let url = URL(string: urlString) else {
            logError("Invalid Gumroad API URL")
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // Create form data
        let formData = [
            "product_permalink": productPermalink,
            "license_key": key,
            "increment_uses_count": "false" // Don't increment on validation
        ]

        let formString = formData.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = formString.data(using: .utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                logError("Invalid response from Gumroad")
                return false
            }

            if httpResponse.statusCode == 200 {
                // Parse response
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let success = json?["success"] as? Bool ?? false

                if success {
                    // Optionally check purchase data
                    if let purchase = json?["purchase"] as? [String: Any],
                       let purchaseEmail = purchase["email"] as? String {
                        // Verify email matches (case-insensitive)
                        if purchaseEmail.lowercased() == email.lowercased() {
                            return true
                        } else {
                            logWarning("Email mismatch: provided \(email), purchase \(purchaseEmail)")
                            return false
                        }
                    }
                    return true
                }
            }

            logWarning("Gumroad validation failed with status: \(httpResponse.statusCode)")
            return false

        } catch {
            logError("Failed to validate license: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - License Storage

    /// Saves license to Keychain
    @MainActor
    private func saveLicense(key: String, email: String) {
        // Save to Keychain
        let licenseData = "\(email):\(key)".data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: licenseData
        ]

        // Delete existing
        SecItemDelete(query as CFDictionary)

        // Add new
        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecSuccess {
            self.isPro = true
            self.licenseEmail = email
            self.licenseKey = key

            // Save to UserDefaults as backup
            UserDefaults.standard.set(true, forKey: "isProUser")
            UserDefaults.standard.set(email, forKey: "licenseEmail")

            logInfo("License saved successfully")
        } else {
            logError("Failed to save license to Keychain: \(status)")
        }
    }

    /// Loads license from Keychain
    private func loadLicenseFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess,
           let data = result as? Data,
           let licenseString = String(data: data, encoding: .utf8) {

            let components = licenseString.split(separator: ":")
            if components.count == 2 {
                DispatchQueue.main.async {
                    self.isPro = true
                    self.licenseEmail = String(components[0])
                    self.licenseKey = String(components[1])
                }
                logInfo("✅ Pro license loaded from Keychain")
            }
        } else {
            // Check UserDefaults backup
            if UserDefaults.standard.bool(forKey: "isProUser") {
                DispatchQueue.main.async {
                    self.isPro = true
                    self.licenseEmail = UserDefaults.standard.string(forKey: "licenseEmail")
                }
                logInfo("✅ Pro status loaded from UserDefaults")
            }
        }
    }

    /// Removes license (for testing or refunds)
    func removeLicense() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]

        SecItemDelete(query as CFDictionary)

        UserDefaults.standard.removeObject(forKey: "isProUser")
        UserDefaults.standard.removeObject(forKey: "licenseEmail")

        DispatchQueue.main.async {
            self.isPro = false
            self.licenseEmail = nil
            self.licenseKey = nil
        }

        logInfo("License removed")
        AnalyticsManager.shared.trackEvent(.licenseRemoved)
    }

    // MARK: - Feature Access

    /// Check if user has access to Pro features
    var hasProAccess: Bool {
        return isPro
    }

    /// Check if semantic search is available
    /// FREE: ✅ Available with TinyLlama
    /// PRO: ✅ Available with all models
    var canUseSemanticSearch: Bool {
        return true // Available in free tier
    }

    /// Check if advanced AI features are available (translation, grammar, reformulation)
    /// FREE: ✅ Available with TinyLlama
    /// PRO: ✅ Available with all models (better quality)
    var canUseAdvancedAI: Bool {
        return true // Available in free tier
    }

    /// Check if user can edit custom prompts
    /// FREE: ❌ Use default prompts only
    /// PRO: ✅ Customize all prompts
    var canEditPrompts: Bool {
        return isPro
    }

    /// Check if user can switch models
    /// FREE: ❌ TinyLlama only
    /// PRO: ✅ All models (Phi-3, Qwen, Llama 3.2, etc.)
    var canSwitchModels: Bool {
        return isPro
    }

    /// Get allowed models for current license
    var allowedModels: [AIModel] {
        if isPro {
            return AIModel.allCases
        } else {
            return [.tinyLlama] // Free tier only gets TinyLlama
        }
    }

    /// Check if a specific model is available
    func canUseModel(_ model: AIModel) -> Bool {
        return allowedModels.contains(model)
    }
}

// MARK: - Analytics Events Extension

extension AnalyticsManager.EventType {
    static let licenseActivated = EventType(rawValue: "license_activated")!
    static let licenseValidationFailed = EventType(rawValue: "license_validation_failed")!
    static let licenseRemoved = EventType(rawValue: "license_removed")!
    static let proFeatureBlocked = EventType(rawValue: "pro_feature_blocked")!
    static let upgradePromptShown = EventType(rawValue: "upgrade_prompt_shown")!
}

// MARK: - Analytics Helper

extension AnalyticsManager.EventType {
    init?(rawValue: String) {
        // Helper to create event types dynamically
        switch rawValue {
        case "license_activated": self = .appLaunch // placeholder
        case "license_validation_failed": self = .appLaunch
        case "license_removed": self = .appLaunch
        case "pro_feature_blocked": self = .appLaunch
        case "upgrade_prompt_shown": self = .appLaunch
        default: return nil
        }
    }
}
