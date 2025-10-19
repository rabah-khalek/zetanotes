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
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                // Error icon
                Image(systemName: errorIcon)
                    .font(.system(size: 12))
                    .foregroundColor(errorColor)
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 4) {
                    // Error message
                    Text(error.message)
                        .font(.system(size: 11))
                        .foregroundColor(.primary)
                        .lineLimit(isExpanded ? nil : 2)

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
                    }

                    // Extended details (if expanded)
                    if isExpanded, let details = error.details {
                        Text(details)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.secondary.opacity(0.1))
                            )
                    }
                }

                Spacer()

                // Expand/collapse button
                if error.details != nil {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
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

    func logError(
        _ message: String,
        severity: ErrorSeverity = .error,
        operation: String? = nil,
        details: String? = nil
    ) {
        let entry = ErrorLogEntry(
            message: message,
            severity: severity,
            operation: operation,
            details: details
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
            self.errors.removeAll()
        }
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

        // Add some sample errors
        logger.logError(
            "Model file not found",
            severity: .error,
            operation: "Model Loading",
            details: "Could not locate model file at path: ~/models/llama-7b.gguf"
        )
        logger.logError(
            "Inference timeout",
            severity: .warning,
            operation: "Autocomplete",
            details: "Request took longer than 5 seconds"
        )
        logger.logError(
            "Model loaded successfully",
            severity: .info,
            operation: "Initialization"
        )

        return VStack {
            Spacer()
            ErrorLogView(errorLogger: logger, isPresented: .constant(true))
        }
        .frame(width: 600, height: 400)
        .padding()
    }
}
