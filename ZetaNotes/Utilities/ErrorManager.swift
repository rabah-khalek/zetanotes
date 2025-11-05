//
//  ErrorManager.swift
//  ZetaNotes
//
//  Centralized error handling with user-facing alerts
//  Integrates with Logger for tracking
//

import Foundation
import SwiftUI

/// Centralized error management system
/// Handles errors across the app and provides user-facing error messages
class ErrorManager: ObservableObject {
    static let shared = ErrorManager()

    // MARK: - Published Properties

    @Published var currentError: AppError?
    @Published var showingError = false

    // MARK: - Error Types

    enum AppError: Error, Identifiable {
        case modelLoadFailed(String)
        case modelDownloadFailed(String)
        case noteOperationFailed(String)
        case searchFailed(String)
        case aiInferenceFailed(String)
        case databaseError(String)
        case networkError(String)
        case fileSystemError(String)
        case unknown(String)

        var id: String {
            switch self {
            case let .modelLoadFailed(msg): return "modelLoad_\(msg)"
            case let .modelDownloadFailed(msg): return "modelDownload_\(msg)"
            case let .noteOperationFailed(msg): return "noteOp_\(msg)"
            case let .searchFailed(msg): return "search_\(msg)"
            case let .aiInferenceFailed(msg): return "aiInference_\(msg)"
            case let .databaseError(msg): return "database_\(msg)"
            case let .networkError(msg): return "network_\(msg)"
            case let .fileSystemError(msg): return "fileSystem_\(msg)"
            case let .unknown(msg): return "unknown_\(msg)"
            }
        }

        var title: String {
            switch self {
            case .modelLoadFailed: return "Model Loading Error"
            case .modelDownloadFailed: return "Download Failed"
            case .noteOperationFailed: return "Note Operation Failed"
            case .searchFailed: return "Search Error"
            case .aiInferenceFailed: return "AI Processing Error"
            case .databaseError: return "Database Error"
            case .networkError: return "Network Error"
            case .fileSystemError: return "File System Error"
            case .unknown: return "Unexpected Error"
            }
        }

        var message: String {
            switch self {
            case let .modelLoadFailed(msg): return msg
            case let .modelDownloadFailed(msg): return msg
            case let .noteOperationFailed(msg): return msg
            case let .searchFailed(msg): return msg
            case let .aiInferenceFailed(msg): return msg
            case let .databaseError(msg): return msg
            case let .networkError(msg): return msg
            case let .fileSystemError(msg): return msg
            case let .unknown(msg): return msg
            }
        }

        var recoveryAction: String? {
            switch self {
            case .modelLoadFailed:
                return "Try restarting the app or downloading a different model."
            case .modelDownloadFailed:
                return "Check your internet connection and try again."
            case .noteOperationFailed:
                return "Please try the operation again."
            case .searchFailed:
                return "Try a different search query."
            case .aiInferenceFailed:
                return "The model may be overloaded. Please try again."
            case .databaseError:
                return "Please restart the app. If the problem persists, contact support."
            case .networkError:
                return "Check your internet connection and try again."
            case .fileSystemError:
                return "Check available disk space and permissions."
            case .unknown:
                return "Please try again or restart the app."
            }
        }

        var icon: String {
            switch self {
            case .modelLoadFailed, .modelDownloadFailed: return "exclamationmark.triangle.fill"
            case .noteOperationFailed: return "doc.badge.exclamationmark"
            case .searchFailed: return "magnifyingglass.circle.fill"
            case .aiInferenceFailed: return "cpu.fill"
            case .databaseError: return "cylinder.fill"
            case .networkError: return "wifi.exclamationmark"
            case .fileSystemError: return "folder.badge.exclamationmark"
            case .unknown: return "questionmark.circle.fill"
            }
        }
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Error Handling

    /// Handles an error by logging it and optionally showing it to the user
    /// - Parameters:
    ///   - error: The error to handle
    ///   - showToUser: Whether to show an alert to the user (default: true)
    ///   - file: Source file (for logging)
    ///   - function: Source function (for logging)
    ///   - line: Source line (for logging)
    func handle(
        _ error: AppError,
        showToUser: Bool = true,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        // Log the error
        Logger.shared.error("\(error.title): \(error.message)", file: file, function: function, line: line)

        // Show to user if requested
        if showToUser {
            DispatchQueue.main.async {
                self.currentError = error
                self.showingError = true
            }
        }
    }

    /// Handles a generic Swift error and converts it to AppError
    func handle(
        _ error: Error,
        context: String,
        showToUser: Bool = true,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let appError: AppError

        // Convert known error types
        if let llmError = error as? LLMError {
            switch llmError {
            case .modelNotFound:
                appError = .modelLoadFailed("Model file not found. Please download the model first.")
            case .modelLoadFailed:
                appError = .modelLoadFailed("Failed to load the AI model. The model file may be corrupted.")
            case .inferenceFailed:
                appError = .aiInferenceFailed("AI processing failed. Please try again.")
            case .invalidInput:
                appError = .aiInferenceFailed("Invalid input provided to the AI model.")
            }
        } else if let downloadError = error as? DownloadError {
            switch downloadError {
            case .downloadInProgress:
                appError = .modelDownloadFailed("A download is already in progress.")
            case .failedToCreateDirectory:
                appError = .fileSystemError("Failed to create directory for model storage.")
            case .invalidURL:
                appError = .networkError("Invalid download URL.")
            case .noDataReceived:
                appError = .networkError("No data received from server.")
            case .fileSizeMismatch(let expected, let actual):
                appError = .modelDownloadFailed("File size mismatch. Expected: \(expected), Got: \(actual)")
            case .fileCorrupted(let reason):
                appError = .modelDownloadFailed("Downloaded file is corrupted: \(reason)")
            case .urlNotReachable(_, let statusCode):
                appError = .networkError("Model file not found (HTTP \(statusCode)). Please check the model configuration.")
            case .invalidFileFormat(let expected, let actual):
                appError = .modelDownloadFailed("Invalid file format. Expected: \(expected), Got: \(actual)")
            }
        } else {
            // Generic error
            appError = .unknown("\(context): \(error.localizedDescription)")
        }

        handle(appError, showToUser: showToUser, file: file, function: function, line: line)
    }

    /// Clears the current error
    func clearError() {
        DispatchQueue.main.async {
            self.currentError = nil
            self.showingError = false
        }
    }

    // MARK: - Convenience Methods

    func handleModelLoadError(_ message: String, showToUser: Bool = true) {
        handle(.modelLoadFailed(message), showToUser: showToUser)
    }

    func handleDownloadError(_ message: String, showToUser: Bool = true) {
        handle(.modelDownloadFailed(message), showToUser: showToUser)
    }

    func handleNoteError(_ message: String, showToUser: Bool = true) {
        handle(.noteOperationFailed(message), showToUser: showToUser)
    }

    func handleSearchError(_ message: String, showToUser: Bool = true) {
        handle(.searchFailed(message), showToUser: showToUser)
    }

    func handleAIError(_ message: String, showToUser: Bool = true) {
        handle(.aiInferenceFailed(message), showToUser: showToUser)
    }

    func handleDatabaseError(_ message: String, showToUser: Bool = true) {
        handle(.databaseError(message), showToUser: showToUser)
    }
}

// MARK: - SwiftUI Error Alert Modifier

extension View {
    /// Adds error alert handling to any view
    func errorAlert(errorManager: ErrorManager = .shared) -> some View {
        let binding: Binding<ErrorManager.AppError?> = Binding(
            get: { errorManager.showingError ? errorManager.currentError : nil },
            set: { _ in errorManager.clearError() }
        )

        return alert(item: binding) { (error: ErrorManager.AppError) -> Alert in
            let messageText: String = error
                .message + (error.recoveryAction != nil ? "\n\n\(error.recoveryAction!)" : "")
            return Alert(
                title: Text(error.title),
                message: Text(messageText),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// MARK: - Error Alert View Component

struct ErrorAlertView: View {
    @ObservedObject var errorManager: ErrorManager
    @Binding var isPresented: Bool

    var body: some View {
        if let error = errorManager.currentError, isPresented {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: error.icon)
                        .font(.system(size: 32))
                        .foregroundColor(.red)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(error.title)
                            .font(.headline)

                        Text(error.message)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: {
                        isPresented = false
                        errorManager.clearError()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding()

                if let recovery = error.recoveryAction {
                    Divider()

                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)

                        Text(recovery)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(12)
            .shadow(radius: 10)
            .padding()
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
