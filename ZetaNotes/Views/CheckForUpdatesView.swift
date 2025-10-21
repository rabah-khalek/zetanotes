//
//  CheckForUpdatesView.swift
//  ZetaNotes
//
//  Sparkle update checking UI
//

import Sparkle
import SwiftUI

/// View for manually checking for updates
struct CheckForUpdatesView: View {
    @ObservedObject private var updaterViewModel: UpdaterViewModel

    init(updater: SPUUpdater) {
        updaterViewModel = UpdaterViewModel(updater: updater)
    }

    var body: some View {
        Button("Check for Updates...") {
            updaterViewModel.checkForUpdates()
        }
        .disabled(!updaterViewModel.canCheckForUpdates)
    }
}

/// ViewModel to wrap Sparkle's updater
final class UpdaterViewModel: ObservableObject {
    @Published var canCheckForUpdates = false

    private let updater: SPUUpdater

    init(updater: SPUUpdater) {
        self.updater = updater

        // Check if updates can be checked
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    func checkForUpdates() {
        updater.checkForUpdates()
    }
}
