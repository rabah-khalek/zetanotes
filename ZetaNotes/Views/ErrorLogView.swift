//
//  ErrorLogView.swift
//  ZetaNotes
//
//  Displays AI errors and logs in a bottom sheet
//  Shows error messages, timestamps, and allows clearing logs
//

import SwiftUI

struct ErrorLogView: View {
    @ObservedObject var errorLogger: ErrorLogger
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)

                Text("Error Log")
                    .font(.system(size: 14, weight: .semibold))

                Spacer()

                if !errorLogger.errors.isEmpty {
                    Text("\(errorLogger.errors.count) error\(errorLogger.errors.count == 1 ? "" : "s")")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.red.opacity(0.15))
                        )
                }

                Button(action: {
                    errorLogger.clearErrors()
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear all errors")
                .disabled(errorLogger.errors.isEmpty)

                Button(action: {
                    withAnimation {
                        isPresented = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close error log")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Error list
            if errorLogger.errors.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(errorLogger.errors) { error in
                            ErrorRowView(error: error)
                        }
                    }
                    .padding(12)
                }
            }
        }
        .frame(height: 280)
        .background(Color(nsColor: .textBackgroundColor))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: -2)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.green.opacity(0.6))

            Text("No Errors")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Text("All AI operations are running smoothly")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error Row View

struct ErrorRowView: View {
    let error: ErrorLogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                // Error icon
                Image(systemName: errorIcon)
                    .font(.system(size: 12))
                    .foregroundColor(errorColor)
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 4) {
                    // Error code (if available)
                    if let errorCode = error.errorCode {
                        Text(errorCode)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(errorColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(errorColor.opacity(0.15))
                            )
                    }

                    // Error message
                    Text(error.message)
                        .font(.system(size: 11))
                        .foregroundColor(.primary)

                    // Timestamp and operation
                    HStack(spacing: 8) {
                        Text(error.timestamp, style: .time)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.secondary)

                        if let operation = error.operation {
                            Text("•")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)

                            Text(operation)
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.secondary.opacity(0.15))
                                )
                        }

                        Text("•")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)

                        // Report issue button (inline)
                        Button(action: {
                            // Build email body with proper line breaks
                            var emailBody = "Error Code: \(error.errorCode ?? "N/A")\n"
                            emailBody += "Message: \(error.message)\n"
                            if let operation = error.operation {
                                emailBody += "Operation: \(operation)\n"
                            }
                            if let details = error.details {
                                emailBody += "Technical Details: \(details)\n"
                            }
                            emailBody += "\n---\nPlease describe what you were doing when this error occurred:"

                            // Properly encode for mailto URL
                            let subject = "ZetaNotes Error Report [\(error.errorCode ?? "UNKNOWN")]"

                            // Create URL components for proper encoding
                            var components = URLComponents()
                            components.scheme = "mailto"
                            components.path = "rabah.khalek@gmail.com"
                            components.queryItems = [
                                URLQueryItem(name: "subject", value: subject),
                                URLQueryItem(name: "body", value: emailBody)
                            ]

                            if let url = components.url {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "envelope")
                                    .font(.system(size: 8))
                                Text("Report")
                                    .font(.system(size: 9))
                            }
                            .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(errorColor.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(errorColor.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var errorIcon: String {
        switch error.severity {
        case .info:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.circle.fill"
        }
    }

    private var errorColor: Color {
        switch error.severity {
        case .info:
            return .blue
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }
}

// MARK: - Error Logger

class ErrorLogger: ObservableObject {
    static let shared = ErrorLogger()

    @Published var errors: [ErrorLogEntry] = []

    private let maxErrors = 50 // Keep last 50 errors
    private var errorTimers: [UUID: Timer] = [:] // Track auto-clear timers for each error

    /// Log an error with error code (preferred method)
    func logError(
        code: ErrorCode,
        operation: String? = nil,
        technicalDetails: String? = nil
    ) {
        // All errors with codes are user-relevant by definition
        let entry = ErrorLogEntry(
            message: code.userMessage,
            severity: .error,
            operation: operation,
            details: technicalDetails,
            errorCode: code.code
        )

        DispatchQueue.main.async {
            self.errors.insert(entry, at: 0)

            // Keep only the most recent errors
            if self.errors.count > self.maxErrors {
                self.errors = Array(self.errors.prefix(self.maxErrors))
            }

            // Auto-clear error after 30 seconds
            self.scheduleAutoClear(for: entry, after: 30.0)
        }

        // Also print to console for debugging
        print("[\(code.code)] [\(operation ?? "AI")] \(code.userMessage)")
        if let details = technicalDetails {
            print("   Technical details: \(details)")
        }
        print("   Report issue: \(ErrorCode.reportIssueURL)")
    }

    /// Log a warning with warning code
    func logWarning(
        code: WarningCode,
        operation: String? = nil,
        details: String? = nil
    ) {
        let entry = ErrorLogEntry(
            message: code.userMessage,
            severity: .warning,
            operation: operation,
            details: details,
            errorCode: code.code
        )

        DispatchQueue.main.async {
            self.errors.insert(entry, at: 0)

            // Keep only the most recent errors
            if self.errors.count > self.maxErrors {
                self.errors = Array(self.errors.prefix(self.maxErrors))
            }

            // Auto-clear warning after 20 seconds (faster than errors)
            self.scheduleAutoClear(for: entry, after: 20.0)
        }

        // Also print to console for debugging
        print("[\(code.code)] [\(operation ?? "AI")] \(code.userMessage)")
        if let details = details {
            print("   Details: \(details)")
        }
    }

    /// Legacy method for backward compatibility - filters non-user-relevant errors
    @available(*, deprecated, message: "Use logError(code:operation:technicalDetails:) instead")
    func logError(
        _ message: String,
        severity: ErrorSeverity = .error,
        operation: String? = nil,
        details: String? = nil
    ) {
        // Filter out non-user-relevant messages
        if !ErrorFilter.shouldShowMessage(message) {
            // Still log to console for debugging
            print("[FILTERED] [\(operation ?? "AI")] \(message)")
            if let details = details {
                print("   Details: \(details)")
            }
            return
        }

        let entry = ErrorLogEntry(
            message: message,
            severity: severity,
            operation: operation,
            details: details,
            errorCode: nil
        )

        DispatchQueue.main.async {
            self.errors.insert(entry, at: 0)

            // Keep only the most recent errors
            if self.errors.count > self.maxErrors {
                self.errors = Array(self.errors.prefix(self.maxErrors))
            }
        }

        // Also print to console for debugging
        let emoji = severity.emoji
        print("\(emoji) [\(operation ?? "AI")] \(message)")
        if let details = details {
            print("   Details: \(details)")
        }
    }

    func clearErrors() {
        DispatchQueue.main.async {
            // Cancel all pending timers
            for timer in self.errorTimers.values {
                timer.invalidate()
            }
            self.errorTimers.removeAll()

            self.errors.removeAll()
        }
    }

    /// Schedules automatic removal of an error after a specified time
    private func scheduleAutoClear(for entry: ErrorLogEntry, after seconds: TimeInterval) {
        let timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            guard let self = self else { return }

            DispatchQueue.main.async {
                // Remove the specific error
                if let index = self.errors.firstIndex(where: { $0.id == entry.id }) {
                    self.errors.remove(at: index)
                    print("Auto-cleared \(entry.severity) from error log: [\(entry.errorCode ?? "N/A")]")
                }

                // Remove the timer reference
                self.errorTimers.removeValue(forKey: entry.id)
            }
        }

        errorTimers[entry.id] = timer
    }
}

// MARK: - Error Log Entry

struct ErrorLogEntry: Identifiable {
    let id = UUID()
    let timestamp = Date()
    let message: String
    let severity: ErrorSeverity
    let operation: String?
    let details: String?
    let errorCode: String? // Error code like "ERROR-ML-001" or "WARN-GEN-001"
}

enum ErrorSeverity {
    case info
    case warning
    case error

    var emoji: String {
        switch self {
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
}

// MARK: - Preview

struct ErrorLogView_Previews: PreviewProvider {
    static var previews: some View {
        let logger = ErrorLogger()

        // Add some sample errors with error codes
        logger.logError(
            code: .modelNotFound,
            operation: "Model Loading",
            technicalDetails: "Could not locate model file at path: ~/models/llama-7b.gguf"
        )
        logger.logWarning(
            code: .generationTruncated,
            operation: "Autocomplete",
            details: "Output was limited to 100 tokens"
        )
        logger.logError(
            code: .insufficientMemory,
            operation: "Text Generation",
            technicalDetails: "Free memory: 342 MB, Required: 500 MB"
        )

        return VStack {
            Spacer()
            ErrorLogView(errorLogger: logger, isPresented: .constant(true))
        }
        .frame(width: 600, height: 400)
        .padding()
    }
}
