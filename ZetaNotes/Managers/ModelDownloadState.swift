//
//  ModelDownloadState.swift
//  ZetaNotes
//
//  Shared state for tracking model downloads across the app
//  Supports concurrent downloads of multiple models
//

import Combine
import Foundation

/// Information about an active download
struct ActiveDownload: Identifiable {
    let id = UUID()
    let modelName: String
    var progress: Double
    var error: String?
}

/// Shared singleton for tracking active model downloads
class ModelDownloadState: ObservableObject {
    static let shared = ModelDownloadState()

    @Published var activeDownloads: [String: ActiveDownload] = [:] // Key: model name
    @Published var isDownloading = false // True if any download is active
    @Published var downloadProgress: Double = 0.0 // Overall progress (for backward compatibility)
    @Published var downloadingModelName: String? // First downloading model (for backward compatibility)
    @Published var downloadError: String?

    private init() {}

    func startDownload(modelName: String) {
        DispatchQueue.main.async { [weak self] in
            self?.activeDownloads[modelName] = ActiveDownload(modelName: modelName, progress: 0.0)
            self?.updateGlobalState()
        }
    }

    func updateProgress(_ progress: Double, for modelName: String) {
        DispatchQueue.main.async { [weak self] in
            self?.activeDownloads[modelName]?.progress = progress
            self?.updateGlobalState()
        }
    }

    func completeDownload(modelName: String) {
        DispatchQueue.main.async { [weak self] in
            // Keep download visible for a moment then remove
            self?.activeDownloads[modelName]?.progress = 1.0
            self?.updateGlobalState()

            // Remove after showing completion briefly
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.activeDownloads.removeValue(forKey: modelName)
                self?.updateGlobalState()
            }
        }
    }

    /// Completes the first active download (for backward compatibility)
    func completeDownload() {
        guard let firstKey = activeDownloads.keys.first else { return }
        completeDownload(modelName: firstKey)
    }

    func failDownload(modelName: String, error: String) {
        DispatchQueue.main.async { [weak self] in
            self?.activeDownloads[modelName]?.error = error
            self?.updateGlobalState()

            // Remove failed download after showing error briefly
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                self?.activeDownloads.removeValue(forKey: modelName)
                self?.updateGlobalState()
            }
        }
    }

    /// Fails the first active download (for backward compatibility)
    func failDownload(error: String) {
        guard let firstKey = activeDownloads.keys.first else { return }
        failDownload(modelName: firstKey, error: error)
    }

    func cancelDownload(modelName: String) {
        DispatchQueue.main.async { [weak self] in
            self?.activeDownloads.removeValue(forKey: modelName)
            self?.updateGlobalState()
        }
    }

    /// Cancels the first active download (for backward compatibility)
    func cancelDownload() {
        guard let firstKey = activeDownloads.keys.first else { return }
        cancelDownload(modelName: firstKey)
    }

    /// Cancels the welcome page download (specifically for the default model) - SYNC
    func cancelWelcomeDownloadSync() {
        let defaultModelName = "Llama 3.2 1B"

        // Synchronous cancellation for welcome page to prevent flicker
        assert(Thread.isMainThread, "Must be called from main thread")
        activeDownloads.removeValue(forKey: defaultModelName)
        updateGlobalState()
    }

    /// Starts welcome page download with immediate state - SYNC
    func startWelcomeDownloadSync() {
        let defaultModelName = "Llama 3.2 1B"

        // Synchronous start for welcome page for immediate UI response
        assert(Thread.isMainThread, "Must be called from main thread")
        activeDownloads[defaultModelName] = ActiveDownload(modelName: defaultModelName, progress: 0.0)
        updateGlobalState()
    }

    func cancelAllDownloads() {
        DispatchQueue.main.async { [weak self] in
            self?.activeDownloads.removeAll()
            self?.updateGlobalState()
        }
    }

    private func updateGlobalState() {
        // Ensure we're on the main thread since we're updating @Published properties
        assert(Thread.isMainThread, "updateGlobalState must be called on the main thread")

        // Update backward-compatible properties
        isDownloading = !activeDownloads.isEmpty

        // Set overall progress to average of all downloads
        if !activeDownloads.isEmpty {
            let totalProgress = activeDownloads.values.reduce(0.0) { $0 + $1.progress }
            downloadProgress = totalProgress / Double(activeDownloads.count)
            downloadingModelName = activeDownloads.values.first?.modelName
        } else {
            downloadProgress = 0.0
            downloadingModelName = nil
            downloadError = nil
        }
    }
}
