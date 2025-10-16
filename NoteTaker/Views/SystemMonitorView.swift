//
//  SystemMonitorView.swift
//  NoteTaker
//
//  System performance monitor displayed as a bottom sheet
//  Shows CPU, Memory, AI metrics with detailed charts
//

import SwiftUI

struct SystemMonitorView: View {
    @ObservedObject var monitor: SystemMonitor
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "gauge.with.dots.needle.67percent")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)

                Text("System Performance")
                    .font(.system(size: 14, weight: .semibold))

                Spacer()

                // System info badge
                HStack(spacing: 4) {
                    Text("\(monitor.cpuCoreCount) cores")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    Text("•")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)

                    Text("\(Int(monitor.totalSystemMemory / 1024))GB")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue.opacity(0.1))
                )

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
                .help("Close system monitor")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Content
            ScrollView {
                VStack(spacing: 16) {
                    // CPU Section
                    MetricSection(
                        title: "CPU",
                        icon: "cpu.fill",
                        value: monitor.formattedCPUUsage,
                        color: cpuColor,
                        progress: monitor.cpuUsage / 100.0,
                        details: "Using \(Int(monitor.cpuUsage))% of \(monitor.cpuCoreCount) cores"
                    )

                    // Memory Section
                    MetricSection(
                        title: "Memory",
                        icon: "memorychip.fill",
                        value: monitor.formattedMemoryUsage,
                        color: memoryColor,
                        progress: monitor.memoryUsagePercentage / 100.0,
                        details: "\(String(format: "%.1f", monitor.memoryUsagePercentage))% of \(Int(monitor.totalSystemMemory / 1024))GB"
                    )

                    Divider()

                    // Memory Pressure
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "speedometer")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)

                                Text("Memory Pressure")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }

                            Text(pressureDescription)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary.opacity(0.8))
                        }

                        Spacer()

                        Text(monitor.memoryPressure.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(memoryPressureColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(memoryPressureColor.opacity(0.15))
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(memoryPressureColor.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .padding(.horizontal, 16)

                    // AI Section (if active)
                    if !monitor.activeModel.isEmpty || monitor.inferenceTime > 0 {
                        Divider()

                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 12))
                                    .foregroundColor(.purple)

                                Text("AI Engine")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }

                            if !monitor.activeModel.isEmpty {
                                HStack {
                                    Text("Active Model:")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)

                                    Spacer()

                                    Text(monitor.activeModel)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.primary)
                                }
                            }

                            if monitor.inferenceTime > 0 {
                                HStack {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.yellow)

                                    Text("Last Inference:")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)

                                    Spacer()

                                    Text("\(Int(monitor.inferenceTime))ms")
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 12)
            }
        }
        .frame(height: 320)
        .background(Color(nsColor: .textBackgroundColor))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: -2)
    }

    // MARK: - Computed Properties

    private var cpuColor: Color {
        switch monitor.cpuUsage {
        case 0..<30:
            return .green
        case 30..<70:
            return .yellow
        default:
            return .red
        }
    }

    private var memoryColor: Color {
        switch monitor.memoryUsagePercentage {
        case 0..<60:
            return .green
        case 60..<80:
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

    private var pressureDescription: String {
        switch monitor.memoryPressure {
        case .normal:
            return "System has sufficient free memory"
        case .warning:
            return "System is using swap memory"
        case .critical:
            return "System may slow down or crash"
        }
    }
}

// MARK: - Metric Section Component

struct MetricSection: View {
    let title: String
    let icon: String
    let value: String
    let color: Color
    let progress: Double
    let details: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                    .frame(width: 20)

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.15))

                    // Progress with gradient
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [color.opacity(0.7), color]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(max(progress, 0), 1))
                }
            }
            .frame(height: 8)

            Text(details)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview

struct SystemMonitorView_Previews: PreviewProvider {
    static var previews: some View {
        let monitor = SystemMonitor.shared
        monitor.startMonitoring()

        return VStack {
            Spacer()
            SystemMonitorView(monitor: monitor, isPresented: .constant(true))
        }
        .frame(width: 600, height: 400)
        .padding()
    }
}
