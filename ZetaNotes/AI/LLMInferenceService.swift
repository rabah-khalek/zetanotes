//
//  LLMInferenceService.swift
//  ZetaNotes
//
//  Low-level interface to GGUF models via llama.cpp
//  Supports TinyLlama 1.1B and Qwen2.5-3B
//  Uses llama.cpp for CPU/GPU inference on Apple Silicon
//

import Foundation
import SwiftUI

// MARK: - Model Types

/// Available AI models for the ZetaNotes app
/// Ordered from worst to best quality
enum AIModel: String, CaseIterable, Codable {
    case tinyLlama = "TinyLlama 1.1B"
    case llamaThreeTwoOneB = "Llama 3.2 1B"
    case qwenTwoFiveOneFiveB = "Qwen2.5 1.5B"
    case smolLMTwoOneSevenB = "SmolLM2 1.7B"
    case phi2 = "Phi-2 2.7B"
    case gemmaTwoTwoB = "Gemma 2 2B"
    case qwenTwoFiveThreeB = "Qwen2.5 3B"
    case llamaThreeTwoThreeB = "Llama 3.2 3B"
    case phiThreeFiveMini = "Phi-3.5 Mini 3.8B"

    var displayName: String {
        rawValue
    }

    var fileName: String {
        switch self {
        case .tinyLlama:
            return "tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
        case .llamaThreeTwoOneB:
            return "Llama-3.2-1B-Instruct-Q4_K_M.gguf"
        case .qwenTwoFiveOneFiveB:
            return "qwen2.5-1.5b-instruct-q4_k_m.gguf"
        case .smolLMTwoOneSevenB:
            return "smollm2-1.7b-instruct-q4_k_m.gguf"
        case .gemmaTwoTwoB:
            return "gemma-2-2b-it-Q4_K_M.gguf"
        case .phi2:
            return "phi-2.Q4_K_M.gguf"
        case .qwenTwoFiveThreeB:
            return "qwen2.5-3b-instruct-q4_k_m.gguf"
        case .llamaThreeTwoThreeB:
            return "Llama-3.2-3B-Instruct-Q4_K_M.gguf"
        case .phiThreeFiveMini:
            return "Phi-3.5-mini-instruct-Q4_K_M.gguf"
        }
    }

    var fileSize: String {
        switch self {
        case .tinyLlama:
            return "0.7 GB"
        case .llamaThreeTwoOneB:
            return "0.7 GB"
        case .qwenTwoFiveOneFiveB:
            return "0.9 GB"
        case .smolLMTwoOneSevenB:
            return "1.0 GB"
        case .phi2:
            return "1.6 GB"
        case .gemmaTwoTwoB:
            return "1.4 GB"
        case .qwenTwoFiveThreeB:
            return "2.0 GB"
        case .llamaThreeTwoThreeB:
            return "2.0 GB"
        case .phiThreeFiveMini:
            return "2.3 GB"
        }
    }

    var memoryUsage: String {
        switch self {
        case .tinyLlama:
            return "~1.5 GB"
        case .llamaThreeTwoOneB:
            return "~1.2 GB"
        case .qwenTwoFiveOneFiveB:
            return "~1.4 GB"
        case .smolLMTwoOneSevenB:
            return "~1.6 GB"
        case .phi2:
            return "~2.2 GB"
        case .gemmaTwoTwoB:
            return "~2.0 GB"
        case .qwenTwoFiveThreeB:
            return "~2.5 GB"
        case .llamaThreeTwoThreeB:
            return "~2.6 GB"
        case .phiThreeFiveMini:
            return "~2.8 GB"
        }
    }

    var speedRating: String {
        switch self {
        case .tinyLlama:
            return "Very Fast"
        case .llamaThreeTwoOneB:
            return "Very Fast"
        case .qwenTwoFiveOneFiveB:
            return "Very Fast"
        case .smolLMTwoOneSevenB:
            return "Very Fast"
        case .phi2:
            return "Very Fast"
        case .gemmaTwoTwoB:
            return "Very Fast"
        case .qwenTwoFiveThreeB:
            return "Fast"
        case .llamaThreeTwoThreeB:
            return "Fast"
        case .phiThreeFiveMini:
            return "Fast"
        }
    }

    var qualityRating: String {
        switch self {
        case .tinyLlama:
            return "Basic"
        case .llamaThreeTwoOneB:
            return "Basic+"
        case .qwenTwoFiveOneFiveB:
            return "Good"
        case .smolLMTwoOneSevenB:
            return "Good"
        case .phi2:
            return "Good+"
        case .gemmaTwoTwoB:
            return "High"
        case .qwenTwoFiveThreeB:
            return "High"
        case .llamaThreeTwoThreeB:
            return "Very High"
        case .phiThreeFiveMini:
            return "Very High"
        }
    }

    var description: String {
        switch self {
        case .tinyLlama:
            return "Lightweight model, best for autocomplete and embeddings. Limited instruction-following quality."
        case .llamaThreeTwoOneB:
            return "Meta's tiny model with latest architecture."
        case .qwenTwoFiveOneFiveB:
            return "Qwen's compact model. Good balance of speed and basic instruction-following capabilities."
        case .smolLMTwoOneSevenB:
            return "Hugging Face's compact model trained on high-quality data. Better instruction-following than TinyLlama."
        case .phi2:
            return "Microsoft's small reasoning model. Good at following instructions and logical tasks."
        case .gemmaTwoTwoB:
            return "Google's efficient 2B model with excellent instruction-following. Great balance of speed and quality."
        case .qwenTwoFiveThreeB:
            return "3B parameter model with excellent instruction-following. Much better for patch, reformulate, and title generation."
        case .llamaThreeTwoThreeB:
            return "Meta's latest 3B model. State-of-the-art quality for its size with strong multilingual support."
        case .phiThreeFiveMini:
            return "Microsoft's latest compact model. Best-in-class quality under 4B parameters. Excellent for all tasks."
        }
    }

    /// Maximum context window size in tokens for each model
    /// Note: Reduced from 32K to 8K to significantly reduce SWAP usage while maintaining practical usability
    var maxContextSize: Int32 {
        switch self {
        case .tinyLlama:
            return 2048
        case .llamaThreeTwoOneB:
            return 4096 // 4K (reduced from 8K to save memory)
        case .qwenTwoFiveOneFiveB:
            return 8192 // 8K (reduced from 32K to save 4-6GB SWAP)
        case .smolLMTwoOneSevenB:
            return 4096 // 4K (reduced from 8K to save memory)
        case .phi2:
            return 2048
        case .gemmaTwoTwoB:
            return 4096 // 4K (reduced from 8K to save memory)
        case .qwenTwoFiveThreeB:
            return 8192 // 8K (reduced from 32K to save 4-6GB SWAP)
        case .llamaThreeTwoThreeB:
            return 8192*2 // 16K (reduced from 32K to save 4-6GB SWAP)
        case .phiThreeFiveMini:
            return 8192 // 8K (reduced from 32K to save 4-6GB SWAP)
        }
    }

    /// Optimal batch size for processing (typically same as context for modern models)
    /// Reduced to match new context sizes for better memory efficiency
    var optimalBatchSize: Int32 {
        switch self {
        case .tinyLlama:
            return 512 // Small model, keep conservative
        case .llamaThreeTwoOneB:
            return 1024 // 1K batch for 4K context (reduced for memory)
        case .qwenTwoFiveOneFiveB:
            return 2048 // 2K batch for 8K context (reduced for memory)
        case .smolLMTwoOneSevenB:
            return 1024 // 1K batch for 4K context (reduced for memory)
        case .phi2:
            return 512 // Small model, keep conservative
        case .gemmaTwoTwoB:
            return 1024 // 1K batch for 4K context (reduced for memory)
        case .qwenTwoFiveThreeB:
            return 2048 // 2K batch for 8K context (reduced for memory)
        case .llamaThreeTwoThreeB:
            return 2048 // 2K batch for 8K context (reduced for memory)
        case .phiThreeFiveMini:
            return 2048 // 2K batch for 8K context (reduced for memory)
        }
    }

    var huggingFaceURL: String {
        switch self {
        case .tinyLlama:
            return "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
        case .llamaThreeTwoOneB:
            return "https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf"
        case .qwenTwoFiveOneFiveB:
            return "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf"
        case .smolLMTwoOneSevenB:
            return "https://huggingface.co/HuggingFaceTB/SmolLM2-1.7B-Instruct-GGUF/resolve/main/smollm2-1.7b-instruct-q4_k_m.gguf"
        case .phi2:
            return "https://huggingface.co/TheBloke/phi-2-GGUF/resolve/main/phi-2.Q4_K_M.gguf"
        case .gemmaTwoTwoB:
            return "https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf"
        case .qwenTwoFiveThreeB:
            return "https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf"
        case .llamaThreeTwoThreeB:
            return "https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf"
        case .phiThreeFiveMini:
            return "https://huggingface.co/bartowski/Phi-3.5-mini-instruct-GGUF/resolve/main/Phi-3.5-mini-instruct-Q4_K_M.gguf"
        }
    }
}

/// Service handling direct LLM inference
/// Wraps llama.cpp or Core ML for running quantized GGUF models
class LLMInferenceService: @unchecked Sendable {
    // MARK: - Configuration

    private enum ModelConfig {
        static let threads: Int32 = 0 // 0 = auto-detect optimal threads
        static let gpuLayers: Int32 = 20 // Reduced from 33 to save 1-2GB SWAP
        static let minFreeMemoryMB: Double = 500 // Require 500MB free before generation
        static let maxKVCacheTokens: Int32 = 4096 // Limit KV cache to 4K tokens to prevent unbounded growth
    }

    // MARK: - State

    private var model: OpaquePointer?
    private var context: OpaquePointer?
    private var sampler: UnsafeMutablePointer<llama_sampler>?
    private var isLoaded = false
    private var currentModel: AIModel = .tinyLlama
    private let inferenceQueue = DispatchQueue(label: "com.zetanotes.inference", qos: .userInitiated)
    private var currentKVCacheTokenCount: Int32 = 0 // Track KV cache usage

    // MARK: - Cancellation Support

    private var currentGenerationTask: Task<Void, Never>?
    private var shouldCancelGeneration = false

    // MARK: - Memory Pressure Monitoring

    private var memoryPressureSource: DispatchSourceMemoryPressure?
    private var isUnderMemoryPressure = false

    // MARK: - Thread Safety

    // Serial queue ensures only one generation runs at a time
    // inferenceQueue already provides this - we just need to ensure proper cancellation

    // MARK: - Memory Management

    /// Check if there is sufficient free memory for generation
    private func hassufficientMemory() -> (available: Bool, freeMemoryMB: Double) {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kerr = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        guard kerr == KERN_SUCCESS else {
            print("⚠️ Failed to get memory info - allowing generation")
            return (true, 0)
        }

        // Get physical memory
        let physicalMemory = Double(ProcessInfo.processInfo.physicalMemory) / 1024 / 1024
        let usedMemoryMB = Double(taskInfo.resident_size) / 1024 / 1024
        let freeMemoryMB = physicalMemory - usedMemoryMB

        let hasEnough = freeMemoryMB >= ModelConfig.minFreeMemoryMB

        if !hasEnough {
            print("⚠️ Insufficient memory for generation:")
            print("   Free: \(String(format: "%.1f", freeMemoryMB)) MB")
            print("   Required: \(String(format: "%.1f", ModelConfig.minFreeMemoryMB)) MB")
        }

        return (hasEnough, freeMemoryMB)
    }

    /// Reset context to free GPU memory
    private func resetContext() {
        guard let ctx = context else { return }
        let mem = llama_get_memory(ctx)
        llama_memory_clear(mem, true) // Clear both metadata and data buffer
        currentKVCacheTokenCount = 0 // Reset token counter
        print("🔄 Cleared KV cache to free GPU memory")
    }

    /// Check if KV cache needs pruning and prune if necessary
    private func pruneKVCacheIfNeeded(addingTokens: Int32) {
        guard context != nil else { return }

        let projectedCount = currentKVCacheTokenCount + addingTokens

        if projectedCount > ModelConfig.maxKVCacheTokens {
            print("⚠️ KV cache approaching limit: \(currentKVCacheTokenCount) + \(addingTokens) > \(ModelConfig.maxKVCacheTokens)")
            print("🧹 Pruning KV cache to prevent memory overflow...")
            resetContext()
        }
    }

    // MARK: - Performance Metrics

    /// Performance metrics from last generation
    struct PerformanceMetrics {
        let promptTokens: Int
        let generatedTokens: Int
        let promptTime: Double // ms
        let generationTime: Double // ms
        let tokensPerSecond: Double

        var totalTime: Double {
            promptTime + generationTime
        }
    }

    @Published private(set) var lastPerformanceMetrics: PerformanceMetrics?

    // MARK: - Model Metadata

    /// Model metadata from GGUF file
    struct ModelMetadata {
        let parameterCount: UInt64
        let description: String
        let contextSize: Int32
        let embeddingSize: Int32
        let layerCount: Int32
        let headCount: Int32
    }

    private(set) var modelMetadata: ModelMetadata?

    // MARK: - Initialization & Cleanup

    init() {
        setupMemoryPressureMonitoring()
    }

    deinit {
        memoryPressureSource?.cancel()
        memoryPressureSource = nil
        // Cleanup is handled by unloadModel()
    }

    /// Setup memory pressure monitoring
    private func setupMemoryPressureMonitoring() {
        let source = DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical], queue: .main)

        source.setEventHandler { [weak self] in
            guard let self = self else { return }
            let event = source.data

            if event.contains(.warning) {
                print("⚠️ Memory pressure WARNING detected")
                self.isUnderMemoryPressure = true
                // AGGRESSIVE: Clear KV cache immediately
                if self.context != nil {
                    self.inferenceQueue.async {
                        self.resetContext()
                        print("🧹 Aggressively cleared KV cache due to memory warning")
                    }
                }
                // Log error for user visibility
                ErrorLogger.shared.logWarning(
                    code: WarningCode.performanceDegradation,
                    operation: "Memory Management",
                    details: "System is running low on memory. Cleared AI caches to prevent slowdowns."
                )
            }

            if event.contains(.critical) {
                print("🔴 Memory pressure CRITICAL detected")
                self.isUnderMemoryPressure = true
                // AGGRESSIVE: Cancel all operations and clear everything
                self.cancelGeneration()
                if self.context != nil {
                    self.inferenceQueue.async {
                        self.resetContext()
                        print("🚨 Emergency memory cleanup: KV cache cleared")
                    }
                }
                // Log error for user visibility
                ErrorLogger.shared.logError(
                    code: ErrorCode.memoryPressure,
                    operation: "Memory Management",
                    technicalDetails: "Critical memory pressure detected. AI operations paused to prevent system instability."
                )
            }
        }

        source.resume()
        memoryPressureSource = source
        print("✅ Memory pressure monitoring enabled with aggressive response")
    }

    // MARK: - Model Loading

    /// Loads the specified GGUF model from the app bundle or Application Support
    /// This is an async operation that should be called once on app launch
    /// - Parameter modelType: The AI model to load (defaults to TinyLlama)
    func loadModel(_ modelType: AIModel = .tinyLlama) async throws {
        // If already loaded with same model, skip
        if isLoaded, currentModel == modelType {
            return
        }

        // If different model requested, unload current model first
        if isLoaded, currentModel != modelType {
            print("🔄 Switching from \(currentModel.displayName) to \(modelType.displayName)")
            unloadModel()
        }

        currentModel = modelType

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            inferenceQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: LLMError.modelNotFound)
                    return
                }

                do {
                    // Get model path from bundle or Application Support (with verbose logging)
                    guard let modelPath = self.getModelPath(for: modelType, verbose: true) else {
                        throw LLMError.modelNotFound
                    }

                    print("📦 Loading \(modelType.displayName) from: \(modelPath)")

                    // Log memory BEFORE loading
                    var taskInfoBefore = mach_task_basic_info()
                    var countBefore = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
                    let kerrBefore = withUnsafeMutablePointer(to: &taskInfoBefore) {
                        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &countBefore)
                        }
                    }
                    if kerrBefore == KERN_SUCCESS {
                        let memoryBeforeMB = Double(taskInfoBefore.resident_size) / 1024 / 1024
                        print("📊 Memory BEFORE model load: \(String(format: "%.1f", memoryBeforeMB)) MB")
                    }

                    // Initialize llama.cpp backend
                    llama_backend_init()
                    llama_numa_init(GGML_NUMA_STRATEGY_DISABLED)

                    // Set up model parameters
                    var modelParams = llama_model_default_params()
                    modelParams.n_gpu_layers = ModelConfig.gpuLayers // Use Metal GPU acceleration

                    // Load the model using the new API
                    guard let loadedModel = llama_model_load_from_file(modelPath, modelParams) else {
                        throw LLMError.modelLoadFailed
                    }
                    self.model = loadedModel

                    // Create context parameters
                    var contextParams = llama_context_default_params()
                    contextParams.n_ctx = UInt32(modelType.maxContextSize)
                    contextParams.n_batch = UInt32(modelType.optimalBatchSize)
                    contextParams.n_threads = ModelConfig.threads
                    contextParams.n_threads_batch = ModelConfig.threads
                    contextParams.embeddings = true // Enable embeddings extraction
                    contextParams.pooling_type = LLAMA_POOLING_TYPE_MEAN // Use mean pooling for embeddings

                    // Create the context using the new API
                    guard let ctx = llama_init_from_model(loadedModel, contextParams) else {
                        llama_model_free(loadedModel)
                        throw LLMError.modelLoadFailed
                    }
                    self.context = ctx

                    // Create sampler chain
                    var samplerParams = llama_sampler_chain_default_params()
                    samplerParams.no_perf = false
                    guard let samplerChain = llama_sampler_chain_init(samplerParams) else {
                        llama_free(ctx)
                        llama_model_free(loadedModel)
                        throw LLMError.modelLoadFailed
                    }

                    // Add samplers to the chain with TinyLlama-optimized parameters
                    // Based on official HuggingFace recommendations: top_k=50, top_p=0.95
                    if let topK = llama_sampler_init_top_k(50) { // Increased from 40
                        llama_sampler_chain_add(samplerChain, topK)
                    }
                    if let topP = llama_sampler_init_top_p(0.95, 1) { // Increased from 0.9
                        llama_sampler_chain_add(samplerChain, topP)
                    }
                    if let temp = llama_sampler_init_temp(0.7) { // Default, will be overridden per request
                        llama_sampler_chain_add(samplerChain, temp)
                    }
                    if let dist = llama_sampler_init_dist(LLAMA_DEFAULT_SEED) {
                        llama_sampler_chain_add(samplerChain, dist)
                    }

                    self.sampler = samplerChain

                    self.isLoaded = true

                    // Extract model metadata
                    self.extractModelMetadata()

                    print("✅ Model loaded successfully with Metal GPU acceleration")
                    print(
                        "📊 Model specs: Context=\(modelType.maxContextSize) tokens, Batch=\(modelType.optimalBatchSize) tokens"
                    )

                    // Log memory AFTER loading
                    var taskInfoAfter = mach_task_basic_info()
                    var countAfter = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
                    let kerrAfter = withUnsafeMutablePointer(to: &taskInfoAfter) {
                        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &countAfter)
                        }
                    }
                    if kerrAfter == KERN_SUCCESS {
                        let memoryAfterMB = Double(taskInfoAfter.resident_size) / 1024 / 1024
                        print("📊 Memory AFTER model load: \(String(format: "%.1f", memoryAfterMB)) MB")
                        if kerrBefore == KERN_SUCCESS {
                            let memoryBeforeMB = Double(taskInfoBefore.resident_size) / 1024 / 1024
                            let delta = memoryAfterMB - memoryBeforeMB
                            print("📊 Memory delta: +\(String(format: "%.1f", delta)) MB")
                        }
                    }

                    continuation.resume()

                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Unloads the model and frees memory
    func unloadModel() {
        inferenceQueue.sync {
            // Wrap in autorelease pool to immediately release temporary objects
            autoreleasepool {
                if let smpl = sampler {
                    llama_sampler_free(smpl)
                    sampler = nil
                }

                if let ctx = context {
                    // Clear KV cache before freeing to release buffers
                    let mem = llama_get_memory(ctx)
                    llama_memory_clear(mem, true)

                    llama_free(ctx)
                    context = nil
                }

                if let mdl = model {
                    llama_model_free(mdl)
                    model = nil
                }

                llama_backend_free()
                isLoaded = false
                print("🔄 Model unloaded and memory freed from process")
            }

            // REALITY CHECK: We cannot force macOS to release system memory
            // macOS will hold onto "free" memory for caching until another app needs it
            // This is normal and expected behavior - not a memory leak

            // Log memory status (will show resident memory, which macOS controls)
            Task {
                // Small delay to allow cleanup threads to complete
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

                var taskInfo = mach_task_basic_info()
                var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
                let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                        task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
                    }
                }

                if kerr == KERN_SUCCESS {
                    let usedMemoryMB = Double(taskInfo.resident_size) / 1024 / 1024
                    print("📊 Resident memory: \(String(format: "%.1f", usedMemoryMB)) MB")
                    print("ℹ️  Note: macOS may keep this cached until system needs memory")
                }
            }
        }
    }

    // MARK: - Inference

    /// Generates text using proper chat template formatting
    /// This is the RECOMMENDED way to generate text - uses model's built-in chat template
    /// - Parameters:
    ///   - systemMessage: The system instruction
    ///   - userMessage: The user's input text
    ///   - maxTokens: Maximum number of tokens to generate
    ///   - temperature: Sampling temperature (0.0 = deterministic, 1.0 = creative)
    ///   - grammar: Optional GBNF grammar string to constrain output format
    /// - Returns: Generated text
    func generateWithChatTemplate(
        systemMessage: String,
        userMessage: String,
        maxTokens: Int? = nil,
        temperature: Float = 0.7,
        grammar: String? = nil
    ) async -> String? {
        guard isLoaded else {
            print("⚠️ Model not loaded")
            ErrorLogger.shared.logError(
                code: .modelNotLoaded,
                operation: "Chat Generation",
                technicalDetails: "isLoaded = false"
            )
            return nil
        }

        return await withCheckedContinuation { continuation in
            inferenceQueue.async { [weak self] in
                autoreleasepool {
                    guard let self = self,
                          let mdl = self.model
                    else {
                        ErrorLogger.shared.logError(
                            code: .modelLoadFailed,
                            operation: "Chat Generation",
                            technicalDetails: "Model was unloaded or service was deallocated"
                        )
                        continuation.resume(returning: nil)
                        return
                    }

                    // Get model's chat template
                    let tmpl = llama_model_chat_template(mdl, nil)

                    // If no chat template, fall back to simple prompt format
                    if tmpl == nil {
                        print("⚠️ Model has no chat template, falling back to simple format")
                        let fallbackPrompt = "\(systemMessage)\n\n\(userMessage)"

                        Task {
                            let result = await self.generate(
                                prompt: fallbackPrompt,
                                maxTokens: maxTokens,
                                temperature: temperature,
                                grammar: grammar
                            )
                            continuation.resume(returning: result)
                        }
                        return
                    }

                    // Build messages array using Swift-safe memory management
                    // Store strings to keep them alive during C API call
                    let systemMsgString = systemMessage
                    let userMsgString = userMessage
                    let systemRoleString = "system"
                    let userRoleString = "user"

                    let requiredSize = systemRoleString.withCString { systemRolePtr in
                        userRoleString.withCString { userRolePtr in
                            systemMsgString.withCString { systemPtr in
                                userMsgString.withCString { userPtr in
                                    var messages: [llama_chat_message] = [
                                        llama_chat_message(role: systemRolePtr, content: systemPtr),
                                        llama_chat_message(role: userRolePtr, content: userPtr)
                                    ]
                                    return llama_chat_apply_template(tmpl, &messages, 2, true, nil, 0)
                                }
                            }
                        }
                    }

                    guard requiredSize > 0 else {
                        print("❌ Failed to calculate chat template size")
                        continuation.resume(returning: nil)
                        return
                    }

                    // Allocate buffer and apply template
                    var buffer = [CChar](repeating: 0, count: Int(requiredSize) + 1)
                    let actualSize = systemRoleString.withCString { systemRolePtr in
                        userRoleString.withCString { userRolePtr in
                            systemMsgString.withCString { systemPtr in
                                userMsgString.withCString { userPtr in
                                    var messages: [llama_chat_message] = [
                                        llama_chat_message(role: systemRolePtr, content: systemPtr),
                                        llama_chat_message(role: userRolePtr, content: userPtr)
                                    ]
                                    return llama_chat_apply_template(
                                        tmpl,
                                        &messages,
                                        2,
                                        true,
                                        &buffer,
                                        Int32(buffer.count)
                                    )
                                }
                            }
                        }
                    }

                    guard actualSize > 0 else {
                        print("❌ Failed to apply chat template")
                        ErrorLogger.shared.logError(
                            code: .generationFailed,
                            operation: "Chat Generation",
                            technicalDetails: "Chat template application returned size: \(actualSize)"
                        )
                        continuation.resume(returning: nil)
                        return
                    }

                    let prompt = String(cString: buffer)
                    print("📝 Chat template applied, prompt length: \(prompt.count) chars")

                    // Now call the regular generate function with the formatted prompt
                    Task {
                        let result = await self.generate(
                            prompt: prompt,
                            maxTokens: maxTokens,
                            temperature: temperature,
                            grammar: grammar
                        )
                        continuation.resume(returning: result)
                    }
                }
            }
        }
    }

    /// Cancels any ongoing text generation
    /// Safe to call even if no generation is in progress
    func cancelGeneration() {
        shouldCancelGeneration = true
        print("🛑 Generation cancellation requested")
    }

    /// Generates text completion for the given prompt
    /// - Parameters:
    ///   - prompt: The input text prompt
    ///   - maxTokens: Maximum number of tokens to generate (nil = use model's max context)
    ///   - temperature: Sampling temperature (0.0 = deterministic, 1.0 = creative)
    ///   - grammar: Optional GBNF grammar string to constrain output format (e.g., JSON schema)
    ///   - timeout: Maximum time in seconds for generation (default: 10.0)
    /// - Returns: Generated text
    func generate(
        prompt: String,
        maxTokens: Int? = nil,
        temperature: Float = 0.7,
        grammar: String? = nil,
        timeout: TimeInterval = 10.0
    ) async -> String? {
        guard isLoaded else {
            print("⚠️ Model not loaded")
            ErrorLogger.shared.logError(
                code: .modelNotLoaded,
                operation: "Text Generation",
                technicalDetails: "isLoaded = false"
            )
            return nil
        }

        // NOTE: Removed cancelGeneration() to allow concurrent queuing of operations
        // The serial inferenceQueue will naturally handle one operation at a time
        // without canceling other queued operations

        return await withCheckedContinuation { continuation in
            inferenceQueue.async { [weak self] in
                // Wrap entire generation in autorelease pool to prevent memory buildup
                autoreleasepool {
                    guard let self = self,
                          let ctx = self.context,
                          let mdl = self.model,
                          let smpl = self.sampler
                    else {
                        ErrorLogger.shared.logError(
                            code: .modelLoadFailed,
                            operation: "Text Generation",
                            technicalDetails: "Model, context, or sampler was unloaded during generation"
                        )
                        continuation.resume(returning: nil)
                        return
                    }

                    // Reset cancellation flag at start of new generation
                    self.shouldCancelGeneration = false

                    print("\n🚀 === Text Generation Started ===")
                    print("📝 Prompt: \(prompt.prefix(150))\(prompt.count > 150 ? "..." : "")")
                    print("📊 Prompt length: \(prompt.count) chars")

                    // Check if we need to prune KV cache before generation
                    self.pruneKVCacheIfNeeded(addingTokens: Int32(prompt.count / 4)) // Rough estimate

                    // CRITICAL: Clear memory FIRST before checking availability
                    // This ensures we're measuring actual available memory, not fragmented memory
                    let mem = llama_get_memory(ctx)
                    llama_memory_clear(mem, true) // Clear both metadata AND data buffer

                    // Small delay to allow memory to actually be freed
                    Thread.sleep(forTimeInterval: 0.05)

                    // Check memory before starting generation
                    let memCheck = self.hassufficientMemory()
                    if !memCheck.available {
                        print("❌ Insufficient memory for generation - aborting")
                        ErrorLogger.shared.logError(
                            code: .insufficientMemory,
                            operation: "Text Generation",
                            technicalDetails: "Free: \(String(format: "%.1f", memCheck.freeMemoryMB)) MB, Required: \(ModelConfig.minFreeMemoryMB) MB"
                        )
                        continuation.resume(returning: nil)
                        return
                    }

                    // Free old sampler and create new one with current temperature
                    llama_sampler_free(smpl)

                    // Create new sampler chain with request-specific temperature
                    var samplerParams = llama_sampler_chain_default_params()
                    samplerParams.no_perf = false
                    guard let newSamplerChain = llama_sampler_chain_init(samplerParams) else {
                        print("❌ Failed to create sampler chain")
                        ErrorLogger.shared.logError(
                            code: .generationFailed,
                            operation: "Text Generation",
                            technicalDetails: "Could not initialize sampler chain for text generation"
                        )
                        continuation.resume(returning: nil)
                        return
                    }

                    // Add samplers with request-specific temperature
                    if let topK = llama_sampler_init_top_k(50) {
                        llama_sampler_chain_add(newSamplerChain, topK)
                    }
                    if let topP = llama_sampler_init_top_p(0.95, 1) {
                        llama_sampler_chain_add(newSamplerChain, topP)
                    }

                    // Add repetition penalties to improve output quality
                    // penalty_last_n: Consider last 64 tokens for repetition
                    // penalty_repeat: 1.1 = slight penalty for repeating tokens
                    // penalty_freq: 0.0 = disabled (frequency penalty)
                    // penalty_present: 0.0 = disabled (presence penalty)
                    if let penalties = llama_sampler_init_penalties(64, 1.1, 0.0, 0.0) {
                        llama_sampler_chain_add(newSamplerChain, penalties)
                    }

                    if let temp = llama_sampler_init_temp(temperature) { // Use request-specific temperature
                        llama_sampler_chain_add(newSamplerChain, temp)
                    }

                    // Add grammar sampler if grammar is provided
                    if let grammarStr = grammar {
                        let vocab = llama_model_get_vocab(mdl)
                        if let grammarSampler = llama_sampler_init_grammar(vocab, grammarStr, "root") {
                            llama_sampler_chain_add(newSamplerChain, grammarSampler)
                            print("📐 Grammar sampler enabled")
                        } else {
                            print("⚠️ Failed to initialize grammar sampler")
                        }
                    }

                    if let dist = llama_sampler_init_dist(LLAMA_DEFAULT_SEED) {
                        llama_sampler_chain_add(newSamplerChain, dist)
                    }

                    self.sampler = newSamplerChain
                    let grammarStatus = grammar != nil ? ", grammar enabled" : ""
                    print(
                        "🧹 Context fully reset (KV cache + data cleared, sampler recreated with temp=\(temperature), penalties enabled\(grammarStatus))"
                    )

                    // Determine max generation length using current model's context size
                    let contextSize = Int32(self.currentModel.maxContextSize)
                    let batchSize = Int32(self.currentModel.optimalBatchSize)

                    // Tokenize the prompt
                    let maxBufferSize = prompt.count + 2048 // Generous buffer
                    var tokens = [llama_token](repeating: 0, count: maxBufferSize)

                    print("🔍 About to tokenize prompt of \(prompt.count) chars with buffer size \(maxBufferSize)")
                    print("📋 Full prompt text:\n\(prompt)")

                    let tokenCount = prompt.withCString { promptCStr in
                        llama_tokenize(
                            llama_model_get_vocab(mdl),
                            promptCStr,
                            Int32(prompt.count),
                            &tokens,
                            Int32(tokens.count),
                            true, // add_special
                            false // parse_special
                        )
                    }

                    guard tokenCount > 0 else {
                        print("❌ Failed to tokenize prompt")
                        ErrorLogger.shared.logError(
                            code: .tokenizationFailed,
                            operation: "Text Generation",
                            technicalDetails: "Token count was 0 or negative"
                        )
                        continuation.resume(returning: nil)
                        return
                    }

                    print("✅ Tokenized: \(tokenCount) tokens (\(prompt.count) chars → \(tokenCount) tokens)")
                    print("📊 Ratio: \(String(format: "%.2f", Double(prompt.count) / Double(tokenCount))) chars/token")

                    // Check if prompt exceeds batch size and truncate if necessary
                    let maxPromptTokens = batchSize
                    if tokenCount > maxPromptTokens {
                        print(
                            "⚠️ Prompt token count (\(tokenCount)) exceeds batch size (\(maxPromptTokens)), truncating prompt"
                        )
                        ErrorLogger.shared.logWarning(
                            code: .generationTruncated,
                            operation: "Text Generation",
                            details: "Prompt: \(tokenCount) tokens, Batch size: \(maxPromptTokens) tokens. Truncating to fit."
                        )
                    }

                    // Keep only the valid tokens, limited to batch size
                    // CRITICAL: Also limit to a safe maximum to prevent memory allocation failures
                    // Even if batch size allows more, we cap at a conservative limit for stability
                    let safeMaxTokens = min(Int(maxPromptTokens), 1024) // Never exceed 1024 tokens for prompt
                    let validTokenCount = min(Int(tokenCount), safeMaxTokens)
                    var promptTokens = Array(tokens.prefix(validTokenCount))
                    let promptTokenCount = Int32(promptTokens.count)

                    if validTokenCount < Int(tokenCount) {
                        print("🔒 Prompt limited to \(promptTokenCount) tokens for safety (was \(tokenCount))")
                    }

                    // Safety check: Ensure prompt token count is valid and not too large
                    if promptTokenCount <= 0 {
                        print("❌ Invalid prompt token count: \(promptTokenCount)")
                        ErrorLogger.shared.logError(
                            code: .tokenizationFailed,
                            operation: "Text Generation",
                            technicalDetails: "Token count: \(promptTokenCount)"
                        )
                        continuation.resume(returning: nil)
                        return
                    }

                    // Additional safety: verify token count doesn't exceed context size
                    if promptTokenCount > contextSize {
                        print("❌ Prompt tokens (\(promptTokenCount)) exceed context size (\(contextSize))")
                        ErrorLogger.shared.logError(
                            code: .promptTooLarge,
                            operation: "Text Generation",
                            technicalDetails: "Prompt: \(promptTokenCount) tokens, Context: \(contextSize) tokens"
                        )
                        continuation.resume(returning: nil)
                        return
                    }

                    print("🔄 Processing \(promptTokenCount) prompt tokens...")

                    // Create batch using the new API with error handling and retry logic
                    // Important: tokens array must remain valid for the lifetime of the batch
                    var decodeResult: Int32 = -1
                    var retryCount = 0
                    let maxRetries = 2

                    while retryCount <= maxRetries, decodeResult != 0 {
                        if retryCount > 0 {
                            print("🔄 Retry attempt \(retryCount)/\(maxRetries) for prompt decoding...")
                            // Clear cache before retry
                            self.resetContext()
                            // Brief pause before retry
                            Thread.sleep(forTimeInterval: 0.1)
                        }

                        decodeResult = promptTokens.withUnsafeMutableBufferPointer { tokensPtr -> Int32 in
                            // Safety check: Ensure pointer is valid
                            guard let baseAddress = tokensPtr.baseAddress, promptTokenCount > 0 else {
                                print("❌ Invalid token buffer or count")
                                return -3 // Special error code for invalid buffer
                            }

                            // Additional safety: verify count matches buffer size
                            if Int(promptTokenCount) > tokensPtr.count {
                                print("❌ Token count (\(promptTokenCount)) exceeds buffer size (\(tokensPtr.count))")
                                return -3
                            }

                            // Check memory before Metal operations
                            let memCheck = self.hassufficientMemory()
                            if !memCheck.available {
                                print(
                                    "⚠️ Memory pressure detected during decode - free: \(String(format: "%.1f", memCheck.freeMemoryMB)) MB"
                                )
                                return -2 // Special error code for memory pressure
                            }

                            let batch = llama_batch_get_one(baseAddress, promptTokenCount)

                            // Call llama_decode directly (it returns Int32, doesn't throw)
                            let result = llama_decode(ctx, batch)
                            return result
                        }

                        if decodeResult == 0 {
                            break // Success
                        } else if decodeResult == -2 {
                            print("❌ Memory pressure prevented decode - aborting")
                            break // Don't retry on memory pressure
                        } else if decodeResult == -3 {
                            print("❌ Invalid token buffer - aborting")
                            break // Don't retry on invalid buffer
                        }

                        retryCount += 1
                    }

                    if decodeResult != 0 {
                        print("❌ Failed to decode prompt after \(retryCount) attempts (error code: \(decodeResult))")
                        ErrorLogger.shared.logError(
                            code: .decodeFailed,
                            operation: "Text Generation",
                            technicalDetails: "Decode result code: \(decodeResult), Retries: \(retryCount)"
                        )
                        // Clean up before returning
                        self.resetContext()
                        continuation.resume(returning: nil)
                        return
                    }

                    print("✅ Prompt processed successfully")

                    // Track generation start time for timeout
                    let generationStartTime = Date()

                    // Generate tokens
                    var generatedTokens: [llama_token] = []
                    var nCur = tokenCount

                    // If maxTokens is nil, use remaining context size; otherwise use specified limit
                    let maxGenTokens = maxTokens ?? Int(contextSize - tokenCount)
                    let nLen = nCur + Int32(maxGenTokens)

                    print(
                        "🎯 Generating up to \(maxGenTokens) new tokens (temp: \(String(format: "%.1f", temperature)))..."
                    )

                    var lastProgressPrint = Date()
                    let progressInterval: TimeInterval = 2.0 // Print progress every 2 seconds

                    let vocab = llama_model_get_vocab(mdl)

                    while nCur < nLen {
                        // Check for cancellation request
                        if self.shouldCancelGeneration {
                            print("🛑 Generation cancelled by request")
                            continuation.resume(returning: nil)
                            return
                        }

                        // Check for timeout
                        let elapsedTime = Date().timeIntervalSince(generationStartTime)
                        if elapsedTime >= timeout {
                            print("⏱️ Generation timeout reached (\(String(format: "%.1f", timeout))s)")
                            print("   Generated \(generatedTokens.count) tokens before timeout")

                            // Log timeout as a warning (it's recoverable - returns partial results)
                            ErrorLogger.shared.logWarning(
                                code: .generationTruncated,
                                operation: "Text Generation",
                                details: "Timeout: \(String(format: "%.1f", timeout))s, Generated \(generatedTokens.count) tokens. Returning partial results."
                            )

                            // Return what we have so far instead of nil
                            break
                        }

                        // Sample the next token using the sampler chain
                        let newTokenId = llama_sampler_sample(newSamplerChain, ctx, -1)

                        // Accept the token
                        llama_sampler_accept(newSamplerChain, newTokenId)

                        // Check for end of sequence
                        if llama_vocab_is_eog(vocab, newTokenId) {
                            print("🏁 End-of-generation token detected")
                            break
                        }

                        // Store the generated token
                        generatedTokens.append(newTokenId)

                        // Print periodic progress updates
                        let now = Date()
                        let tokensGenerated = generatedTokens.count
                        if now.timeIntervalSince(lastProgressPrint) >= progressInterval {
                            let progress = Double(tokensGenerated) / Double(maxGenTokens) * 100
                            print(
                                "⏳ Progress: \(tokensGenerated)/\(maxGenTokens) tokens (\(String(format: "%.1f", progress))%)"
                            )
                            lastProgressPrint = now
                        }

                        // Create new batch with the new token
                        nCur += 1

                        // Decode the new token - keep token alive during decode
                        var newToken = newTokenId
                        var decodeResult: Int32 = -1
                        var decodeRetryCount = 0
                        let maxDecodeRetries = 1 // Fewer retries during token generation

                        while decodeRetryCount <= maxDecodeRetries, decodeResult != 0 {
                            decodeResult = withUnsafeMutablePointer(to: &newToken) { tokenPtr -> Int32 in
                                // Quick memory check
                                let memCheck = self.hassufficientMemory()
                                if !memCheck.available {
                                    print("⚠️ Memory pressure during token generation")
                                    return -2
                                }

                                let batch = llama_batch_get_one(tokenPtr, 1)

                                // Call llama_decode directly (it returns Int32, doesn't throw)
                                let result = llama_decode(ctx, batch)
                                return result
                            }

                            if decodeResult != 0, decodeRetryCount < maxDecodeRetries {
                                print("🔄 Retrying token decode at position \(nCur)...")
                                Thread.sleep(forTimeInterval: 0.05)
                                decodeRetryCount += 1
                            } else {
                                break
                            }
                        }

                        if decodeResult != 0 {
                            print(
                                "❌ Failed to decode token at position \(nCur) after \(decodeRetryCount) retries (error: \(decodeResult))"
                            )
                            // Clean up before breaking
                            self.resetContext()
                            break
                        }
                    }

                    // Detokenize all generated tokens at once using llama_detokenize
                    var generatedText = ""
                    if !generatedTokens.isEmpty {
                        // Calculate required buffer size
                        let estimatedSize = generatedTokens.count * 16 // Estimate ~16 bytes per token
                        var textBuffer = [CChar](repeating: 0, count: estimatedSize)

                        let resultSize = generatedTokens.withUnsafeBufferPointer { tokensPtr in
                            llama_detokenize(
                                vocab,
                                tokensPtr.baseAddress,
                                Int32(generatedTokens.count),
                                &textBuffer,
                                Int32(textBuffer.count),
                                false, // remove_special
                                false // unparse_special
                            )
                        }

                        if resultSize > 0 {
                            if resultSize < textBuffer.count {
                                // Success - buffer was large enough
                                generatedText = String(cString: textBuffer)
                            } else {
                                // Buffer was too small, reallocate with exact size
                                var largerBuffer = [CChar](repeating: 0, count: Int(resultSize) + 1)
                                let finalSize = generatedTokens.withUnsafeBufferPointer { tokensPtr in
                                    llama_detokenize(
                                        vocab,
                                        tokensPtr.baseAddress,
                                        Int32(generatedTokens.count),
                                        &largerBuffer,
                                        Int32(largerBuffer.count),
                                        false,
                                        false
                                    )
                                }
                                if finalSize > 0 {
                                    generatedText = String(cString: largerBuffer)
                                }
                            }
                        }
                    }

                    let tokensGenerated = Int(nCur - tokenCount)

                    // Update KV cache token count
                    self.currentKVCacheTokenCount += Int32(tokensGenerated)
                    print("📊 KV cache now contains ~\(self.currentKVCacheTokenCount) tokens (limit: \(ModelConfig.maxKVCacheTokens))")

                    // Collect performance metrics from llama.cpp
                    let perfData = llama_perf_context(ctx)
                    let perfMetrics = PerformanceMetrics(
                        promptTokens: Int(perfData.n_p_eval),
                        generatedTokens: Int(perfData.n_eval),
                        promptTime: perfData.t_p_eval_ms,
                        generationTime: perfData.t_eval_ms,
                        tokensPerSecond: (perfData.n_eval > 0 && perfData.t_eval_ms > 0.001) ? (
                            Double(perfData.n_eval) / (perfData.t_eval_ms / 1000.0)
                        ) : 0
                    )

                    // Update published metrics on main thread
                    DispatchQueue.main.async {
                        self.lastPerformanceMetrics = perfMetrics
                    }

                    // Update SystemMonitor with performance data
                    Task { @MainActor in
                        SystemMonitor.shared.recordTokensPerSecond(perfMetrics.tokensPerSecond)
                        SystemMonitor.shared.recordInference(duration: perfMetrics.totalTime)
                    }

                    // Reset performance counters for next generation
                    llama_perf_context_reset(ctx)

                    print("✅ Generation complete: \(tokensGenerated) tokens → \(generatedText.count) chars")
                    print(
                        "⚡ Performance: \(String(format: "%.1f", perfMetrics.tokensPerSecond)) t/s, prompt: \(String(format: "%.0f", perfMetrics.promptTime))ms, gen: \(String(format: "%.0f", perfMetrics.generationTime))ms"
                    )
                    print("🔍 Debug - n_eval: \(perfData.n_eval), t_eval_ms: \(perfData.t_eval_ms)")
                    print("📄 Output preview: \(generatedText.prefix(200))\(generatedText.count > 200 ? "..." : "")")
                    print("=== Generation Complete ===\n")

                    // Warn if generation produced empty output despite valid input
                    if generatedText.isEmpty && !prompt.isEmpty {
                        print("⚠️ Warning: Generated empty output despite valid prompt")
                        ErrorLogger.shared.logWarning(
                            code: .generationEmpty,
                            operation: "Text Generation",
                            details: "Model generated \(tokensGenerated) tokens but resulted in empty text. Prompt length: \(prompt.count) chars"
                        )
                    }

                    continuation.resume(returning: generatedText)
                } // End autoreleasepool
            }
        }
    }

    /// Generates text completion with automatic batching for large prompts
    /// Chunks text by sentences and processes each chunk separately
    /// - Parameters:
    ///   - text: The input text to process
    ///   - instruction: The instruction/prompt template (should contain {content} placeholder)
    ///   - maxTokens: Maximum number of tokens to generate per chunk
    ///   - temperature: Sampling temperature
    ///   - separator: String to join processed chunks (default: single space)
    /// - Returns: Combined generated text
    func generateBatched(
        text: String,
        instruction: String,
        maxTokens: Int? = nil,
        temperature: Float = 0.7,
        separator: String = " "
    ) async -> String? {
        guard !text.isEmpty else { return nil }

        // Get the current model's batch size and calculate chunk size
        // Leave 30% buffer for the prompt template overhead
        let modelBatchSize = Int(currentModel.optimalBatchSize)
        let maxTokensPerChunk = Int(Double(modelBatchSize) * 0.7)

        // Create chunker with model-aware token limit
        let chunker = TextChunker(maxTokensPerChunk: maxTokensPerChunk)
        let chunks = chunker.chunk(text)

        // If only one chunk, process normally without batching
        if chunks.count == 1 {
            let prompt = instruction.replacingOccurrences(of: "{content}", with: text)
            return await generate(
                prompt: prompt,
                maxTokens: maxTokens,
                temperature: temperature
            )
        }

        // Process each chunk
        print("📦 Batched generation: Processing large text in \(chunks.count) batches...")
        var processedChunks: [String] = []

        for (index, chunk) in chunks.enumerated() {
            print("   Batch \(index + 1)/\(chunks.count): \(chunk.count) chars")

            let prompt = instruction.replacingOccurrences(of: "{content}", with: chunk)

            guard let output = await generate(
                prompt: prompt,
                maxTokens: maxTokens,
                temperature: temperature
            ) else {
                print("   ⚠️ Batch \(index + 1) failed, skipping")
                continue
            }

            if !output.isEmpty {
                processedChunks.append(output)
            }
        }

        if processedChunks.isEmpty {
            print("❌ All batches failed")
            ErrorLogger.shared.logError(
                code: .generationFailed,
                operation: "Batched Generation",
                technicalDetails: "Attempted to process \(chunks.count) chunks, all failed"
            )
            return nil
        }

        // Warn if some batches failed
        if processedChunks.count < chunks.count {
            print("⚠️ Warning: Some batches failed (\(processedChunks.count)/\(chunks.count) succeeded)")
            ErrorLogger.shared.logWarning(
                code: .batchProcessingIncomplete,
                operation: "Batched Generation",
                details: "Only \(processedChunks.count) out of \(chunks.count) batches succeeded. Output may be incomplete."
            )
        }

        print("✅ Successfully processed \(processedChunks.count)/\(chunks.count) batches")
        return processedChunks.joined(separator: separator)
    }

    /// Generates embedding vector for the given text
    /// - Parameter text: Input text to embed
    /// - Returns: Float array representing the embedding (typically 768 or 2048 dimensions)
    func generateEmbedding(for text: String) async -> [Float]? {
        guard isLoaded else {
            print("⚠️ Model not loaded")
            ErrorLogger.shared.logError(
                code: .modelNotLoaded,
                operation: "Embedding Generation",
                technicalDetails: "isLoaded = false"
            )
            return nil
        }

        return await withCheckedContinuation { continuation in
            inferenceQueue.async { [weak self] in
                // Wrap in autorelease pool to prevent memory buildup
                autoreleasepool {
                    guard let self = self,
                          let ctx = self.context,
                          let mdl = self.model
                    else {
                        ErrorLogger.shared.logError(
                            code: .modelLoadFailed,
                            operation: "Embedding Generation",
                            technicalDetails: "Model or context was unloaded during generation"
                        )
                        continuation.resume(returning: nil)
                        return
                    }

                    // Clear KV cache before embedding generation
                    let mem = llama_get_memory(ctx)
                    llama_memory_clear(mem, false) // Clear metadata only

                    // Tokenize the text
                    var tokens = [llama_token](repeating: 0, count: text.count + 16)
                    let tokenCount = text.withCString { textCStr in
                        llama_tokenize(
                            llama_model_get_vocab(mdl),
                            textCStr,
                            Int32(text.count),
                            &tokens,
                            Int32(tokens.count),
                            true,
                            false
                        )
                    }

                    guard tokenCount > 0 else {
                        print("❌ Failed to tokenize text for embedding")
                        ErrorLogger.shared.logError(
                            code: .tokenizationFailed,
                            operation: "Embedding Generation",
                            technicalDetails: "Text: '\(text.prefix(100))...', Length: \(text.count) chars"
                        )
                        continuation.resume(returning: nil)
                        return
                    }

                    // Check if token count exceeds batch size
                    let batchSize = self.currentModel.optimalBatchSize
                    if tokenCount > batchSize {
                        print("⚠️ Token count (\(tokenCount)) exceeds batch size (\(batchSize)), truncating")
                    }

                    // Keep only the valid tokens, limited to batch size
                    let validTokenCount = min(Int(tokenCount), Int(batchSize))
                    var embeddingTokens = Array(tokens.prefix(validTokenCount))
                    let embeddingTokenCount = Int32(embeddingTokens.count)

                    // Create batch and decode - keep tokens alive during decode
                    let decodeResult = embeddingTokens.withUnsafeMutableBufferPointer { tokensPtr -> Int32 in
                        let batch = llama_batch_get_one(tokensPtr.baseAddress, embeddingTokenCount)
                        return llama_decode(ctx, batch)
                    }

                    if decodeResult != 0 {
                        print("❌ Failed to decode for embeddings")
                        ErrorLogger.shared.logError(
                            code: .decodeFailed,
                            operation: "Embedding Generation",
                            technicalDetails: "Decode result: \(decodeResult), Token count: \(embeddingTokenCount)"
                        )
                        continuation.resume(returning: nil)
                        return
                    }

                    // Get embeddings using sequence-level extraction (works with mean pooling)
                    let embeddingSize = llama_model_n_embd(mdl)
                    guard let embeddingsPtr = llama_get_embeddings_seq(ctx, 0) else {
                        print("❌ Failed to get embeddings")
                        ErrorLogger.shared.logError(
                            code: .generationFailed,
                            operation: "Embedding Generation",
                            technicalDetails: "Could not retrieve embedding vector from model context"
                        )
                        continuation.resume(returning: nil)
                        return
                    }

                    // Convert to Swift array
                    var embedding = Array(UnsafeBufferPointer(start: embeddingsPtr, count: Int(embeddingSize)))

                    // Normalize embeddings (L2 normalization)
                    let magnitude = sqrt(embedding.map { $0 * $0 }.reduce(0, +))
                    if magnitude > 0 {
                        embedding = embedding.map { $0 / magnitude }
                    }

                    print("✅ Generated embedding with \(embedding.count) dimensions (normalized)")
                    continuation.resume(returning: embedding)
                } // End autoreleasepool
            }
        }
    }

    // MARK: - Model Metadata Extraction

    /// Extracts metadata from the loaded GGUF model
    private func extractModelMetadata() {
        guard let mdl = model else { return }

        let paramCount = llama_model_n_params(mdl)
        let ctxTrain = llama_model_n_ctx_train(mdl)
        let embdSize = llama_model_n_embd(mdl)
        let layers = llama_model_n_layer(mdl)
        let heads = llama_model_n_head(mdl)

        // Get model description
        var descBuffer = [CChar](repeating: 0, count: 256)
        let descLen = llama_model_desc(mdl, &descBuffer, descBuffer.count)
        let modelDesc = descLen > 0 ? String(cString: descBuffer) : currentModel.displayName

        modelMetadata = ModelMetadata(
            parameterCount: paramCount,
            description: modelDesc,
            contextSize: ctxTrain,
            embeddingSize: embdSize,
            layerCount: layers,
            headCount: heads
        )

        // Build tooltip for SystemMonitor
        let tooltip = """
        \(currentModel.displayName)
        Parameters: \(formatParameterCount(paramCount))
        Architecture: \(modelDesc)
        Context: \(ctxTrain) tokens
        Embedding: \(embdSize)
        Layers: \(layers) • Heads: \(heads)
        """

        print(
            "📊 Model metadata: \(formatParameterCount(paramCount)) params, \(ctxTrain) ctx, \(embdSize) embd, \(layers) layers"
        )
        print("💡 Setting SystemMonitor metadata tooltip: \(tooltip)")

        Task { @MainActor in
            SystemMonitor.shared.setModelMetadata(tooltip)
            print("✅ SystemMonitor metadata updated on main thread")
        }
    }

    /// Formats parameter count in human-readable format (e.g., "1.1B", "3.8B")
    private func formatParameterCount(_ count: UInt64) -> String {
        let billions = Double(count) / 1_000_000_000
        if billions >= 1.0 {
            return String(format: "%.1fB", billions)
        }
        let millions = Double(count) / 1_000_000
        return String(format: "%.0fM", millions)
    }

    // MARK: - Thread Control

    /// Sets the number of threads for generation and batch processing
    /// - Parameters:
    ///   - threads: Number of threads for single-token generation (0 = auto)
    ///   - batchThreads: Number of threads for batch processing (0 = auto)
    func setThreadCount(threads: Int32, batchThreads: Int32? = nil) {
        guard let ctx = context else { return }
        llama_set_n_threads(ctx, threads, batchThreads ?? threads)
        print("🔧 Thread count updated: generation=\(threads), batch=\(batchThreads ?? threads)")
    }

    /// Returns current thread configuration
    func getThreadCount() -> (generation: Int32, batch: Int32)? {
        guard let ctx = context else { return nil }
        return (llama_n_threads(ctx), llama_n_threads_batch(ctx))
    }

    // MARK: - Helpers

    private func getModelPath(for modelType: AIModel, verbose: Bool = false) -> String? {
        if verbose {
            print("🔍 Starting search for \(modelType.displayName)...")
        }

        let modelFileName = modelType.fileName
        let fileManager = FileManager.default

        // Extract base name without extension for Bundle.main.path
        let baseName = modelFileName.replacingOccurrences(of: ".gguf", with: "")

        // First, check if model exists in app bundle (Resources/Models/)
        if let bundlePath = Bundle.main.path(forResource: baseName, ofType: "gguf") {
            if verbose {
                print("✅ Found model in app bundle: \(bundlePath)")
            }
            return bundlePath
        }

        // Check in Resources/Models subdirectory of bundle
        if let resourcesPath = Bundle.main.resourcePath {
            let modelsPath = resourcesPath + "/Models/" + modelFileName
            if fileManager.fileExists(atPath: modelsPath) {
                if verbose {
                    print("✅ Found model in bundle Models: \(modelsPath)")
                }
                return modelsPath
            }
        }

        // Check in ~/Library/Application Support/ZetaNotes/Models/
        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let modelsDir = appSupport.appendingPathComponent("ZetaNotes/Models")
            let modelPath = modelsDir.appendingPathComponent(modelFileName)

            if fileManager.fileExists(atPath: modelPath.path) {
                if verbose {
                    print("✅ Found model in Application Support: \(modelPath.path)")
                }
                return modelPath.path
            }
        }

        // Development fallback removed - models should only load from:
        // 1. App bundle (for bundled models)
        // 2. Application Support (for user-downloaded models)
        // This prevents tools working after reset in development builds

        if verbose {
            print("❌ Model not found in any location")
            ErrorLogger.shared.logError(
                code: .modelNotFound,
                operation: "Model Loading",
                technicalDetails: "Model file: \(modelFileName). Searched in Application Support and development directories"
            )
        }
        return nil
    }

    /// Returns the Application Support directory path for storing models
    func getModelsDirectory() -> URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        else {
            return nil
        }
        return appSupport.appendingPathComponent("ZetaNotes/Models")
    }

    /// Checks if a model file exists locally
    func isModelDownloaded(_ modelType: AIModel) -> Bool {
        return getModelPath(for: modelType) != nil
    }

    /// Returns the loaded model type
    func getCurrentModel() -> AIModel {
        return currentModel
    }
}

// MARK: - Errors

enum LLMError: Error, LocalizedError {
    case modelNotFound
    case modelLoadFailed
    case inferenceFailed
    case invalidInput

    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "Model file not found. Place model files in ~/Library/Application Support/ZetaNotes/Models/ or use the download feature in settings."
        case .modelLoadFailed:
            return "Failed to load the AI model"
        case .inferenceFailed:
            return "Inference failed"
        case .invalidInput:
            return "Invalid input provided"
        }
    }
}
