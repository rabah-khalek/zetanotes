//
//  ModelDownloader.swift
//  ZetaNotes
//
//  Handles downloading AI models from Hugging Face
//

import Foundation

/// Information about an active download task
private class DownloadTask {
    let task: URLSessionDownloadTask
    let observation: NSKeyValueObservation
    var completionHandlers: [(Result<URL, Error>) -> Void] = []

    init(task: URLSessionDownloadTask, observation: NSKeyValueObservation) {
        self.task = task
        self.observation = observation
    }
}

/// Service for downloading AI model files
/// Supports concurrent downloads of multiple models
class ModelDownloader: NSObject, ObservableObject {
    static let shared = ModelDownloader()

    @Published var downloadProgress: Double = 0.0
    @Published var isDownloading = false
    @Published var downloadError: String?
    @Published var downloadingModel: AIModel? // Track which model is being downloaded (first one for backward compat)

    private var activeTasks: [String: DownloadTask] = [:] // Key: model fileName
    private let session: URLSession

    // Shared state for UI updates
    private let sharedState = ModelDownloadState.shared

    override private init() {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 3 // Allow up to 3 concurrent downloads
        self.session = URLSession(configuration: config)
        super.init()
    }

    // MARK: - Download

    /// Downloads a model from Hugging Face to Application Support
    /// Supports concurrent downloads of multiple models
    /// - Parameters:
    ///   - modelType: The model to download
    ///   - completion: Called when download completes or fails (optional)
    func downloadModel(_ modelType: AIModel, completion: ((Result<URL, Error>) -> Void)? = nil) {
        let fileName = modelType.fileName

        // If already downloading this model, just add the completion handler
        if let existingTask = activeTasks[fileName] {
            if let completion = completion {
                existingTask.completionHandlers.append(completion)
            }
            print("ℹ️  Already downloading \(modelType.displayName), added to queue")
            return
        }

        // Get destination directory
        guard let modelsDir = getModelsDirectory() else {
            completion?(.failure(DownloadError.failedToCreateDirectory))
            return
        }

        // Create directory if it doesn't exist
        do {
            try FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true)
        } catch {
            completion?(.failure(error))
            return
        }

        let destinationURL = modelsDir.appendingPathComponent(fileName)

        // Check if already exists
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            print("✅ Model already exists at: \(destinationURL.path)")
            completion?(.success(destinationURL))
            return
        }

        // Start download
        guard let url = URL(string: modelType.huggingFaceURL) else {
            completion?(.failure(DownloadError.invalidURL))
            return
        }

        print("📥 Starting download of \(modelType.displayName) from Hugging Face...")
        print("   URL: \(url)")
        print("   Destination: \(destinationURL.path)")
        print("   Active downloads: \(activeTasks.count + 1)")

        // Update shared state
        sharedState.startDownload(modelName: modelType.displayName)

        // Create download task
        let task = session.downloadTask(with: url) { [weak self] tempURL, _, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ Download failed for \(modelType.displayName): \(error)")
                self.sharedState.failDownload(modelName: modelType.displayName, error: error.localizedDescription)
                self.notifyCompletion(for: fileName, result: .failure(error))
                return
            }

            guard let tempURL = tempURL else {
                self.sharedState.failDownload(modelName: modelType.displayName, error: "No data received")
                self.notifyCompletion(for: fileName, result: .failure(DownloadError.noDataReceived))
                return
            }

            // Move file to destination
            do {
                // Remove existing file if it exists
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }

                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                print("✅ Model downloaded successfully: \(modelType.displayName)")
                self.sharedState.completeDownload(modelName: modelType.displayName)
                self.notifyCompletion(for: fileName, result: .success(destinationURL))
            } catch {
                print("❌ Failed to move downloaded file: \(error)")
                self.sharedState.failDownload(modelName: modelType.displayName, error: error.localizedDescription)
                self.notifyCompletion(for: fileName, result: .failure(error))
            }
        }

        // Observe progress
        let observation = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            DispatchQueue.main.async {
                self?.sharedState.updateProgress(progress.fractionCompleted, for: modelType.displayName)
                self?.updateGlobalProgress()
            }
        }

        // Store the task
        let downloadTask = DownloadTask(task: task, observation: observation)
        if let completion = completion {
            downloadTask.completionHandlers.append(completion)
        }
        activeTasks[fileName] = downloadTask

        // Update global state
        updateGlobalProgress()

        task.resume()
    }

    /// Cancels a specific download
    func cancelDownload(for modelType: AIModel) {
        let fileName = modelType.fileName
        guard let downloadTask = activeTasks[fileName] else {
            // Already cancelled or completed, just clean up state
            DispatchQueue.main.async { [weak self] in
                self?.sharedState.cancelDownload(modelName: modelType.displayName)
                self?.updateGlobalProgress()
            }
            return
        }

        downloadTask.task.cancel()
        downloadTask.observation.invalidate()

        // Notify completion handlers with cancellation error
        let handlers = downloadTask.completionHandlers
        for handler in handlers {
            handler(.failure(NSError(domain: "ModelDownloader", code: -999, userInfo: [
                NSLocalizedDescriptionKey: "Download cancelled by user"
            ])))
        }

        activeTasks.removeValue(forKey: fileName)

        DispatchQueue.main.async { [weak self] in
            self?.sharedState.cancelDownload(modelName: modelType.displayName)
            self?.updateGlobalProgress()
        }

        print("🛑 Download cancelled: \(modelType.displayName)")
    }

    /// Cancels the first active download (for backward compatibility)
    func cancelDownload() {
        guard let firstKey = activeTasks.keys.first,
              let model = AIModel.allCases.first(where: { $0.fileName == firstKey }) else {
            return
        }
        cancelDownload(for: model)
    }

    /// Cancels all active downloads
    func cancelAllDownloads() {
        let tasksCopy = activeTasks

        for (_, downloadTask) in tasksCopy {
            downloadTask.task.cancel()
            downloadTask.observation.invalidate()

            // Notify completion handlers
            let handlers = downloadTask.completionHandlers
            for handler in handlers {
                handler(.failure(NSError(domain: "ModelDownloader", code: -999, userInfo: [
                    NSLocalizedDescriptionKey: "Download cancelled by user"
                ])))
            }
        }

        activeTasks.removeAll()

        DispatchQueue.main.async { [weak self] in
            self?.sharedState.cancelAllDownloads()
            self?.updateGlobalProgress()
        }

        print("🛑 All downloads cancelled")
    }

    // MARK: - Helpers

    private func notifyCompletion(for fileName: String, result: Result<URL, Error>) {
        guard let downloadTask = activeTasks[fileName] else { return }

        let handlers = downloadTask.completionHandlers
        activeTasks.removeValue(forKey: fileName)

        for handler in handlers {
            handler(result)
        }

        updateGlobalProgress()
    }

    private func updateGlobalProgress() {
        DispatchQueue.main.async {
            self.isDownloading = !self.activeTasks.isEmpty

            if !self.activeTasks.isEmpty {
                // Calculate average progress
                let totalProgress = self.activeTasks.values.reduce(0.0) { total, task in
                    total + task.task.progress.fractionCompleted
                }
                self.downloadProgress = totalProgress / Double(self.activeTasks.count)

                // Set first downloading model for backward compatibility
                self.downloadingModel = AIModel.allCases.first { model in
                    self.activeTasks.keys.contains(model.fileName)
                }
            } else {
                self.downloadProgress = 0.0
                self.downloadingModel = nil
            }
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
