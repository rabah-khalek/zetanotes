//
//  StatusFooterView.swift
//  ZetaNotes
//
//  Consolidated status footer with system monitor, word count, and model info
//

import SwiftUI

struct StatusFooterView: View {
    @ObservedObject var systemMonitor: SystemMonitor
    @ObservedObject var aiEngine: AIEngine
    @ObservedObject var downloadState: ModelDownloadState
    @ObservedObject var errorLogger: ErrorLogger

    var wordCount: Int
    var characterCount: Int
    var createdAt: Date?

    @Binding var showingErrorLog: Bool

    @State private var showingModelMetadata = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Spacer()

                HStack(spacing: 8) {
                    // Created timestamp
                    if let createdAt = createdAt {
                        timestampBadge(label: "Created", date: createdAt, color: .green)
                    }

                    // Word count
                    wordCountBadge

                    // Performance (tokens/sec)
                    if systemMonitor.tokensPerSecond > 0 {
                        performanceBadge
                    }

                    // System usage (only show when model is loaded)
                    if aiEngine.isModelLoaded {
                        systemUsageBadge
                    }

                    // Active AI Model (only show when model is loaded)
                    if !systemMonitor.activeModel.isEmpty && aiEngine.isModelLoaded {
                        activeModelBadge
                    }

                    // Disclaimer badge
                    disclaimerBadge

                    // Error indicator (show when there are errors)
                    if !errorLogger.errors.isEmpty {
                        errorBadge
                    }

                    // Model Download Progress (if downloading)
                    if downloadState.isDownloading, let modelName = downloadState.downloadingModelName {
                        downloadProgressBadge(modelName: modelName)
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
                .padding(.vertical, 6)

                Spacer()
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(
            Color(nsColor: .controlBackgroundColor)
                .overlay(
                    Rectangle()
                        .fill(Color.secondary.opacity(0.1))
                        .frame(height: 0.5),
                    alignment: .top
                )
        )
        .sheet(isPresented: $showingModelMetadata) {
            ModelMetadataSheet(systemMonitor: systemMonitor, isPresented: $showingModelMetadata)
        }
    }

    // MARK: - Badge Components

    private func timestampBadge(label: String, date: Date, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: label == "Created" ? "calendar.badge.plus" : "calendar.badge.clock")
                .font(.system(size: 9))
                .foregroundColor(color)

            Text(label + ":")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)

            Text(formatTimestamp(date))
                .font(.system(size: 10, weight: .medium, design: .default))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(color.opacity(0.2), lineWidth: 0.5)
                )
        )
        .help("\(label): \(formatFullTimestamp(date))")
    }

    private var wordCountBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.text")
                .font(.system(size: 9))
                .foregroundColor(.blue)

            Text("\(wordCount)w")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)

            Text("•")
                .font(.system(size: 8))
                .foregroundColor(.secondary.opacity(0.5))

            Text("\(characterCount)c")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.blue.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.blue.opacity(0.2), lineWidth: 0.5)
                )
        )
        .help("\(wordCount) words, \(characterCount) characters")
    }

    private var errorBadge: some View {
        Button(action: {
            showingErrorLog.toggle()
        }) {
            HStack(spacing: 4) {
                Image(systemName: errorLogger.errors.contains(where: { $0.severity == .error })
                    ? "exclamationmark.triangle.fill"
                    : "exclamationmark.circle.fill")
                    .font(.system(size: 9))
                    .foregroundColor(errorLogger.errors.contains(where: { $0.severity == .error }) ? .red : .orange)

                Text("\(errorLogger.errors.count)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill((errorLogger.errors.contains(where: { $0.severity == .error }) ? Color.red : Color.orange).opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder((errorLogger.errors.contains(where: { $0.severity == .error }) ? Color.red : Color.orange).opacity(0.2), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .help("View error log (\(errorLogger.errors.count) error\(errorLogger.errors.count == 1 ? "" : "s"))")
    }

    private var activeModelBadge: some View {
        Button(action: {
            print("🔘 Model badge clicked")
            showingModelMetadata = true
        }) {
            HStack(spacing: 4) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 9))
                    .foregroundColor(.purple)

                Text(systemMonitor.activeModel)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Image(systemName: "info.circle")
                    .font(.system(size: 8))
                    .foregroundColor(.purple.opacity(0.6))
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.purple.opacity(showingModelMetadata ? 0.15 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(Color.purple.opacity(showingModelMetadata ? 0.4 : 0.2), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .help("Click to view model details")
    }

    private var performanceBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "speedometer")
                .font(.system(size: 9))
                .foregroundColor(.green)

            Text(String(format: "%.1f", systemMonitor.tokensPerSecond))
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)

            Text("t/s")
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.green.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.green.opacity(0.2), lineWidth: 0.5)
                )
        )
        .help("Generation speed: \(String(format: "%.1f", systemMonitor.tokensPerSecond)) tokens per second")
    }

    private var systemUsageBadge: some View {
        HStack(spacing: 6) {
            // CPU indicator
            HStack(spacing: 3) {
                Image(systemName: "cpu.fill")
                    .font(.system(size: 9))
                    .foregroundColor(cpuColor)

                Text("CPU:")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)

                Text(String(format: "%3d", Int(systemMonitor.cpuUsage)) + "%")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.primary)
                    .frame(width: 32, alignment: .trailing)
            }

            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 1, height: 10)

            // Memory indicator
            HStack(spacing: 3) {
                Image(systemName: "memorychip.fill")
                    .font(.system(size: 9))
                    .foregroundColor(memoryColor)

                Text("MEM:")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)

                Text(String(format: "%3d", Int(systemMonitor.memoryUsage)) + "M")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.primary)
                    .frame(width: 32, alignment: .trailing)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.secondary.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 0.5)
                )
        )
        .help("""
        CPU: \(Int(systemMonitor.cpuUsage))% of \(systemMonitor.cpuCoreCount) cores • \
        Memory: \(Int(systemMonitor.memoryUsage))MB \
        (\(String(format: "%.1f", systemMonitor.memoryUsagePercentage))% of \
        \(Int(systemMonitor.totalSystemMemory / 1024))GB)
        """)
    }

    private var disclaimerBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 9))
                .foregroundColor(.blue)

            Button(action: {
                if let url =
                    URL(
                        string: "mailto:rabah.khalek@gmail.com?subject=ZetaNotes%20Bug%20Report&body=Please%20describe%20the%20issue%20and%20steps%20to%20reproduce:"
                    ) {
                    NSWorkspace.shared.open(url)
                }
            }) {
                Text("Report issue")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.blue)
                    .underline()
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.blue.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.blue.opacity(0.2), lineWidth: 0.5)
                )
        )
        .help("Report any issues or provide feedback")
    }

    private func downloadProgressBadge(modelName: String) -> some View {
        HStack(spacing: 6) {
            ProgressView()
                .scaleEffect(0.6)
                .frame(width: 12, height: 12)

            Text("Downloading \(modelName)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.primary)

            Text("\(Int(downloadState.downloadProgress * 100))%")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.orange)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.orange.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.orange.opacity(0.2), lineWidth: 0.5)
                )
        )
        .help("Downloading AI model: \(Int(downloadState.downloadProgress * 100))% complete")
    }

    // MARK: - Formatting Helpers

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }

    private func formatFullTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }

    // MARK: - Color Helpers

    private var cpuColor: Color {
        switch systemMonitor.cpuUsage {
        case 0 ..< 30:
            return .green
        case 30 ..< 70:
            return .yellow
        default:
            return .red
        }
    }

    private var memoryColor: Color {
        switch systemMonitor.memoryUsagePercentage {
        case 0 ..< 60:
            return .green
        case 60 ..< 80:
            return .yellow
        default:
            return .red
        }
    }
}

// MARK: - Model Metadata Sheet

struct ModelMetadataSheet: View {
    @ObservedObject var systemMonitor: SystemMonitor
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.purple)

                Text("Model Information")
                    .font(.system(size: 20, weight: .bold))

                Spacer()

                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
            }

            Divider()

            // Content
            ScrollView {
                if !systemMonitor.modelMetadataTooltip.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        let lines = systemMonitor.modelMetadataTooltip.split(separator: "\n")

                        ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                            if line.contains(":") {
                                let parts = line.split(separator: ":", maxSplits: 1)
                                if parts.count == 2 {
                                    HStack(alignment: .top, spacing: 12) {
                                        Text(String(parts[0]) + ":")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.secondary)
                                            .frame(width: 100, alignment: .trailing)

                                        Text(String(parts[1]).trimmingCharacters(in: .whitespaces))
                                            .font(.system(size: 14, design: .monospaced))
                                            .foregroundColor(.primary)
                                            .textSelection(.enabled)
                                    }
                                }
                            } else if index == 0 {
                                // First line (model name)
                                Text(String(line))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primary)
                                    .padding(.bottom, 4)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)

                        Text("No Model Loaded")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)

                        Text("Load a model to see its information")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }
            .frame(maxHeight: 300)
        }
        .padding(24)
        .frame(width: 500)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
