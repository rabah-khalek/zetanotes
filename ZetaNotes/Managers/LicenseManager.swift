//
//  LicenseManager.swift
//  ZetaNotes
//
//  Manages Pro license and feature access
//  Uses StoreKit 2 for In-App Purchases
//

import Foundation
import Combine
import StoreKit

/// Manages Pro license validation and feature access control
/// Delegates to StoreKitManager for App Store purchases
@MainActor
class LicenseManager: ObservableObject {
    static let shared = LicenseManager()

    // MARK: - Published Properties

    @Published var isPro: Bool = false
    @Published var subscriptionTier: SubscriptionTier = .free
    @Published var subscriptionExpiryDate: Date?

    // MARK: - Private Properties

    private let storeKit = StoreKitManager.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        // Observe StoreKit changes
        storeKit.$isPro
            .assign(to: &$isPro)

        storeKit.$subscriptionTier
            .assign(to: &$subscriptionTier)

        storeKit.$subscriptionExpiryDate
            .assign(to: &$subscriptionExpiryDate)

        print("✅ LicenseManager initialized with StoreKit 2")
    }

    // MARK: - Purchase Methods

    /// Purchase a subscription or lifetime access
    func purchase(_ productID: ProductID) async throws {
        guard let product = storeKit.product(for: productID) else {
            throw StoreError.productNotFound
        }

        _ = try await storeKit.purchase(product)
    }

    /// Restore previous purchases
    func restorePurchases() async throws {
        try await storeKit.restorePurchases()
    }

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
            // Pro users get all models
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

    // MARK: - Product Information

    /// Get all available products from StoreKit
    var availableProducts: [Product] {
        return storeKit.products
    }

    /// Get formatted price for a product
    func formattedPrice(for productID: ProductID) -> String {
        return storeKit.formattedPrice(for: productID)
    }

    /// Check if a product is already purchased
    func isPurchased(_ productID: ProductID) -> Bool {
        return storeKit.isPurchased(productID)
    }

    // MARK: - Subscription Information

    /// Get subscription renewal information
    func subscriptionRenewalInfo() async -> Product.SubscriptionInfo.RenewalInfo? {
        return await storeKit.subscriptionRenewalInfo()
    }

    /// Check if subscription needs renewal
    func checkSubscriptionStatus() {
        // StoreKit handles this automatically via transaction listener
        Task {
            await storeKit.updateCustomerProductStatus()
        }
    }
}
