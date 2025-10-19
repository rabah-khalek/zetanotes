//
//  ModelDownloader.swift
//  ZetaNotes
//
//  Handles downloading AI models from Hugging Face
//

import Foundation

/// Service for downloading AI model files
/// Singleton to ensure downloads continue in background even when views are dismissed
class ModelDownloader: NSObject, ObservableObject {
    static let shared = ModelDownloader()

    @Published var downloadProgress: Double = 0.0
    @Published var isDownloading = false
    @Published var downloadError: String?
    @Published var downloadingModel: AIModel? // Track which model is being downloaded

    private var downloadTask: URLSessionDownloadTask?
    private var observation: NSKeyValueObservation?
    private var completionHandlers: [(Result<URL, Error>) -> Void] = []

    // Shared state for UI updates
    private let sharedState = ModelDownloadState.shared

    override private init() {
        super.init()
    }

    // MARK: - Download

    /// Downloads a model from Hugging Face to Application Support
    /// - Parameters:
    ///   - modelType: The model to download
    ///   - completion: Called when download completes or fails (optional)
    func downloadModel(_ modelType: AIModel, completion: ((Result<URL, Error>) -> Void)? = nil) {
        // If already downloading this model, just add the completion handler
        if isDownloading, downloadingModel == modelType {
            if let completion = completion {
                completionHandlers.append(completion)
            }
            return
        }

        // If downloading a different model, fail
        guard !isDownloading else {
            completion?(.failure(DownloadError.downloadInProgress))
            return
        }

        // Clear previous completion handlers and add new one
        completionHandlers.removeAll()
        if let completion = completion {
            completionHandlers.append(completion)
        }

        // Get destination directory
        guard let modelsDir = getModelsDirectory() else {
            notifyCompletion(.failure(DownloadError.failedToCreateDirectory))
            return
        }

        // Create directory if it doesn't exist
        do {
            try FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true)
        } catch {
            notifyCompletion(.failure(error))
            return
        }

        let destinationURL = modelsDir.appendingPathComponent(modelType.fileName)

        // Check if already exists
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            print("✅ Model already exists at: \(destinationURL.path)")
            notifyCompletion(.success(destinationURL))
            return
        }

        // Start download
        guard let url = URL(string: modelType.huggingFaceURL) else {
            notifyCompletion(.failure(DownloadError.invalidURL))
            return
        }

        print("📥 Starting download of \(modelType.displayName) from Hugging Face...")
        print("   URL: \(url)")
        print("   Destination: \(destinationURL.path)")

        DispatchQueue.main.async {
            self.isDownloading = true
            self.downloadProgress = 0.0
            self.downloadError = nil
            self.downloadingModel = modelType
        }

        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        downloadTask = session.downloadTask(with: url) { [weak self] tempURL, _, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isDownloading = false
                self.downloadingModel = nil
            }

            if let error = error {
                print("❌ Download failed: \(error)")
                DispatchQueue.main.async {
                    self.downloadError = error.localizedDescription
                }
                self.notifyCompletion(.failure(error))
                return
            }

            guard let tempURL = tempURL else {
                self.notifyCompletion(.failure(DownloadError.noDataReceived))
                return
            }

            // Move file to destination
            do {
                // Remove existing file if it exists
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }

                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                print("✅ Model downloaded successfully to: \(destinationURL.path)")
                self.notifyCompletion(.success(destinationURL))
            } catch {
                print("❌ Failed to move downloaded file: \(error)")
                self.notifyCompletion(.failure(error))
            }
        }

        // Observe progress
        observation = downloadTask?.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            DispatchQueue.main.async {
                self?.downloadProgress = progress.fractionCompleted
                self?.sharedState.updateProgress(progress.fractionCompleted)
            }
        }

        downloadTask?.resume()
    }

    /// Cancels the current download
    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        observation?.invalidate()
        observation = nil

        DispatchQueue.main.async {
            self.isDownloading = false
            self.downloadProgress = 0.0
            self.downloadingModel = nil
        }

        print("🛑 Download cancelled")
    }

    // MARK: - Helpers

    private func notifyCompletion(_ result: Result<URL, Error>) {
        let handlers = completionHandlers
        completionHandlers.removeAll()

        for handler in handlers {
            handler(result)
        }
    }

    private func getModelsDirectory() -> URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        else {
            return nil
        }
        return appSupport.appendingPathComponent("ZetaNotes/Models")
    }
}

// MARK: - URLSessionDownloadDelegate

extension ModelDownloader: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Handled in completion block
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.downloadProgress = progress
        }
    }
}

// MARK: - Errors

enum DownloadError: Error, LocalizedError {
    case downloadInProgress
    case failedToCreateDirectory
    case invalidURL
    case noDataReceived

    var errorDescription: String? {
        switch self {
        case .downloadInProgress:
            return "A download is already in progress"
        case .failedToCreateDirectory:
            return "Failed to create models directory"
        case .invalidURL:
            return "Invalid download URL"
        case .noDataReceived:
            return "No data received from server"
        }
    }
}
