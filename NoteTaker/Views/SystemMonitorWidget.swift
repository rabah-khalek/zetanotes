//
//  SystemMonitorWidget.swift
//  NoteTaker
//
//  Compact system performance widget showing CPU, Memory, and AI metrics
//  Expandable on click to show detailed information
//

import SwiftUI

struct SystemMonitorWidget: View {
    @ObservedObject var monitor: SystemMonitor
    @State private var isExpanded = false

    var body: some View {
        HStack(spacing: 0) {
            // Compact view (always visible)
            compactView
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                }

            // Expanded details panel
            if isExpanded {
                expandedView
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
    }

    // MARK: - Compact View

    private var compactView: some View {
        HStack(spacing: 6) {
            // CPU indicator with icon
            HStack(spacing: 3) {
                Image(systemName: "cpu.fill")
                    .font(.system(size: 9))
                    .foregroundColor(cpuColor)

                Text("\(Int(monitor.cpuUsage))%")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)
            }

            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 1, height: 10)

            // Memory indicator with icon
            HStack(spacing: 3) {
                Image(systemName: "memorychip.fill")
                    .font(.system(size: 9))
                    .foregroundColor(memoryColor)

                Text("\(Int(monitor.memoryUsage))MB")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)
            }

            // Expand/collapse indicator
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.secondary.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Expanded View

    private var expandedView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Image(systemName: "gauge.with.dots.needle.67percent")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
                Text("System Performance")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close")
            }

            Divider()

            // CPU Usage
            MetricRow(
                label: "CPU",
                icon: "cpu.fill",
                value: monitor.formattedCPUUsage,
                color: cpuColor,
                progress: monitor.cpuUsage / 100.0
            )

            // Memory Usage
            MetricRow(
                label: "Memory",
                icon: "memorychip.fill",
                value: monitor.formattedMemoryUsage,
                color: memoryColor,
                progress: min(monitor.memoryUsage / 3000.0, 1.0)
            )

            // Memory Pressure
            HStack {
                Image(systemName: "speedometer")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .frame(width: 16)

                Text("Pressure:")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Spacer()
                Text(monitor.memoryPressure.rawValue)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(memoryPressureColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(memoryPressureColor.opacity(0.15))
                            .overlay(
                                Capsule()
                                    .strokeBorder(memoryPressureColor.opacity(0.3), lineWidth: 0.5)
                            )
                    )
            }

            // AI Model Info (if active)
            if !monitor.activeModel.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 10))
                            .foregroundColor(.purple)
                            .frame(width: 16)
                        Text("Active Model")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    Text(monitor.activeModel)
                        .font(.system(size: 10))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .padding(.leading, 22)
                }
            }

            // Inference Time (if available)
            if monitor.inferenceTime > 0 {
                HStack {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                        .frame(width: 16)
                    Text("Last inference:")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(monitor.inferenceTime))ms")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(14)
        .frame(width: 240)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Helper Views

    private struct MetricRow: View {
        let label: String
        let icon: String
        let value: String
        let color: Color
        let progress: Double

        var body: some View {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                        .foregroundColor(color)
                        .frame(width: 16)

                    Text(label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(value)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.primary)
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.secondary.opacity(0.15))

                        // Progress with gradient
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [color.opacity(0.8), color]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * min(max(progress, 0), 1))
                    }
                }
                .frame(height: 6)
            }
        }
    }

    // MARK: - Color Helpers

    private var cpuColor: Color {
        switch monitor.cpuUsage {
        case 0 ..< 30:
            return .green
        case 30 ..< 70:
            return .yellow
        default:
            return .red
        }
    }

    private var memoryColor: Color {
        switch monitor.memoryUsage {
        case 0 ..< 2000:
            return .green
        case 2000 ..< 2500:
            return .yellow
        default:
            return .red
        }
    }

    private var memoryPressureColor: Color {
        switch monitor.memoryPressure {
        case .normal:
            return .green
        case .warning:
            return .yellow
        case .critical:
            return .red
        }
    }
}

// MARK: - Preview

struct SystemMonitorWidget_Previews: PreviewProvider {
    static var previews: some View {
        let monitor = SystemMonitor.shared

        VStack(spacing: 20) {
            SystemMonitorWidget(monitor: monitor)

            Text("Compact widget shown above")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 400, height: 200)
        .onAppear {
            // Simulate some metrics for preview
            monitor.startMonitoring()
        }
    }
}
