//
//  ReviewManager.swift
//  ZetaNotes
//
//  Manages App Store review prompts using SKStoreReviewController
//  Smart logic to request reviews at appropriate times
//

import Foundation
import StoreKit

/// Manages App Store review requests with smart timing logic
@MainActor
class ReviewManager: ObservableObject {
    static let shared = ReviewManager()

    // MARK: - UserDefaults Keys

    private let lastReviewRequestDateKey = "lastReviewRequestDate"
    private let appLaunchCountKey = "appLaunchCount"
    private let noteCreationCountKey = "noteCreationCount"
    private let firstLaunchDateKey = "firstLaunchDate"
    private let hasRequestedReviewAfterPurchaseKey = "hasRequestedReviewAfterPurchase"

    // MARK: - Configuration

    /// Minimum days between review requests (Apple allows 3 per 365 days)
    private let minimumDaysBetweenRequests = 120 // ~4 months between requests

    /// Minimum days since first launch before requesting review
    private let minimumDaysSinceFirstLaunch = 7

    /// Minimum note count before requesting review
    private let minimumNoteCount = 10

    /// Minimum app launches before requesting review
    private let minimumLaunchCount = 5

    // MARK: - Initialization

    private init() {
        // Record first launch date if not set
        if UserDefaults.standard.object(forKey: firstLaunchDateKey) == nil {
            UserDefaults.standard.set(Date(), forKey: firstLaunchDateKey)
        }
    }

    // MARK: - Public Methods

    /// Increment app launch count (call this in app init)
    func recordAppLaunch() {
        let currentCount = UserDefaults.standard.integer(forKey: appLaunchCountKey)
        UserDefaults.standard.set(currentCount + 1, forKey: appLaunchCountKey)
        print("📊 [ReviewManager] App launch count: \(currentCount + 1)")
    }

    /// Increment note creation count (call when user creates a note)
    func recordNoteCreation() {
        let currentCount = UserDefaults.standard.integer(forKey: noteCreationCountKey)
        UserDefaults.standard.set(currentCount + 1, forKey: noteCreationCountKey)
        print("📊 [ReviewManager] Note creation count: \(currentCount + 1)")
    }

    /// Request review after Pro purchase (guaranteed once)
    func requestReviewAfterPurchase() {
        // Only request once after purchase
        guard !UserDefaults.standard.bool(forKey: hasRequestedReviewAfterPurchaseKey) else {
            print("⏭️ [ReviewManager] Already requested review after purchase, skipping")
            return
        }

        print("⭐ [ReviewManager] Requesting review after Pro purchase")
        UserDefaults.standard.set(true, forKey: hasRequestedReviewAfterPurchaseKey)
        requestReview()
    }

    /// Smart review request - only shows if conditions are met
    func requestReviewIfAppropriate() {
        guard shouldRequestReview() else {
            print("⏭️ [ReviewManager] Not appropriate to request review yet")
            return
        }

        print("⭐ [ReviewManager] Conditions met, requesting review")
        requestReview()
    }

    /// Manual review request (for "Rate ZetaNotes" button in settings)
    func requestReviewManually() {
        print("⭐ [ReviewManager] Manual review request from settings")
        requestReview()
    }

    // MARK: - Private Methods

    /// Check if we should request a review based on usage patterns
    private func shouldRequestReview() -> Bool {
        // Check if enough time has passed since last request
        if let lastRequestDate = UserDefaults.standard.object(forKey: lastReviewRequestDateKey) as? Date {
            let daysSinceLastRequest = Calendar.current.dateComponents([.day], from: lastRequestDate, to: Date()).day ?? 0
            guard daysSinceLastRequest >= minimumDaysBetweenRequests else {
                print("⏭️ [ReviewManager] Only \(daysSinceLastRequest) days since last request (need \(minimumDaysBetweenRequests))")
                return false
            }
        }

        // Check if enough time has passed since first launch
        if let firstLaunchDate = UserDefaults.standard.object(forKey: firstLaunchDateKey) as? Date {
            let daysSinceFirstLaunch = Calendar.current.dateComponents([.day], from: firstLaunchDate, to: Date()).day ?? 0
            guard daysSinceFirstLaunch >= minimumDaysSinceFirstLaunch else {
                print("⏭️ [ReviewManager] Only \(daysSinceFirstLaunch) days since first launch (need \(minimumDaysSinceFirstLaunch))")
                return false
            }
        }

        // Check launch count
        let launchCount = UserDefaults.standard.integer(forKey: appLaunchCountKey)
        guard launchCount >= minimumLaunchCount else {
            print("⏭️ [ReviewManager] Only \(launchCount) launches (need \(minimumLaunchCount))")
            return false
        }

        // Check note count
        let noteCount = UserDefaults.standard.integer(forKey: noteCreationCountKey)
        guard noteCount >= minimumNoteCount else {
            print("⏭️ [ReviewManager] Only \(noteCount) notes (need \(minimumNoteCount))")
            return false
        }

        print("✅ [ReviewManager] All conditions met:")
        print("   - Launch count: \(launchCount)")
        print("   - Note count: \(noteCount)")
        return true
    }

    /// Request review from App Store (Apple decides whether to show)
    private func requestReview() {
        // Record the request date
        UserDefaults.standard.set(Date(), forKey: lastReviewRequestDateKey)

        // Request review (macOS doesn't require window scene)
        SKStoreReviewController.requestReview()
        print("✅ [ReviewManager] Review request sent to SKStoreReviewController")
    }

    // MARK: - Debug Helpers

    #if DEBUG
    /// Reset all review tracking (for testing only)
    func resetReviewTracking() {
        UserDefaults.standard.removeObject(forKey: lastReviewRequestDateKey)
        UserDefaults.standard.removeObject(forKey: appLaunchCountKey)
        UserDefaults.standard.removeObject(forKey: noteCreationCountKey)
        UserDefaults.standard.removeObject(forKey: hasRequestedReviewAfterPurchaseKey)
        print("🔄 [ReviewManager] Reset all review tracking")
    }

    /// Print current tracking stats
    func printStats() {
        let launches = UserDefaults.standard.integer(forKey: appLaunchCountKey)
        let notes = UserDefaults.standard.integer(forKey: noteCreationCountKey)
        let firstLaunch = UserDefaults.standard.object(forKey: firstLaunchDateKey) as? Date
        let lastRequest = UserDefaults.standard.object(forKey: lastReviewRequestDateKey) as? Date
        let hasRequestedAfterPurchase = UserDefaults.standard.bool(forKey: hasRequestedReviewAfterPurchaseKey)

        print("📊 [ReviewManager] Stats:")
        print("   - Launches: \(launches)")
        print("   - Notes: \(notes)")
        print("   - First launch: \(firstLaunch?.description ?? "not set")")
        print("   - Last request: \(lastRequest?.description ?? "never")")
        print("   - Requested after purchase: \(hasRequestedAfterPurchase)")
    }
    #endif
}
