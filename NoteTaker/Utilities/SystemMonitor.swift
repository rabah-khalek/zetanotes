//
//  SystemMonitor.swift
//  NoteTaker
//
//  Real-time CPU, Memory, and GPU monitoring
//  Provides performance metrics for display in UI
//

import Combine
import Foundation

/// Monitors system resources (CPU, Memory, GPU) in real-time
/// Provides data for the system monitor widget and diagnostics view
class SystemMonitor: ObservableObject {
    static let shared = SystemMonitor()

    // MARK: - Published Properties

    @Published var cpuUsage: Double = 0.0 // CPU usage percentage (0-100+)
    @Published var memoryUsage: Double = 0.0 // Memory usage in MB
    @Published var memoryPressure: MemoryPressure = .normal
    @Published var inferenceTime: Double = 0.0 // Last AI inference time in ms
    @Published var activeModel: String = "" // Currently loaded model name

    // System capabilities
    var totalSystemMemory: Double = 0.0 // Total RAM in MB
    var cpuCoreCount: Int = 0 // Number of CPU cores

    // MARK: - Performance History

    struct PerformanceSnapshot {
        let cpu: Double
        let memory: Double
        let timestamp: Date
    }

    private var cpuHistory: [Double] = []
    private var memoryHistory: [Double] = []
    private let maxHistoryCount = 60 // Keep 1 minute of data (at 1 sample/sec)

    var performanceHistory: [PerformanceSnapshot] {
        let now = Date()
        return zip(cpuHistory, memoryHistory).enumerated().map { index, values in
            let timestamp = now.addingTimeInterval(-Double(cpuHistory.count - index))
            return PerformanceSnapshot(cpu: values.0, memory: values.1, timestamp: timestamp)
        }
    }

    // MARK: - Private Properties

    private var timer: Timer?
    private var isMonitoring = false

    // MARK: - Memory Pressure Enum

    enum MemoryPressure: String {
        case normal = "Normal"
        case warning = "Warning"
        case critical = "Critical"

        var color: String {
            switch self {
            case .normal: return "green"
            case .warning: return "yellow"
            case .critical: return "red"
            }
        }
    }

    // MARK: - Initialization

    private init() {
        // Configure vector cache on initialization
        NoteEmbedding.configureVectorCache()

        // Detect system capabilities
        detectSystemCapabilities()
    }

    // MARK: - System Capabilities Detection

    private func detectSystemCapabilities() {
        // Get total system memory
        var size = UInt64(0)
        var len = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &size, &len, nil, 0)
        totalSystemMemory = Double(size) / 1024 / 1024 // Convert to MB

        // Get CPU core count
        var count = 0
        var countSize = MemoryLayout<Int>.size
        sysctlbyname("hw.ncpu", &count, &countSize, nil, 0)
        cpuCoreCount = count

        print("📊 System: \(cpuCoreCount) cores, \(Int(totalSystemMemory))MB RAM")
    }

    // MARK: - Monitoring Control

    /// Starts monitoring system resources
    func startMonitoring() {
        guard !isMonitoring else { return }

        isMonitoring = true

        // Update metrics immediately
        updateMetrics()

        // Schedule updates every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMetrics()
        }

        print("📊 System monitoring started")
    }

    /// Stops monitoring system resources
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false

        print("📊 System monitoring stopped")
    }

    // MARK: - Metrics Update

    private func updateMetrics() {
        // Update CPU usage
        cpuUsage = getCPUUsage()

        // Update memory usage
        memoryUsage = getMemoryUsage()

        // Update memory pressure
        memoryPressure = getMemoryPressure()

        // Update history
        addToHistory(cpu: cpuUsage, memory: memoryUsage)
    }

    private func addToHistory(cpu: Double, memory: Double) {
        cpuHistory.append(cpu)
        memoryHistory.append(memory)

        // Keep only the last N samples
        if cpuHistory.count > maxHistoryCount {
            cpuHistory.removeFirst()
            memoryHistory.removeFirst()
        }
    }

    // MARK: - CPU Usage

    private func getCPUUsage() -> Double {
        var totalUsageOfCPU = 0.0
        var threadsList: thread_act_array_t?
        var threadsCount = mach_msg_type_number_t(0)

        let threadsResult = withUnsafeMutablePointer(to: &threadsList) {
            return $0.withMemoryRebound(to: thread_act_array_t?.self, capacity: 1) {
                task_threads(mach_task_self_, $0, &threadsCount)
            }
        }

        guard threadsResult == KERN_SUCCESS, let threadsList = threadsList else {
            return 0.0
        }

        for index in 0 ..< threadsCount {
            var threadInfo = thread_basic_info()
            var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)

            let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                    thread_info(threadsList[Int(index)], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
                }
            }

            guard infoResult == KERN_SUCCESS else { continue }

            let threadBasicInfo = threadInfo
            if threadBasicInfo.flags & TH_FLAGS_IDLE == 0 {
                totalUsageOfCPU += (Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE)) * 100.0
            }
        }

        // Clean up
        vm_deallocate(
            mach_task_self_,
            vm_address_t(bitPattern: threadsList),
            vm_size_t(Int(threadsCount) * MemoryLayout<thread_t>.stride)
        )

        return totalUsageOfCPU
    }

    // MARK: - Memory Usage

    private func getMemoryUsage() -> Double {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        guard kerr == KERN_SUCCESS else {
            return 0.0
        }

        // Convert to MB
        return Double(taskInfo.resident_size) / 1024 / 1024
    }

    // MARK: - Memory Pressure

    private func getMemoryPressure() -> MemoryPressure {
        // Determine pressure based on percentage of total system memory
        let memoryPercentage = (memoryUsage / totalSystemMemory) * 100

        switch memoryPercentage {
        case 0 ..< 60:
            return .normal
        case 60 ..< 80:
            return .warning
        default:
            return .critical
        }
    }

    /// Returns memory usage as percentage of total system memory
    var memoryUsagePercentage: Double {
        guard totalSystemMemory > 0 else { return 0 }
        return (memoryUsage / totalSystemMemory) * 100
    }

    // MARK: - AI Performance Tracking

    /// Updates the active model name
    func setActiveModel(_ modelName: String) {
        DispatchQueue.main.async {
            self.activeModel = modelName
        }
    }

    /// Records an AI inference time
    func recordInference(duration: Double) {
        DispatchQueue.main.async {
            self.inferenceTime = duration
        }
    }

    // MARK: - Utilities

    /// Returns a formatted string for memory usage
    var formattedMemoryUsage: String {
        return String(format: "%.0f MB", memoryUsage)
    }

    /// Returns a formatted string for CPU usage
    var formattedCPUUsage: String {
        return String(format: "%.0f%%", cpuUsage)
    }

    /// Returns status color based on CPU usage
    var cpuStatusColor: String {
        switch cpuUsage {
        case 0 ..< 30: return "green"
        case 30 ..< 70: return "yellow"
        default: return "red"
        }
    }

    /// Returns status color based on memory usage
    var memoryStatusColor: String {
        return memoryPressure.color
    }

    deinit {
        stopMonitoring()
    }
}
