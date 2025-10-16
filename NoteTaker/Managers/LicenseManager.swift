//
//  LicenseManager.swift
//  OffNotes
//
//  Manages Pro license validation and feature access
//  Integrates with LemonSqueezy for license key validation
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

    /// Validates a license key with LemonSqueezy
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
        // DEV_TODO: Replace with your actual LemonSqueezy store ID and product ID
        // Get these from: https://app.lemonsqueezy.com/settings/api
        let storeId = "DEV_STORE_ID" // DEV_TODO: CHANGE THIS
        let productId = "DEV_PRODUCT_ID" // DEV_TODO: CHANGE THIS (optional, can validate without)

        // LemonSqueezy license activation endpoint
        let urlString = "https://api.lemonsqueezy.com/v1/licenses/activate"

        guard let url = URL(string: urlString) else {
            print("❌ Invalid LemonSqueezy API URL")
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Add timeout to prevent hanging
        request.timeoutInterval = 10

        // Create JSON payload
        let payload: [String: Any] = [
            "license_key": key,
            "instance_name": email // Use email as instance identifier
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            print("❌ Failed to create request payload")
            return false
        }

        request.httpBody = jsonData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response from LemonSqueezy")
                return false
            }

            print("📡 LemonSqueezy API response status: \(httpResponse.statusCode)")

            if httpResponse.statusCode == 200 {
                // Parse response
                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    print("❌ Failed to parse LemonSqueezy response")
                    return false
                }

                // LemonSqueezy returns { "activated": true, "license_key": {...} }
                let activated = json["activated"] as? Bool ?? false

                if activated {
                    // Check license key metadata
                    if let licenseData = json["license_key"] as? [String: Any] {
                        let status = licenseData["status"] as? String ?? ""

                        // Valid statuses: "active", "inactive", "expired", "disabled"
                        if status == "active" {
                            print("✅ License validated successfully")
                            return true
                        } else {
                            print("⚠️ License status: \(status)")
                            return false
                        }
                    }
                    return true
                }

                print("⚠️ License not activated")
                return false

            } else if httpResponse.statusCode == 422 {
                // Validation error (invalid key, expired, etc.)
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let errors = json["errors"] as? [[String: Any]] ?? []
                    for error in errors {
                        if let detail = error["detail"] as? String {
                            print("⚠️ LemonSqueezy error: \(detail)")
                        }
                    }
                }
                return false
            } else if httpResponse.statusCode == 404 {
                print("⚠️ LemonSqueezy API endpoint not found (check configuration)")
                return false
            }

            print("⚠️ LemonSqueezy validation failed with status: \(httpResponse.statusCode)")

            // Try to parse error message
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["message"] as? String {
                print("⚠️ Error message: \(message)")
            }

            return false

        } catch let error as NSError {
            print("❌ Failed to validate license: \(error.localizedDescription)")
            print("   Error domain: \(error.domain)")
            print("   Error code: \(error.code)")
            return false
        } catch {
            print("❌ Unexpected error: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - License Storage

    /// Saves license to Keychain
    private func saveLicense(key: String, email: String) async {
        // Save to Keychain (background thread is fine for Security framework)
        guard let licenseData = "\(email):\(key)".data(using: .utf8) else {
            print("❌ Failed to encode license data")
            return
        }

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
            // Update UI state on main thread
            await MainActor.run {
                self.isPro = true
                self.licenseEmail = email
                self.licenseKey = key
            }

            // Save to UserDefaults as backup
            UserDefaults.standard.set(true, forKey: "isProUser")
            UserDefaults.standard.set(email, forKey: "licenseEmail")

            print("✅ License saved successfully")
        } else {
            print("❌ Failed to save license to Keychain: \(status)")
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
                print("✅ Pro license loaded from Keychain")
            }
        } else {
            // Check UserDefaults backup
            if UserDefaults.standard.bool(forKey: "isProUser") {
                DispatchQueue.main.async {
                    self.isPro = true
                    self.licenseEmail = UserDefaults.standard.string(forKey: "licenseEmail")
                }
                print("✅ Pro status loaded from UserDefaults")
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

        print("✅ License removed")
        // Note: Analytics tracking removed to avoid circular dependency
    }

    #if DEBUG
    /// Deactivates Pro license (dev mode only)
    func deactivateLicense() {
        removeLicense()
        print("🔓 [DEV] Pro license deactivated")
    }
    #endif

    // MARK: - Feature Access Control

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
