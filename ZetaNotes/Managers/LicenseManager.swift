//
//  LicenseManager.swift
//  ZetaNotes
//
//  Feature access control.
//  Since version 1.0.3 ZetaNotes is completely free: in-app purchases were
//  removed and every former Pro feature is unlocked for everyone.
//

import Combine
import Foundation

@MainActor
class LicenseManager: ObservableObject {
    static let shared = LicenseManager()

    /// Always true: all features are unlocked for everyone.
    @Published var isPro: Bool = true

    private init() {}

    // MARK: - Feature Access Control

    var hasProAccess: Bool { true }
    var canUseSemanticSearch: Bool { true }
    var canUseAdvancedAI: Bool { true }
    var canEditPrompts: Bool { true }
    var canSwitchModels: Bool { true }

    /// Every bundled model is available to everyone.
    func canUseModel(_ modelName: String) -> Bool { true }
}
