//
//  ErrorCodes.swift
//  ZetaNotes
//
//  Centralized error code system with user-friendly messages
//  Filters out non-user-relevant errors (like cancellations)
//

import Foundation

/// Error code categories for better organization
enum ErrorCodeCategory: String {
    case modelLoading = "ML"    // Model Loading
    case generation = "GEN"      // Text Generation
    case memory = "MEM"          // Memory Issues
    case download = "DL"         // Downloads
    case database = "DB"         // Database/Persistence
    case network = "NET"         // Network Issues
    case system = "SYS"          // System Issues
}

/// Categorized error codes with user-friendly messages
enum ErrorCode {
    // Model Loading Errors (ERROR-ML-xxx)
    case modelNotFound
    case modelLoadFailed
    case modelNotLoaded
    case modelSwitchFailed

    // Generation Errors (ERROR-GEN-xxx)
    case generationFailed
    case generationTimeout
    case generationEmpty
    case promptTooLarge
    case tokenizationFailed
    case decodeFailed

    // Memory Errors (ERROR-MEM-xxx)
    case insufficientMemory
    case memoryPressure
    case memoryAllocationFailed

    // Download Errors (ERROR-DL-xxx)
    case downloadFailed
    case downloadInProgress
    case invalidDownloadURL
    case noDataReceived
    case directoryCreationFailed

    // Database Errors (ERROR-DB-xxx)
    case databaseSaveFailed
    case databaseLoadFailed
    case databaseCorrupted

    // Network Errors (ERROR-NET-xxx)
    case networkUnavailable
    case requestTimeout
    case serverError

    // System Errors (ERROR-SYS-xxx)
    case fileSystemError
    case permissionDenied
    case unknownError

    /// Format the error code as a string (e.g., "ERROR-ML-001")
    var code: String {
        let prefix = "ERROR"
        switch self {
        // Model Loading
        case .modelNotFound: return "\(prefix)-ML-001"
        case .modelLoadFailed: return "\(prefix)-ML-002"
        case .modelNotLoaded: return "\(prefix)-ML-003"
        case .modelSwitchFailed: return "\(prefix)-ML-004"

        // Generation
        case .generationFailed: return "\(prefix)-GEN-001"
        case .generationTimeout: return "\(prefix)-GEN-002"
        case .generationEmpty: return "\(prefix)-GEN-003"
        case .promptTooLarge: return "\(prefix)-GEN-004"
        case .tokenizationFailed: return "\(prefix)-GEN-005"
        case .decodeFailed: return "\(prefix)-GEN-006"

        // Memory
        case .insufficientMemory: return "\(prefix)-MEM-001"
        case .memoryPressure: return "\(prefix)-MEM-002"
        case .memoryAllocationFailed: return "\(prefix)-MEM-003"

        // Download
        case .downloadFailed: return "\(prefix)-DL-001"
        case .downloadInProgress: return "\(prefix)-DL-002"
        case .invalidDownloadURL: return "\(prefix)-DL-003"
        case .noDataReceived: return "\(prefix)-DL-004"
        case .directoryCreationFailed: return "\(prefix)-DL-005"

        // Database
        case .databaseSaveFailed: return "\(prefix)-DB-001"
        case .databaseLoadFailed: return "\(prefix)-DB-002"
        case .databaseCorrupted: return "\(prefix)-DB-003"

        // Network
        case .networkUnavailable: return "\(prefix)-NET-001"
        case .requestTimeout: return "\(prefix)-NET-002"
        case .serverError: return "\(prefix)-NET-003"

        // System
        case .fileSystemError: return "\(prefix)-SYS-001"
        case .permissionDenied: return "\(prefix)-SYS-002"
        case .unknownError: return "\(prefix)-SYS-999"
        }
    }

    /// User-friendly message explaining the error in non-technical terms
    var userMessage: String {
        switch self {
        // Model Loading
        case .modelNotFound:
            return "The AI model file couldn't be found. Please download the model from Settings."

        case .modelLoadFailed:
            return "The AI model couldn't be loaded. Try restarting the app or downloading the model again."

        case .modelNotLoaded:
            return "No AI model is currently loaded. Please select and download a model from Settings."

        case .modelSwitchFailed:
            return "Failed to switch to the selected model. Try restarting the app."

        // Generation
        case .generationFailed:
            return "The AI couldn't generate text for your request. This might be due to memory constraints or the complexity of your text."

        case .generationTimeout:
            return "The AI took too long to respond. Try with a shorter text or a faster model."

        case .generationEmpty:
            return "The AI generated empty output. Try rephrasing your text or using a different model."

        case .promptTooLarge:
            return "Your text is too long for the current model. Try using a smaller portion or upgrade to a model with a larger context."

        case .tokenizationFailed:
            return "The AI couldn't process your text. Try removing special characters or shortening your text."

        case .decodeFailed:
            return "The AI encountered an error while processing. This usually happens when memory is low."

        // Memory
        case .insufficientMemory:
            return "Your Mac doesn't have enough free memory. Close other apps or use a smaller AI model."

        case .memoryPressure:
            return "Your Mac is running low on memory. The AI will pause to prevent system slowdowns."

        case .memoryAllocationFailed:
            return "The AI couldn't allocate enough memory. Try closing other apps or using a smaller model."

        // Download
        case .downloadFailed:
            return "Model download failed. Check your internet connection and try again."

        case .downloadInProgress:
            return "A model is already downloading. Please wait for it to complete."

        case .invalidDownloadURL:
            return "The download link is invalid. Please contact support if this persists."

        case .noDataReceived:
            return "No data was received during download. Check your internet connection."

        case .directoryCreationFailed:
            return "Couldn't create the folder to store the model. Check your disk space and permissions."

        // Database
        case .databaseSaveFailed:
            return "Your note couldn't be saved. Check if you have enough disk space."

        case .databaseLoadFailed:
            return "Your notes couldn't be loaded. Try restarting the app."

        case .databaseCorrupted:
            return "The notes database appears to be corrupted. Please contact support for recovery options."

        // Network
        case .networkUnavailable:
            return "No internet connection. Check your network settings and try again."

        case .requestTimeout:
            return "The server didn't respond in time. Check your internet connection."

        case .serverError:
            return "The server encountered an error. Please try again later."

        // System
        case .fileSystemError:
            return "Couldn't access a required file or folder. Check your disk space and permissions."

        case .permissionDenied:
            return "Permission denied to access a required resource. Check your macOS permissions for ZetaNotes."

        case .unknownError:
            return "An unexpected error occurred. Please try again or contact support if this persists."
        }
    }

    /// Link to report issues
    static let reportIssueURL = "mailto:rabah.khalek@gmail.com?subject=ZetaNotes%20Error%20Report"

    /// Formatted error message with code and report link
    func formattedMessage(details: String? = nil) -> String {
        var message = "[\(code)] \(userMessage)"

        if let details = details, !details.isEmpty {
            message += "\n\nTechnical details: \(details)"
        }

        message += "\n\nNeed help? Report this issue: \(ErrorCode.reportIssueURL)"
        return message
    }
}

/// Warning code categories for non-critical issues
enum WarningCode {
    // Generation Warnings
    case generationPartialFailure
    case generationTruncated
    case generationEmpty
    case batchProcessingIncomplete

    // Performance Warnings
    case performanceDegradation
    case modelSuboptimal

    /// Format the warning code as a string (e.g., "WARN-GEN-001")
    var code: String {
        let prefix = "WARN"
        switch self {
        case .generationPartialFailure: return "\(prefix)-GEN-001"
        case .generationTruncated: return "\(prefix)-GEN-002"
        case .generationEmpty: return "\(prefix)-GEN-003"
        case .batchProcessingIncomplete: return "\(prefix)-GEN-004"
        case .performanceDegradation: return "\(prefix)-PERF-001"
        case .modelSuboptimal: return "\(prefix)-PERF-002"
        }
    }

    /// User-friendly warning message
    var userMessage: String {
        switch self {
        case .generationPartialFailure:
            return "The AI completed your request but some parts may be incomplete."

        case .generationTruncated:
            return "The AI's output was cut short due to length limits. The result may be incomplete."

        case .generationEmpty:
            return "The AI generated empty output. The result may not be what you expected."

        case .batchProcessingIncomplete:
            return "Some parts of your text couldn't be processed. The result may be partial."

        case .performanceDegradation:
            return "The AI is running slower than usual. Consider closing other apps."

        case .modelSuboptimal:
            return "The current model may not be optimal for this task. Consider upgrading to a larger model."
        }
    }

    /// Formatted warning message with code
    func formattedMessage(details: String? = nil) -> String {
        var message = "[\(code)] \(userMessage)"

        if let details = details, !details.isEmpty {
            message += "\n\nDetails: \(details)"
        }

        return message
    }
}

/// Categorizes errors to determine if they should be shown to users
struct ErrorFilter {
    /// Determines if an error should be shown to the user
    /// Returns true if the error is user-relevant, false otherwise
    static func shouldShowToUser(error: Error) -> Bool {
        // Filter out cancellation errors - these are intentional user actions
        if error is CancellationError {
            return false
        }

        // Check for Swift Task cancellation
        if (error as NSError).domain == NSCocoaErrorDomain && (error as NSError).code == NSUserCancelledError {
            return false
        }

        // Check for explicit cancellation messages in description
        let errorDescription = error.localizedDescription.lowercased()
        if errorDescription.contains("cancel") ||
           errorDescription.contains("cancelled") ||
           errorDescription.contains("canceled") {
            return false
        }

        // All other errors should be shown
        return true
    }

    /// Categorizes an error message to determine severity and user relevance
    static func shouldShowMessage(_ message: String) -> Bool {
        let lowercased = message.lowercased()

        // Filter out cancellation messages
        if lowercased.contains("cancel") ||
           lowercased.contains("cancelled") ||
           lowercased.contains("canceled") {
            return false
        }

        // Filter out internal debug messages
        if lowercased.hasPrefix("debug:") ||
           lowercased.hasPrefix("trace:") {
            return false
        }

        return true
    }
}
