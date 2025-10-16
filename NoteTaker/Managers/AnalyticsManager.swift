//
//  AnalyticsManager.swift
//  NoteTaker
//
//  Privacy-first analytics tracking for app usage and performance
//  All data stored locally, user can view and delete
//

import Foundation
import Combine
import AppKit

/// Privacy-first analytics manager
/// Tracks app usage, feature utilization, and performance metrics locally
class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()

    // MARK: - Published Properties

    @Published var totalInferences: Int = 0
    @Published var avgInferenceTime: Double = 0
    @Published var mostUsedFeature: String = "None"
    @Published var activeModel: String = ""

    // MARK: - Event Types

    enum EventType: String, Codable {
        // App lifecycle
        case appLaunch = "app_launch"
        case appTerminate = "app_terminate"

        // Note operations
        case noteCreated = "note_created"
        case noteDeleted = "note_deleted"
        case noteSearched = "note_searched"

        // AI features
        case autocompleteUsed = "autocomplete_used"
        case summarizationUsed = "summarization_used"
        case translationUsed = "translation_used"
        case titleGenerationUsed = "title_generation_used"
        case autoCorrectUsed = "auto_correct_used"
        case reformulationUsed = "reformulation_used"

        // Model operations
        case modelLoaded = "model_loaded"
        case modelDownloadStarted = "model_download_started"
        case modelDownloadCompleted = "model_download_completed"
        case modelDownloadFailed = "model_download_failed"
        case modelSwitched = "model_switched"

        // Performance
        case inferenceCompleted = "inference_completed"
        case searchCompleted = "search_completed"

        // Errors
        case errorOccurred = "error_occurred"

        // License/Monetization
        case licenseActivated = "license_activated"
        case licenseValidationFailed = "license_validation_failed"
        case licenseRemoved = "license_removed"
        case proFeatureBlocked = "pro_feature_blocked"
        case upgradePromptShown = "upgrade_prompt_shown"
        case upgradePromptDismissed = "upgrade_prompt_dismissed"
        case upgradeButtonClicked = "upgrade_button_clicked"
    }

    // MARK: - Event Structure

    struct AnalyticsEvent: Codable {
        let id: UUID
        let type: EventType
        let timestamp: Date
        let sessionId: UUID
        let metadata: [String: String]

        init(type: EventType, sessionId: UUID, metadata: [String: String] = [:]) {
            self.id = UUID()
            self.type = type
            self.timestamp = Date()
            self.sessionId = sessionId
            self.metadata = metadata
        }
    }

    // MARK: - Properties

    private var events: [AnalyticsEvent] = []
    private let currentSessionId = UUID()
    private let sessionStartTime = Date()

    private var featureUsageCount: [String: Int] = [:]
    private var inferenceTimesHistory: [Double] = []

    private let maxEventsInMemory = 1000
    private let persistenceKey = "com.notetaker.analytics.events"

    // MARK: - Initialization

    private init() {
        loadEvents()
        trackEvent(.appLaunch)
        setupTerminationHandler()
    }

    // MARK: - Event Tracking

    /// Tracks an analytics event
    func trackEvent(_ type: EventType, metadata: [String: String] = [:]) {
        let event = AnalyticsEvent(type: type, sessionId: currentSessionId, metadata: metadata)
        events.append(event)

        // Update computed properties
        updateComputedMetrics(event: event)

        // Log to file for debugging
        logInfo("Analytics: \(type.rawValue) - \(metadata)")

        // Persist events periodically
        if events.count % 10 == 0 {
            saveEvents()
        }

        // Limit memory usage
        if events.count > maxEventsInMemory {
            events.removeFirst(100)
        }
    }

    // MARK: - Convenience Tracking Methods

    func trackNoteCreated() {
        trackEvent(.noteCreated)
    }

    func trackNoteDeleted() {
        trackEvent(.noteDeleted)
    }

    func trackSearch(query: String, resultCount: Int) {
        trackEvent(.noteSearched, metadata: [
            "result_count": String(resultCount)
        ])
    }

    func trackAutocomplete(duration: Double) {
        trackFeatureUsed("autocomplete", duration: duration)
        trackEvent(.autocompleteUsed, metadata: [
            "duration_ms": String(Int(duration))
        ])
    }

    func trackSummarization(duration: Double) {
        trackFeatureUsed("summarization", duration: duration)
        trackEvent(.summarizationUsed, metadata: [
            "duration_ms": String(Int(duration))
        ])
    }

    func trackTranslation(targetLanguage: String, duration: Double) {
        trackFeatureUsed("translation", duration: duration)
        trackEvent(.translationUsed, metadata: [
            "target_language": targetLanguage,
            "duration_ms": String(Int(duration))
        ])
    }

    func trackTitleGeneration(duration: Double) {
        trackFeatureUsed("title_generation", duration: duration)
        trackEvent(.titleGenerationUsed, metadata: [
            "duration_ms": String(Int(duration))
        ])
    }

    func trackAutoCorrect(duration: Double) {
        trackFeatureUsed("auto_correct", duration: duration)
        trackEvent(.autoCorrectUsed, metadata: [
            "duration_ms": String(Int(duration))
        ])
    }

    func trackReformulation(duration: Double) {
        trackFeatureUsed("reformulation", duration: duration)
        trackEvent(.reformulationUsed, metadata: [
            "duration_ms": String(Int(duration))
        ])
    }

    func trackModelLoaded(modelName: String) {
        activeModel = modelName
        trackEvent(.modelLoaded, metadata: [
            "model_name": modelName
        ])
    }

    func trackModelDownloadStarted(modelName: String, fileSize: String) {
        trackEvent(.modelDownloadStarted, metadata: [
            "model_name": modelName,
            "file_size": fileSize
        ])
    }

    func trackModelDownloadCompleted(modelName: String, duration: Double) {
        trackEvent(.modelDownloadCompleted, metadata: [
            "model_name": modelName,
            "duration_seconds": String(Int(duration))
        ])
    }

    func trackModelDownloadFailed(modelName: String, error: String) {
        trackEvent(.modelDownloadFailed, metadata: [
            "model_name": modelName,
            "error": error
        ])
    }

    func trackModelSwitched(from: String, to: String) {
        activeModel = to
        trackEvent(.modelSwitched, metadata: [
            "from_model": from,
            "to_model": to
        ])
    }

    func trackInference(feature: String, model: String, duration: Double) {
        totalInferences += 1
        inferenceTimesHistory.append(duration)

        // Keep only last 100 inference times
        if inferenceTimesHistory.count > 100 {
            inferenceTimesHistory.removeFirst()
        }

        // Update average
        avgInferenceTime = inferenceTimesHistory.reduce(0, +) / Double(inferenceTimesHistory.count)

        trackEvent(.inferenceCompleted, metadata: [
            "feature": feature,
            "model": model,
            "duration_ms": String(Int(duration))
        ])
    }

    func trackError(type: String, message: String) {
        trackEvent(.errorOccurred, metadata: [
            "error_type": type,
            "message": message
        ])
    }

    // MARK: - Private Helpers

    private func trackFeatureUsed(_ feature: String, duration: Double) {
        featureUsageCount[feature, default: 0] += 1

        // Update most used feature
        if let maxFeature = featureUsageCount.max(by: { $0.value < $1.value }) {
            mostUsedFeature = maxFeature.key.capitalized
        }
    }

    private func updateComputedMetrics(event: AnalyticsEvent) {
        // Update metrics based on event type
        // Already handled in specific track methods
    }

    // MARK: - Session Management

    func getSessionDuration() -> TimeInterval {
        return Date().timeIntervalSince(sessionStartTime)
    }

    func getSessionInfo() -> [String: Any] {
        return [
            "session_id": currentSessionId.uuidString,
            "duration_seconds": Int(getSessionDuration()),
            "total_events": events.count,
            "total_inferences": totalInferences,
            "avg_inference_time": avgInferenceTime,
            "most_used_feature": mostUsedFeature,
            "active_model": activeModel
        ]
    }

    // MARK: - Data Management

    func getEventsSummary() -> [String: Any] {
        var summary: [String: Any] = [:]

        // Count events by type
        let eventTypeCounts = Dictionary(grouping: events, by: { $0.type.rawValue })
            .mapValues { $0.count }

        summary["event_counts"] = eventTypeCounts
        summary["total_events"] = events.count
        summary["session_info"] = getSessionInfo()
        summary["feature_usage"] = featureUsageCount

        return summary
    }

    func exportAnalytics() -> String {
        let summary = getEventsSummary()

        var report = "# NoteTaker Analytics Report\n\n"
        report += "Generated: \(Date())\n"
        report += "Session ID: \(currentSessionId.uuidString)\n"
        report += "Session Duration: \(Int(getSessionDuration())) seconds\n\n"

        report += "## Summary\n"
        report += "- Total Events: \(events.count)\n"
        report += "- Total Inferences: \(totalInferences)\n"
        report += "- Avg Inference Time: \(String(format: "%.1f", avgInferenceTime))ms\n"
        report += "- Most Used Feature: \(mostUsedFeature)\n"
        report += "- Active Model: \(activeModel)\n\n"

        report += "## Feature Usage\n"
        for (feature, count) in featureUsageCount.sorted(by: { $0.value > $1.value }) {
            report += "- \(feature.capitalized): \(count) times\n"
        }

        return report
    }

    func clearAnalytics() {
        events.removeAll()
        featureUsageCount.removeAll()
        inferenceTimesHistory.removeAll()
        totalInferences = 0
        avgInferenceTime = 0
        mostUsedFeature = "None"

        saveEvents()
        logInfo("Analytics data cleared")
    }

    // MARK: - Persistence

    private func saveEvents() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(events)

            let fileURL = getAnalyticsFileURL()
            try data.write(to: fileURL)
        } catch {
            logError("Failed to save analytics: \(error)")
        }
    }

    private func loadEvents() {
        do {
            let fileURL = getAnalyticsFileURL()

            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                return
            }

            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            events = try decoder.decode([AnalyticsEvent].self, from: data)

            // Rebuild computed metrics
            rebuildMetrics()
        } catch {
            logError("Failed to load analytics: \(error)")
        }
    }

    private func getAnalyticsFileURL() -> URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        let analyticsDir = appSupport.appendingPathComponent("NoteTaker/Analytics", isDirectory: true)

        try? FileManager.default.createDirectory(at: analyticsDir, withIntermediateDirectories: true)

        return analyticsDir.appendingPathComponent("events.json")
    }

    private func rebuildMetrics() {
        // Rebuild feature usage counts from events
        for event in events {
            switch event.type {
            case .autocompleteUsed:
                featureUsageCount["autocomplete", default: 0] += 1
            case .summarizationUsed:
                featureUsageCount["summarization", default: 0] += 1
            case .translationUsed:
                featureUsageCount["translation", default: 0] += 1
            case .titleGenerationUsed:
                featureUsageCount["title_generation", default: 0] += 1
            case .autoCorrectUsed:
                featureUsageCount["auto_correct", default: 0] += 1
            case .reformulationUsed:
                featureUsageCount["reformulation", default: 0] += 1
            case .inferenceCompleted:
                totalInferences += 1
                if let durationStr = event.metadata["duration_ms"],
                   let duration = Double(durationStr) {
                    inferenceTimesHistory.append(duration)
                }
            default:
                break
            }
        }

        // Update most used feature
        if let maxFeature = featureUsageCount.max(by: { $0.value < $1.value }) {
            mostUsedFeature = maxFeature.key.capitalized
        }

        // Update average inference time
        if !inferenceTimesHistory.isEmpty {
            avgInferenceTime = inferenceTimesHistory.reduce(0, +) / Double(inferenceTimesHistory.count)
        }
    }

    // MARK: - Termination Handler

    private func setupTerminationHandler() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.trackEvent(.appTerminate)
            self?.saveEvents()
        }
    }

    deinit {
        saveEvents()
    }
}
