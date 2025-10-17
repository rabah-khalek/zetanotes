//
//  Logger.swift
//  NoteTaker
//
//  Structured logging system with file-based persistence
//  Replaces print() statements for production-ready logging
//

import Foundation

/// Centralized logging system for the NoteTaker app
/// Provides structured logging with levels, timestamps, and file persistence
class Logger {
    static let shared = Logger()

    // MARK: - Log Level

    enum LogLevel: String {
        case debug = "🔍 DEBUG"
        case info = "ℹ️ INFO"
        case warning = "⚠️ WARNING"
        case error = "❌ ERROR"
        case critical = "🔥 CRITICAL"

        var priority: Int {
            switch self {
            case .debug: return 0
            case .info: return 1
            case .warning: return 2
            case .error: return 3
            case .critical: return 4
            }
        }
    }

    // MARK: - Properties

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()

    private let logQueue = DispatchQueue(label: "com.notetaker.logger", qos: .utility)
    private var logFileURL: URL?
    private let maxLogFileSize: Int = 10 * 1024 * 1024 // 10 MB
    private let minimumLogLevel: LogLevel

    #if DEBUG
    private let enableFileLogging = true
    #else
    private let enableFileLogging = true // Enable in production for debugging
    #endif

    // MARK: - Initialization

    private init() {
        // Set minimum log level based on build configuration
        #if DEBUG
        minimumLogLevel = .debug
        #else
        minimumLogLevel = .info
        #endif

        setupLogFile()
    }

    private func setupLogFile() {
        guard enableFileLogging else { return }

        do {
            let appSupport = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )

            let logsDirectory = appSupport.appendingPathComponent("NoteTaker/Logs", isDirectory: true)
            try FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)

            let logFileName = "notetaker-\(dateFormatter.string(from: Date()).prefix(10)).log"
            logFileURL = logsDirectory.appendingPathComponent(logFileName)

            // Rotate logs if needed
            rotateLogs(directory: logsDirectory)

            log("Logger initialized at: \(logFileURL?.path ?? "unknown")", level: .info)
        } catch {
            print("Failed to setup log file: \(error)")
        }
    }

    // MARK: - Logging Methods

    /// Logs a message with the specified level
    func log(
        _ message: String,
        level: LogLevel,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard level.priority >= minimumLogLevel.priority else { return }

        let timestamp = dateFormatter.string(from: Date())
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(timestamp)] \(level.rawValue) [\(fileName):\(line)] \(function) - \(message)"

        // Print to console
        print(logMessage)

        // Write to file
        if enableFileLogging {
            logQueue.async { [weak self] in
                self?.writeToFile(logMessage)
            }
        }
    }

    /// Convenience methods
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }

    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }

    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }

    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }

    func critical(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .critical, file: file, function: function, line: line)
    }

    // MARK: - File Management

    private func writeToFile(_ message: String) {
        guard let logFileURL = logFileURL else { return }

        let logLine = message + "\n"

        if FileManager.default.fileExists(atPath: logFileURL.path) {
            // Append to existing file
            if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                fileHandle.seekToEndOfFile()
                if let data = logLine.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            }
        } else {
            // Create new file
            try? logLine.write(to: logFileURL, atomically: true, encoding: .utf8)
        }

        // Check file size and rotate if needed
        checkAndRotateLog()
    }

    private func checkAndRotateLog() {
        guard let logFileURL = logFileURL else { return }

        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: logFileURL.path)
            if let fileSize = attributes[.size] as? Int, fileSize > maxLogFileSize {
                rotateCurrentLog()
            }
        } catch {
            print("Failed to check log file size: \(error)")
        }
    }

    private func rotateCurrentLog() {
        guard let logFileURL = logFileURL else { return }

        let timestamp = Int(Date().timeIntervalSince1970)
        let archivedURL = logFileURL.deletingLastPathComponent()
            .appendingPathComponent("notetaker-archived-\(timestamp).log")

        do {
            try FileManager.default.moveItem(at: logFileURL, to: archivedURL)
            print("📦 Log file rotated to: \(archivedURL.lastPathComponent)")
        } catch {
            print("Failed to rotate log file: \(error)")
        }
    }

    private func rotateLogs(directory: URL) {
        do {
            let logFiles = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )

            // Keep only the last 7 days of logs
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

            for logFile in logFiles {
                let attributes = try FileManager.default.attributesOfItem(atPath: logFile.path)
                if let creationDate = attributes[.creationDate] as? Date, creationDate < cutoffDate {
                    try FileManager.default.removeItem(at: logFile)
                    print("🗑️ Deleted old log file: \(logFile.lastPathComponent)")
                }
            }
        } catch {
            print("Failed to rotate logs: \(error)")
        }
    }

    // MARK: - Export

    /// Returns the path to the current log file
    func getCurrentLogPath() -> String? {
        return logFileURL?.path
    }

    /// Exports logs to a specified URL
    func exportLogs(to destinationURL: URL) throws {
        guard let logFileURL = logFileURL else {
            throw LoggerError.noLogFile
        }

        try FileManager.default.copyItem(at: logFileURL, to: destinationURL)
    }

    /// Returns the contents of the current log file
    func getLogContents() -> String? {
        guard let logFileURL = logFileURL else { return nil }
        return try? String(contentsOf: logFileURL, encoding: .utf8)
    }

    /// Clears all logs
    func clearLogs() {
        guard let logsDirectory = logFileURL?.deletingLastPathComponent() else { return }

        do {
            let logFiles = try FileManager.default.contentsOfDirectory(
                at: logsDirectory,
                includingPropertiesForKeys: nil
            )

            for logFile in logFiles {
                try FileManager.default.removeItem(at: logFile)
            }

            log("All logs cleared", level: .info)
        } catch {
            log("Failed to clear logs: \(error)", level: .error)
        }
    }
}

// MARK: - Errors

enum LoggerError: Error, LocalizedError {
    case noLogFile

    var errorDescription: String? {
        switch self {
        case .noLogFile:
            return "No log file available"
        }
    }
}

// MARK: - Global Convenience Functions

/// Convenience function to log debug messages
func logDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.debug(message, file: file, function: function, line: line)
}

/// Convenience function to log info messages
func logInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.info(message, file: file, function: function, line: line)
}

/// Convenience function to log warning messages
func logWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.warning(message, file: file, function: function, line: line)
}

/// Convenience function to log error messages
func logError(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.error(message, file: file, function: function, line: line)
}

/// Convenience function to log critical messages
func logCritical(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.critical(message, file: file, function: function, line: line)
}
