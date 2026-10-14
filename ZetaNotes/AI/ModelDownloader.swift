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

        // Check if already exists and validate it
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            // Validate existing file
            if validateDownloadedFile(at: destinationURL, modelType: modelType) {
                print("Model already exists and validated at: \(destinationURL.path)")
                completion?(.success(destinationURL))
                return
            } else {
                // Remove corrupted file
                print("Existing model file is corrupted, removing and re-downloading...")
                try? FileManager.default.removeItem(at: destinationURL)
            }
        }

        // Start download
        guard let url = URL(string: modelType.huggingFaceURL) else {
            completion?(.failure(DownloadError.invalidURL))
            return
        }

        // Validate URL is reachable before starting download
        validateURL(url, modelType: modelType) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.startDownloadTask(url: url, modelType: modelType, destinationURL: destinationURL, completion: completion)
            case .failure(let error):
                self.sharedState.failDownload(modelName: modelType.displayName, error: error.localizedDescription)
                completion?(.failure(error))
            }
        }
    }

    /// Starts the actual download task after validation
    private func startDownloadTask(url: URL, modelType: AIModel, destinationURL: URL, completion: ((Result<URL, Error>) -> Void)?) {
        let fileName = modelType.fileName

        print("Starting download of \(modelType.displayName) from Hugging Face...")
        print("   URL: \(url)")
        print("   Destination: \(destinationURL.path)")
        print("   Active downloads: \(activeTasks.count + 1)")

        // Update shared state
        sharedState.startDownload(modelName: modelType.displayName)

        // Create download task
        let task = session.downloadTask(with: url) { [weak self] tempURL, _, error in
            guard let self = self else { return }

            if let error = error {
                print("Download failed for \(modelType.displayName): \(error)")
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

                // Validate the downloaded file
                if self.validateDownloadedFile(at: destinationURL, modelType: modelType) {
                    print("Model downloaded and validated successfully: \(modelType.displayName)")
                    self.sharedState.completeDownload(modelName: modelType.displayName)
                    self.notifyCompletion(for: fileName, result: .success(destinationURL))
                } else {
                    // File validation failed, remove it
                    try? FileManager.default.removeItem(at: destinationURL)
                    let error = DownloadError.fileCorrupted(reason: "File validation failed after download")
                    print("Downloaded file validation failed: \(modelType.displayName)")
                    self.sharedState.failDownload(modelName: modelType.displayName, error: error.localizedDescription)
                    self.notifyCompletion(for: fileName, result: .failure(error))
                }
            } catch {
                print("Failed to move downloaded file: \(error)")
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

        print("Download cancelled: \(modelType.displayName)")
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

        print("All downloads cancelled")
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

    // MARK: - Validation

    /// Validates a downloaded file to ensure it's not corrupted
    /// - Parameters:
    ///   - fileURL: The local file URL to validate
    ///   - modelType: The model type to validate against
    /// - Returns: True if file is valid, false otherwise
    private func validateDownloadedFile(at fileURL: URL, modelType: AIModel) -> Bool {
        let fileManager = FileManager.default

        // Check if file exists
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("Validation failed: File doesn't exist at \(fileURL.path)")
            return false
        }

        // Get file attributes
        guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
              let fileSize = attributes[.size] as? Int64 else {
            print("Validation failed: Cannot read file attributes")
            return false
        }

        // Check if file is too small (less than 100 MB suggests corruption)
        let minSizeBytes: Int64 = 100 * 1024 * 1024 // 100 MB
        if fileSize < minSizeBytes {
            print("Validation failed: File too small (\(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)))")
            return false
        }

        // Validate GGUF file signature (first 4 bytes should be "GGUF")
        do {
            let fileHandle = try FileHandle(forReadingFrom: fileURL)
            defer { try? fileHandle.close() }

            guard let headerData = try fileHandle.read(upToCount: 4),
                  let signature = String(data: headerData, encoding: .ascii) else {
                print("Validation failed: Cannot read file header")
                return false
            }

            if signature != "GGUF" {
                print("Validation failed: Invalid GGUF signature. Got '\(signature)' instead of 'GGUF'")
                return false
            }

            print("File validation passed for \(modelType.displayName)")
            return true
        } catch {
            print("Validation failed: Cannot open file - \(error.localizedDescription)")
            return false
        }
    }

    /// Validates if a URL is reachable with a HEAD request before downloading
    /// - Parameters:
    ///   - url: The URL to validate
    ///   - modelType: The model type being downloaded
    ///   - completion: Called with success or error
    private func validateURL(_ url: URL, modelType: AIModel, completion: @escaping (Result<Void, Error>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10

        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("URL validation failed for \(modelType.displayName): \(error.localizedDescription)")
                completion(.failure(DownloadError.urlNotReachable(url: url.absoluteString, statusCode: 0)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(DownloadError.invalidURL))
                return
            }

            if httpResponse.statusCode == 200 {
                print("URL validation passed for \(modelType.displayName)")
                completion(.success(()))
            } else {
                print("URL returned status code \(httpResponse.statusCode) for \(modelType.displayName)")
                completion(.failure(DownloadError.urlNotReachable(url: url.absoluteString, statusCode: httpResponse.statusCode)))
            }
        }

        task.resume()
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
    case fileSizeMismatch(expected: String, actual: String)
    case fileCorrupted(reason: String)
    case urlNotReachable(url: String, statusCode: Int)
    case invalidFileFormat(expected: String, actual: String)

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
        case .fileSizeMismatch(let expected, let actual):
            return "Downloaded file size mismatch. Expected: \(expected), Got: \(actual). The file may be corrupted."
        case .fileCorrupted(let reason):
            return "Downloaded file is corrupted: \(reason)"
        case .urlNotReachable(let url, let statusCode):
            return "Model file not found at \(url) (HTTP \(statusCode)). The model definition may have an incorrect filename."
        case .invalidFileFormat(let expected, let actual):
            return "Invalid file format. Expected: \(expected), Got: \(actual)"
        }
    }
}
