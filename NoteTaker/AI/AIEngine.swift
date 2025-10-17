//
//  AIEngine.swift
//  NoteTaker
//
//  Central AI engine managing TinyLlama 1.1B model
//  Optimized for <3GB RAM usage on Apple Silicon
//

import Combine
import Foundation

/// Central AI engine coordinating all ML operations
/// Singleton pattern ensures single model instance for memory efficiency
class AIEngine: ObservableObject {
    static let shared = AIEngine()

    // MARK: - Services

    private(set) lazy var llmService: LLMInferenceService = .init()

    private(set) lazy var embeddingService: EmbeddingService = .init(llmService: llmService)

    private(set) lazy var autocompleteService: AutocompleteService = .init(llmService: llmService)

    private(set) lazy var summarizationService: SummarizationService = .init(llmService: llmService)

    private(set) lazy var translationService: TranslationService = .init(llmService: llmService)

    private(set) lazy var autoCorrectService: AutoCorrectService = .init(llmService: llmService)

    private(set) lazy var reformulationService: ReformulationService = .init(llmService: llmService)

    private(set) lazy var titleGenerationService: TitleGenerationService = .init(llmService: llmService)

    // MARK: - State

    @Published var isModelLoaded = false
    @Published var modelLoadingError: String?
    @Published var memoryUsage: Double = 0.0 // In MB
    @Published var selectedModel: AIModel = .tinyLlama

    private var cancellables = Set<AnyCancellable>()
    private let memoryMonitorQueue = DispatchQueue(label: "com.notetaker.memorymonitor", qos: .utility)

    // MARK: - Initialization

    private init() {
        setupMemoryMonitoring()
        loadSavedModelPreference()
    }

    // MARK: - Model Management

    /// Loads the saved model preference from UserDefaults
    private func loadSavedModelPreference() {
        if let savedModelRawValue = UserDefaults.standard.string(forKey: "selectedAIModel"),
           let savedModel = AIModel(rawValue: savedModelRawValue) {
            selectedModel = savedModel
        }
    }

    /// Loads the currently selected model
    /// Call this on app launch or lazily on first use
    func loadModel() async {
        await loadModel(selectedModel)
    }

    /// Loads a specific model
    /// - Parameter modelType: The AI model to load
    func loadModel(_ modelType: AIModel) async {
        // If already loaded with the same model, skip
        if isModelLoaded, llmService.getCurrentModel() == modelType {
            return
        }

        await MainActor.run {
            self.isModelLoaded = false
        }

        do {
            try await llmService.loadModel(modelType)

            await MainActor.run {
                self.isModelLoaded = true
                self.modelLoadingError = nil
                self.selectedModel = modelType
            }

            // Save preference
            UserDefaults.standard.set(modelType.rawValue, forKey: "selectedAIModel")

            // Update system monitor (if available)
            // SystemMonitor.shared.setActiveModel(modelType.displayName)

            print("✅ \(modelType.displayName) loaded successfully")
        } catch {
            await MainActor.run {
                self.isModelLoaded = false
                self.modelLoadingError = error.localizedDescription

                // Log error to error logger
                ErrorLogger.shared.logError(
                    "Failed to load \(modelType.displayName)",
                    severity: .error,
                    operation: "Model Loading",
                    details: error.localizedDescription
                )
            }

            print("❌ Failed to load \(modelType.displayName): \(error)")
        }
    }

    /// Switches to a different model
    /// - Parameter modelType: The new model to switch to
    func switchModel(to modelType: AIModel) async {
        // Check if user has access to this model
        guard LicenseManager.shared.canUseModel(modelType) else {
            print("🔒 Model \(modelType.displayName) requires Pro license")
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .showUpgradePrompt,
                    object: UpgradePromptView.PromptType.modelSwitching
                )
            }
            return
        }

        print("🔄 Switching to \(modelType.displayName)...")
        await loadModel(modelType)
    }

    /// Unloads the model to free memory (useful for memory pressure situations)
    func unloadModel() {
        llmService.unloadModel()

        DispatchQueue.main.async {
            self.isModelLoaded = false
        }

        print("🔄 AI Model unloaded")
    }

    // MARK: - Memory Monitoring

    private func setupMemoryMonitoring() {
        // Monitor memory usage every 5 seconds
        Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateMemoryUsage()
            }
            .store(in: &cancellables)
    }

    private func updateMemoryUsage() {
        memoryMonitorQueue.async { [weak self] in
            var taskInfo = mach_task_basic_info()
            var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
            let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
                $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                    task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
                }
            }

            if kerr == KERN_SUCCESS {
                let usedMemoryMB = Double(taskInfo.resident_size) / 1024 / 1024

                DispatchQueue.main.async {
                    self?.memoryUsage = usedMemoryMB
                }

                // Warn if approaching 3GB limit
                if usedMemoryMB > 2500 {
                    print("⚠️ High memory usage: \(String(format: "%.1f", usedMemoryMB)) MB")
                }
            }
        }
    }

    // MARK: - Quick Access Methods

    /// Generates autocomplete suggestions for the given text
    func autocomplete(for text: String) async -> String? {
        return await autocompleteService.generateSuggestion(for: text)
    }

    /// Generates a summary of the given text
    func summarize(_ text: String, maxLength: Int = 100) async -> String? {
        return await summarizationService.summarize(text, maxLength: maxLength)
    }

    /// Generates an embedding vector for the given text
    func generateEmbedding(for text: String) async -> [Float]? {
        return await embeddingService.generateEmbedding(for: text)
    }

    // MARK: - Utility

    /// Returns current model status as a string
    var statusDescription: String {
        if isModelLoaded {
            return "✅ \(selectedModel.displayName) (Metal GPU) • \(String(format: "%.1f", memoryUsage)) MB"
        } else if let error = modelLoadingError {
            return "Error: \(error)"
        } else {
            return "Model not loaded"
        }
    }

    /// Checks if a model is downloaded locally
    func isModelDownloaded(_ modelType: AIModel) -> Bool {
        return llmService.isModelDownloaded(modelType)
    }
}

// MARK: - Memory Pressure Handling

extension AIEngine {
    /// Responds to memory pressure warnings from the system
    func handleMemoryPressure() {
        print("⚠️ Memory pressure detected - considering model unload")

        // If memory usage is very high, unload the model temporarily
        if memoryUsage > 2800 {
            unloadModel()
        }
    }
}
