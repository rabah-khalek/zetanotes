//
//  StatusFooterView.swift
//  NoteTaker
//
//  Status footer with system monitor and error log
//

import SwiftUI

struct StatusFooterView: View {
    @ObservedObject var systemMonitor: SystemMonitor
    @ObservedObject var errorLogger: ErrorLogger
    @Binding var showingErrorLog: Bool
    var wordCount: Int = 0
    var characterCount: Int = 0

    var body: some View {
        HStack(spacing: 0) {
            Spacer()

            HStack(alignment: .center, spacing: 8) {
                wordCountBadge
                separator

                if !systemMonitor.activeModel.isEmpty {
                    activeModelBadge
                    separator
                }

                systemMonitorBadge

                if !errorLogger.errors.isEmpty {
                    separator
                    errorLogButton
                }
            }
            .padding(.leading, 12)
            .padding(.trailing, 16)
            .padding(.vertical, 6)
        }
        .frame(height: 28)
        .background(
            Color(nsColor: .controlBackgroundColor)
                .overlay(
                    Rectangle()
                        .fill(Color.secondary.opacity(0.1))
                        .frame(height: 0.5),
                    alignment: .top
                )
        )
    }

    // MARK: - Badge Components

    private var separator: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.2))
            .frame(width: 1, height: 14)
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

    private var activeModelBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 9))
                .foregroundColor(.purple)

            Text(systemMonitor.activeModel)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.purple.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.purple.opacity(0.2), lineWidth: 0.5)
                )
        )
        .help("Active AI Model: \(systemMonitor.activeModel)")
    }

    private var systemMonitorBadge: some View {
        HStack(spacing: 6) {
            cpuIndicator

            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 1, height: 10)

            memoryIndicator
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
        .help("CPU: \(Int(systemMonitor.cpuUsage))% of \(systemMonitor.cpuCoreCount) cores • Memory: \(Int(systemMonitor.memoryUsage))MB (\(String(format: "%.1f", systemMonitor.memoryUsagePercentage))% of \(Int(systemMonitor.totalSystemMemory / 1024))GB)")
    }

    private var cpuIndicator: some View {
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
    }

    private var memoryIndicator: some View {
        HStack(spacing: 3) {
            Image(systemName: "memorychip.fill")
                .font(.system(size: 9))
                .foregroundColor(memoryColor)

            Text("MEM:")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)

            Text(String(format: "%4d", Int(systemMonitor.memoryUsage)) + "M")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.primary)
                .frame(width: 42, alignment: .trailing)
        }
    }

    private var errorLogButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showingErrorLog.toggle()
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.orange)

                Text("\(errorLogger.errors.count)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.orange)

                Image(systemName: showingErrorLog ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary.opacity(0.7))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.orange.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
        .help("Click to view \(errorLogger.errors.count) error\(errorLogger.errors.count == 1 ? "" : "s")")
    }

    // MARK: - Color Helpers

    private var cpuColor: Color {
        switch systemMonitor.cpuUsage {
        case 0..<30:
            return .green
        case 30..<70:
            return .yellow
        default:
            return .red
        }
    }

    private var memoryColor: Color {
        switch systemMonitor.memoryUsagePercentage {
        case 0..<60:
            return .green
        case 60..<80:
            return .yellow
        default:
            return .red
        }
    }
}
