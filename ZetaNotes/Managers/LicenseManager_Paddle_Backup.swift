//
//  LicenseManager_Paddle_Backup.swift
//  ZetaNotes
//
//  Manages Pro license validation and feature access
//  Integrates with Paddle for license key validation
//

import Foundation
import Security

/// Subscription tier options
enum SubscriptionTier: String, Codable {
    case free
    case monthly
    case annual
    case lifetime

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .monthly: return "Monthly"
        case .annual: return "Annual"
        case .lifetime: return "Lifetime"
        }
    }

    var price: String {
        switch self {
        case .free: return "$0"
        case .monthly: return "$0.99/month"
        case .annual: return "$6/year"
        case .lifetime: return "$20 one-time"
        }
    }
}

/// Manages Pro license validation and feature access control
class LicenseManager: ObservableObject {
    static let shared = LicenseManager()

    // MARK: - Published Properties

    @Published var isPro: Bool = false
    @Published var licenseEmail: String?
    @Published var licenseKey: String?
    @Published var subscriptionTier: SubscriptionTier = .free
    @Published var subscriptionExpiryDate: Date?

    // MARK: - Constants

    private let keychainService = "com.zetanotes.license"
    private let keychainAccount = "pro-license"

    // For development/testing and App Review builds
    #if DEBUG || APP_REVIEW_BUILD
    private let allowTestLicense = true
    private let testLicenseKey = "TEST"
    private let testLicenseEmail = "ADMIN"
    #endif

    // MARK: - Initialization

    private init() {
        loadLicenseFromKeychain()
    }

    // MARK: - License Validation

    /// Validates a license key with Paddle
    /// - Parameters:
    ///   - key: The license key to validate
    ///   - email: The email associated with the purchase
    /// - Returns: True if license is valid
    func validateLicense(key: String, email: String) async -> Bool {
        // Clean up the key
        let cleanKey = key.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        #if DEBUG || APP_REVIEW_BUILD
        // Allow test license in debug mode and App Review builds
        #if DEBUG
        print("🔍 DEBUG: Checking test credentials...")
        #else
        print("🔍 APP REVIEW BUILD: Test credentials enabled for Apple reviewers")
        #endif
        print("   Input key: '\(cleanKey)' (length: \(cleanKey.count))")
        print("   Expected key: '\(testLicenseKey)' (length: \(testLicenseKey.count))")
        print("   Keys match: \(cleanKey == testLicenseKey)")
        print("   Input email: '\(cleanEmail)' (length: \(cleanEmail.count))")
        print("   Expected email: '\(testLicenseEmail.lowercased())' (length: \(testLicenseEmail.lowercased().count))")
        print("   Emails match: \(cleanEmail == testLicenseEmail.lowercased())")
        print("   allowTestLicense: \(allowTestLicense)")

        if allowTestLicense && cleanKey == testLicenseKey && cleanEmail == testLicenseEmail.lowercased() {
            // Test license defaults to lifetime for easy testing
            await saveLicense(key: cleanKey, email: cleanEmail, tier: .lifetime, expiryDate: nil)
            #if DEBUG
            print("✅ Test license activated (DEV MODE - Lifetime)")
            #else
            print("✅ Test license activated (APP REVIEW BUILD - Lifetime)")
            #endif
            return true
        } else if allowTestLicense {
            print("⚠️ Test credentials don't match - continuing to API validation")
        }
        #endif

        // Validate with Paddle API
        let isValid = await validateWithPaddle(key: cleanKey, email: cleanEmail)

        if isValid {
            // Note: tier and expiry are extracted inside validateWithPaddle and saved there
            print("✅ Pro license activated for \(cleanEmail)")
            // Note: Analytics tracking removed to avoid circular dependency
        } else {
            print("❌ Invalid license key attempted: \(cleanKey)")
            // Note: Analytics tracking removed to avoid circular dependency
        }

        return isValid
    }

    /// Validates license key with Paddle API
    private func validateWithPaddle(key: String, email: String) async -> Bool {
        // DEV_TODO: Replace with your actual Paddle vendor ID and product ID
        // Get these from: https://vendors.paddle.com/authentication
        _ = "DEV_VENDOR_ID" // DEV_TODO: CHANGE THIS
        _ = "DEV_PRODUCT_ID" // DEV_TODO: CHANGE THIS (optional, can validate without)

        // Paddle license validation endpoint (using Paddle Classic API)
        let urlString = "https://vendors.paddle.com/api/2.0/product/validate_license"

        guard let url = URL(string: urlString) else {
            print("❌ Invalid Paddle API URL")
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Add timeout to prevent hanging
        request.timeoutInterval = 10

        // Create JSON payload for Paddle
        let payload: [String: Any] = [
            "license_code": key,
            "email": email // Use email for validation
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            print("❌ Failed to create request payload")
            return false
        }

        request.httpBody = jsonData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response from Paddle")
                return false
            }

            print("📡 Paddle API response status: \(httpResponse.statusCode)")

            if httpResponse.statusCode == 200 {
                // Parse response
                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    print("❌ Failed to parse Paddle response")
                    return false
                }

                // Paddle returns { "success": true, "response": {...} }
                let success = json["success"] as? Bool ?? false

                if success {
                    // Check license data
                    if let responseData = json["response"] as? [String: Any] {
                        let state = responseData["state"] as? String ?? ""

                        // Valid states: "active", "inactive", "expired", "trialing"
                        if state == "active" || state == "trialing" {
                            // Extract subscription info
                            let tier = extractSubscriptionTierFromPaddle(from: responseData)
                            let expiryDate = extractExpiryDateFromPaddle(from: responseData)

                            await saveLicense(key: key, email: email, tier: tier, expiryDate: expiryDate)

                            print("✅ License validated successfully - Tier: \(tier.displayName)")
                            return true
                        } else {
                            print("⚠️ License state: \(state)")
                            return false
                        }
                    }
                    return true
                }

                print("⚠️ License validation failed")
                return false

            } else if httpResponse.statusCode == 400 {
                // Validation error (invalid key, expired, etc.)
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let error = json["error"] as? [String: Any] ?? [:]
                    if let message = error["message"] as? String {
                        print("⚠️ Paddle error: \(message)")
                    }
                }
                return false
            } else if httpResponse.statusCode == 404 {
                print("⚠️ Paddle API endpoint not found (check configuration)")
                return false
            }

            print("⚠️ Paddle validation failed with status: \(httpResponse.statusCode)")

            // Try to parse error message
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
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

    // MARK: - Helper Methods

    /// Extract subscription tier from Paddle license metadata
    private func extractSubscriptionTierFromPaddle(from responseData: [String: Any]) -> SubscriptionTier {
        // Check product_name or subscription info for tier
        if let productName = responseData["product_name"] as? String {
            let lowercased = productName.lowercased()
            if lowercased.contains("monthly") {
                return .monthly
            } else if lowercased.contains("annual") || lowercased.contains("yearly") {
                return .annual
            } else if lowercased.contains("lifetime") {
                return .lifetime
            }
        }

        // Check subscription info if available
        if let subscription = responseData["subscription"] as? [String: Any],
           let plan = subscription["plan"] as? String {
            let lowercased = plan.lowercased()
            if lowercased.contains("monthly") {
                return .monthly
            } else if lowercased.contains("annual") || lowercased.contains("yearly") {
                return .annual
            } else if lowercased.contains("lifetime") {
                return .lifetime
            }
        }

        // Default to lifetime for backwards compatibility
        return .lifetime
    }

    /// Extract expiry date from Paddle license metadata
    private func extractExpiryDateFromPaddle(from responseData: [String: Any]) -> Date? {
        // Check for expiry date in response
        if let expiryTimestamp = responseData["expires"] as? TimeInterval, expiryTimestamp > 0 {
            return Date(timeIntervalSince1970: expiryTimestamp)
        }

        // Check subscription expiry
        if let subscription = responseData["subscription"] as? [String: Any],
           let nextBillDate = subscription["next_bill_date"] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.date(from: nextBillDate)
        }

        // For lifetime licenses, no expiry
        return nil
    }

    /// Extract subscription tier from license metadata (legacy LemonSqueezy)
    private func extractSubscriptionTier(from licenseData: [String: Any]) -> SubscriptionTier {
        // Check meta or variant_name for subscription info
        if let meta = licenseData["meta"] as? [String: Any],
           let variantName = meta["variant_name"] as? String {
            let lowercased = variantName.lowercased()
            if lowercased.contains("monthly") {
                return .monthly
            } else if lowercased.contains("annual") || lowercased.contains("yearly") {
                return .annual
            } else if lowercased.contains("lifetime") {
                return .lifetime
            }
        }

        // Default to lifetime for backwards compatibility
        return .lifetime
    }

    /// Extract expiry date from license metadata
    private func extractExpiryDate(from licenseData: [String: Any]) -> Date? {
        // Check for expiry date in metadata
        if let meta = licenseData["meta"] as? [String: Any],
           let expiresAtString = meta["expires_at"] as? String {
            let formatter = ISO8601DateFormatter()
            return formatter.date(from: expiresAtString)
        }

        // For lifetime licenses, no expiry
        return nil
    }

    // MARK: - License Storage

    /// Saves license to Keychain
    private func saveLicense(
        key: String,
        email: String,
        tier: SubscriptionTier = .lifetime,
        expiryDate: Date? = nil
    ) async {
        // Create license data with tier and expiry
        var licenseDict: [String: String] = [
            "email": email,
            "key": key,
            "tier": tier.rawValue
        ]

        if let expiry = expiryDate {
            licenseDict["expiry"] = ISO8601DateFormatter().string(from: expiry)
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: licenseDict),
              let jsonString = String(data: jsonData, encoding: .utf8)
        else {
            print("❌ Failed to encode license data")
            return
        }

        let licenseData = Data(jsonString.utf8)

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
            // Check if subscription is still valid
            let isActive = isSubscriptionActive(tier: tier, expiryDate: expiryDate)

            // Update UI state on main thread
            await MainActor.run {
                self.isPro = isActive
                self.licenseEmail = email
                self.licenseKey = key
                self.subscriptionTier = tier
                self.subscriptionExpiryDate = expiryDate
            }

            // Save to UserDefaults as backup
            UserDefaults.standard.set(isActive, forKey: "isProUser")
            UserDefaults.standard.set(email, forKey: "licenseEmail")
            UserDefaults.standard.set(tier.rawValue, forKey: "subscriptionTier")
            if let expiry = expiryDate {
                UserDefaults.standard.set(expiry, forKey: "subscriptionExpiry")
            }

            print("✅ License saved successfully - Tier: \(tier.displayName)")
        } else {
            print("❌ Failed to save license to Keychain: \(status)")
        }
    }

    /// Check if subscription is still active
    private func isSubscriptionActive(tier: SubscriptionTier, expiryDate: Date?) -> Bool {
        switch tier {
        case .lifetime:
            return true // Lifetime never expires
        case .monthly, .annual:
            guard let expiry = expiryDate else {
                return false // Subscription needs expiry date
            }
            return expiry > Date() // Check if not expired
        case .free:
            return false
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
            // Try to parse as JSON (new format)
            if let jsonData = licenseString.data(using: .utf8),
               let licenseDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: String],
               let email = licenseDict["email"],
               let key = licenseDict["key"],
               let tierString = licenseDict["tier"] {
                let tier = SubscriptionTier(rawValue: tierString) ?? .lifetime
                var expiryDate: Date?

                if let expiryString = licenseDict["expiry"] {
                    expiryDate = ISO8601DateFormatter().date(from: expiryString)
                }

                let isActive = isSubscriptionActive(tier: tier, expiryDate: expiryDate)

                DispatchQueue.main.async {
                    self.isPro = isActive
                    self.licenseEmail = email
                    self.licenseKey = key
                    self.subscriptionTier = tier
                    self.subscriptionExpiryDate = expiryDate
                }

                if isActive {
                    print("✅ Pro license loaded from Keychain - Tier: \(tier.displayName)")
                } else {
                    print("⚠️ License expired - Tier: \(tier.displayName)")
                }
                return
            }

            // Fallback: Try old format (email:key)
            let components = licenseString.split(separator: ":")
            if components.count == 2 {
                DispatchQueue.main.async {
                    self.isPro = true
                    self.licenseEmail = String(components[0])
                    self.licenseKey = String(components[1])
                    self.subscriptionTier = .lifetime // Assume lifetime for old licenses
                    self.subscriptionExpiryDate = nil
                }
                print("✅ Pro license loaded from Keychain (legacy format)")
                return
            }
        }

        // Check UserDefaults backup
        if UserDefaults.standard.bool(forKey: "isProUser") {
            let email = UserDefaults.standard.string(forKey: "licenseEmail")
            let tierString = UserDefaults.standard.string(forKey: "subscriptionTier") ?? "lifetime"
            let tier = SubscriptionTier(rawValue: tierString) ?? .lifetime
            let expiryDate = UserDefaults.standard.object(forKey: "subscriptionExpiry") as? Date

            let isActive = isSubscriptionActive(tier: tier, expiryDate: expiryDate)

            DispatchQueue.main.async {
                self.isPro = isActive
                self.licenseEmail = email
                self.subscriptionTier = tier
                self.subscriptionExpiryDate = expiryDate
            }

            if isActive {
                print("✅ Pro status loaded from UserDefaults - Tier: \(tier.displayName)")
            } else {
                print("⚠️ Subscription expired")
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
        UserDefaults.standard.removeObject(forKey: "subscriptionTier")
        UserDefaults.standard.removeObject(forKey: "subscriptionExpiry")

        DispatchQueue.main.async {
            self.isPro = false
            self.licenseEmail = nil
            self.licenseKey = nil
            self.subscriptionTier = .free
            self.subscriptionExpiryDate = nil
        }

        print("✅ License removed")
        // Note: Analytics tracking removed to avoid circular dependency
    }

    /// Check if subscription needs renewal
    func checkSubscriptionStatus() {
        guard subscriptionTier != .lifetime, subscriptionTier != .free else {
            return // Lifetime and free don't need checking
        }

        if !isSubscriptionActive(tier: subscriptionTier, expiryDate: subscriptionExpiryDate) {
            DispatchQueue.main.async {
                self.isPro = false
            }
            print("⚠️ Subscription expired - User downgraded to free tier")
        }
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
    var allowedModels: [String] {
        if isPro {
            // Pro users get all models - we'll use string references to avoid circular imports
            return [
                "TinyLlama 1.1B",
                "Llama 3.2 1B",
                "Qwen2.5 1.5B",
                "SmolLM2 1.7B",
                "Phi-2 2.7B",
                "Gemma 2 2B",
                "Qwen2.5 3B",
                "Llama 3.2 3B",
                "Phi-3.5 Mini 3.8B"
            ]
        } else {
            return ["Llama 3.2 1B"] // Free tier gets Llama 3.2 1B
        }
    }

    /// Check if a specific model is available
    func canUseModel(_ modelName: String) -> Bool {
        return allowedModels.contains(modelName)
    }
}
