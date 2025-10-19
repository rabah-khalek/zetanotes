//
//  ModelDownloadState.swift
//  ZetaNotes
//
//  Shared state for tracking model downloads across the app
//

import Foundation
import Combine

/// Shared singleton for tracking active model downloads
class ModelDownloadState: ObservableObject {
    static let shared = ModelDownloadState()

    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0.0
    @Published var downloadingModelName: String?
    @Published var downloadError: String?

    private init() {}

    func startDownload(modelName: String) {
        isDownloading = true
        downloadingModelName = modelName
        downloadProgress = 0.0
        downloadError = nil
    }

    func updateProgress(_ progress: Double) {
        downloadProgress = progress
    }

    func completeDownload() {
        isDownloading = false
        downloadProgress = 1.0
        downloadError = nil
        // Keep model name for a brief moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.downloadingModelName = nil
        }
    }

    func failDownload(error: String) {
        isDownloading = false
        downloadError = error
        downloadingModelName = nil
    }

    func cancelDownload() {
        isDownloading = false
        downloadProgress = 0.0
        downloadError = nil
        downloadingModelName = nil
    }
}
