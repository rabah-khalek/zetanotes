//
//  StoreKitManager.swift
//  ZetaNotes
//
//  Manages In-App Purchases using StoreKit 2
//  Handles subscriptions and non-consumable purchases
//

import Foundation
import StoreKit

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
        case .monthly: return "$1/month"
        case .annual: return "$6/year"
        case .lifetime: return "$20 one-time"
        }
    }
}

/// Product identifiers matching App Store Connect and Configuration.storekit
enum ProductID: String, CaseIterable {
    case monthly = "com.zetanotes.pro.monthly"
    case annual = "com.zetanotes.pro.annual"
    case lifetime = "com.zetanotes.pro.lifetime"

    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .annual: return "Annual"
        case .lifetime: return "Lifetime"
        }
    }
}

/// Manages StoreKit 2 In-App Purchases
@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    // MARK: - DEV Mode for App Review
    // Set to true for App Review builds to enable Pro features without purchase
    #if DEV_PRO_MODE
    private let devProMode = true
    #else
    private let devProMode = false
    #endif

    // MARK: - Published Properties

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var subscriptionStatus: Product.SubscriptionInfo.Status?

    // Computed properties for easy access
    @Published var isPro: Bool = false
    @Published var subscriptionTier: SubscriptionTier = .free
    @Published var subscriptionExpiryDate: Date?

    // MARK: - Private Properties

    private var productsLoaded = false
    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Initialization

    private init() {
        // For DEV_PRO_MODE builds (App Review), enable Pro immediately
        if devProMode {
            isPro = true
            subscriptionTier = .lifetime
            print("🔓 [DEV] Pro mode enabled for App Review build")
        }

        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()

        Task {
            await loadProducts()
            await updateCustomerProductStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Product Loading

    /// Load products from App Store
    func loadProducts() async {
        guard !productsLoaded else {
            print("ℹ️ [StoreKit] Products already loaded (\(products.count) products), skipping")
            return
        }

        do {
            let productIDs = ProductID.allCases.map { $0.rawValue }
            print("🔄 [StoreKit] Loading products with IDs:")
            for id in productIDs {
                print("   - \(id)")
            }

            products = try await Product.products(for: productIDs)

            print("✅ [StoreKit] Loaded \(products.count) products")
            if products.isEmpty {
                print("⚠️ [StoreKit] WARNING: No products loaded!")
                print("   This means StoreKit Configuration is NOT working.")
                print("   Check: Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration")
                print("   Should be set to: Configuration.storekit")
                print("   Note: Products will retry on next loadProducts() call")
                // Don't mark as loaded so it will retry
            } else {
                for product in products {
                    print("  📦 \(product.id): \(product.displayName) - \(product.displayPrice)")
                }
                productsLoaded = true
            }
        } catch {
            print("❌ [StoreKit] Failed to load products: \(error)")
            // Don't mark as loaded so it will retry
        }
    }

    // MARK: - Purchase

    /// Purchase a product
    func purchase(_ product: Product) async throws -> Transaction? {
        print("🛒 Initiating purchase for: \(product.displayName)")

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            // Verify the purchase
            let transaction = try checkVerified(verification)

            // Update customer's product status
            await updateCustomerProductStatus()

            // Finish the transaction
            await transaction.finish()

            print("✅ Purchase successful: \(product.displayName)")
            return transaction

        case .userCancelled:
            print("⚠️ User cancelled purchase")
            return nil

        case .pending:
            print("⏳ Purchase pending approval")
            return nil

        @unknown default:
            print("❌ Unknown purchase result")
            return nil
        }
    }

    // MARK: - Restore Purchases

    /// Restore previous purchases
    func restorePurchases() async throws {
        print("🔄 Restoring purchases...")

        try await AppStore.sync()
        await updateCustomerProductStatus()

        print("✅ Purchases restored")
    }

    // MARK: - Transaction Verification

    /// Verify a transaction is valid
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            print("❌ Transaction verification failed")
            throw StoreError.failedVerification

        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Transaction Listener

    /// Listen for transaction updates
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await MainActor.run {
                        try self.checkVerified(result)
                    }

                    // Update product status
                    await self.updateCustomerProductStatus()

                    // Finish the transaction
                    await transaction.finish()
                } catch {
                    print("❌ Transaction verification failed: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Product Status

    /// Update the customer's purchased products and subscription status
    func updateCustomerProductStatus() async {
        var purchasedIDs: Set<String> = []
        var currentSubscriptionStatus: Product.SubscriptionInfo.Status?

        // Check for active subscriptions and purchases
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Add to purchased products
                purchasedIDs.insert(transaction.productID)

                // Check if this is a subscription
                if let product = products.first(where: { $0.id == transaction.productID }),
                   let subscription = product.subscription {

                    // Get subscription status
                    let statuses = try await subscription.status
                    if let status = statuses.first {
                        currentSubscriptionStatus = status
                    }
                }
            } catch {
                print("❌ Failed to verify transaction: \(error.localizedDescription)")
            }
        }

        // Update published properties
        purchasedProductIDs = purchasedIDs
        subscriptionStatus = currentSubscriptionStatus

        // Update Pro status and tier
        updateProStatus()

        print("📊 Product status updated - Purchased: \(purchasedIDs.count), Pro: \(isPro), Tier: \(subscriptionTier.displayName)")
    }

    /// Determine Pro status and subscription tier from purchases
    private func updateProStatus() {
        // DEV_PRO_MODE: Always enable Pro for App Review builds
        if devProMode {
            isPro = true
            subscriptionTier = .lifetime
            subscriptionExpiryDate = nil
            return
        }

        // Check for lifetime purchase
        if purchasedProductIDs.contains(ProductID.lifetime.rawValue) {
            isPro = true
            subscriptionTier = .lifetime
            subscriptionExpiryDate = nil
            print("✅ Lifetime Pro active")
            return
        }

        // Check subscription status
        guard let status = subscriptionStatus else {
            isPro = false
            subscriptionTier = .free
            subscriptionExpiryDate = nil
            print("ℹ️ No active subscription")
            return
        }

        switch status.state {
        case .subscribed:
            isPro = true

            // Determine tier from product ID
            if purchasedProductIDs.contains(ProductID.monthly.rawValue) {
                subscriptionTier = .monthly
            } else if purchasedProductIDs.contains(ProductID.annual.rawValue) {
                subscriptionTier = .annual
            }

            // Set expiry date from renewal info
            if let renewalInfo = try? status.renewalInfo.payloadValue {
                subscriptionExpiryDate = renewalInfo.renewalDate
            }

            print("✅ Active subscription: \(subscriptionTier.displayName)")

        case .expired:
            isPro = false
            subscriptionTier = .free
            subscriptionExpiryDate = nil
            print("⚠️ Subscription expired")

        case .revoked:
            isPro = false
            subscriptionTier = .free
            subscriptionExpiryDate = nil
            print("⚠️ Subscription revoked")

        case .inGracePeriod:
            // Keep Pro access during grace period
            isPro = true
            print("⚠️ Subscription in grace period")

        case .inBillingRetryPeriod:
            // Keep Pro access during billing retry
            isPro = true
            print("⚠️ Subscription in billing retry period")

        default:
            // Handle any future states conservatively
            isPro = false
            subscriptionTier = .free
            subscriptionExpiryDate = nil
            print("⚠️ Unknown or unsupported subscription state")
        }
    }

    // MARK: - Product Helpers

    /// Get product by ID
    func product(for productID: ProductID) -> Product? {
        return products.first { $0.id == productID.rawValue }
    }

    /// Check if product is purchased
    func isPurchased(_ productID: ProductID) -> Bool {
        return purchasedProductIDs.contains(productID.rawValue)
    }

    /// Get subscription renewal info
    func subscriptionRenewalInfo() async -> Product.SubscriptionInfo.RenewalInfo? {
        guard let status = subscriptionStatus else { return nil }
        return try? status.renewalInfo.payloadValue
    }

    /// Get formatted price for product
    func formattedPrice(for productID: ProductID) -> String {
        guard let product = product(for: productID) else {
            return productID.displayName
        }
        return product.displayPrice
    }
}

// MARK: - StoreError

enum StoreError: Error {
    case failedVerification
    case productNotFound
    case purchaseFailed

    var localizedDescription: String {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        case .productNotFound:
            return "Product not found in App Store"
        case .purchaseFailed:
            return "Purchase failed"
        }
    }
}
