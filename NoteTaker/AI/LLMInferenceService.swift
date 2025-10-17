//
//  LLMInferenceService.swift
//  NoteTaker
//
//  Low-level interface to GGUF models via llama.cpp
//  Supports TinyLlama 1.1B and Qwen2.5-3B
//  Uses llama.cpp for CPU/GPU inference on Apple Silicon
//

import Foundation

// MARK: - Model Types

/// Available AI models for the NoteTaker app
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
            return "Meta's tiny model with latest architecture. Better than TinyLlama despite same size."
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
            return "https://huggingface.co/microsoft/phi-2-GGUF/resolve/main/phi-2.Q4_K_M.gguf"
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
        static let contextSize: Int32 = 2048
        static let batchSize: Int32 = 512
        static let threads: Int32 = 0 // 0 = auto-detect optimal threads
        static let gpuLayers: Int32 = 99 // Use GPU acceleration on Apple Silicon
    }

    // MARK: - State

    private var model: OpaquePointer?
    private var context: OpaquePointer?
    private var sampler: UnsafeMutablePointer<llama_sampler>?
    private var isLoaded = false
    private var currentModel: AIModel = .tinyLlama
    private let inferenceQueue = DispatchQueue(label: "com.notetaker.inference", qos: .userInitiated)

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
                    contextParams.n_ctx = UInt32(ModelConfig.contextSize)
                    contextParams.n_batch = UInt32(ModelConfig.batchSize)
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
                    print("✅ Model loaded successfully with Metal GPU acceleration")
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
            if let smpl = sampler {
                llama_sampler_free(smpl)
                sampler = nil
            }

            if let ctx = context {
                llama_free(ctx)
                context = nil
            }

            if let mdl = model {
                llama_model_free(mdl)
                model = nil
            }

            llama_backend_free()
            isLoaded = false
            print("🔄 Model unloaded and memory freed")
        }
    }

    // MARK: - Inference

    /// Generates text completion for the given prompt
    /// - Parameters:
    ///   - prompt: The input text prompt
    ///   - maxTokens: Maximum number of tokens to generate (nil = use model's max context)
    ///   - temperature: Sampling temperature (0.0 = deterministic, 1.0 = creative)
    ///   - stopSequences: Sequences that stop generation when encountered
    /// - Returns: Generated text
    func generate(
        prompt: String,
        maxTokens: Int? = nil,
        temperature: Float = 0.7,
        stopSequences: [String] = []
    ) async -> String? {
        guard isLoaded else {
            print("⚠️ Model not loaded")
            return nil
        }

        return await withCheckedContinuation { continuation in
            inferenceQueue.async { [weak self] in
                guard let self = self,
                      let ctx = self.context,
                      let mdl = self.model,
                      let smpl = self.sampler
                else {
                    continuation.resume(returning: nil)
                    return
                }

                print("\n🚀 === Text Generation Started ===")
                print("📝 Prompt: \(prompt.prefix(150))\(prompt.count > 150 ? "..." : "")")
                print("📊 Prompt length: \(prompt.count) chars")

                // CRITICAL: Fully clear KV cache and reset sampler to prevent cross-contamination between requests
                // This ensures each generation starts with a completely clean slate
                let mem = llama_get_memory(ctx)
                llama_memory_clear(mem, true) // Clear both metadata AND data buffer for complete reset
                llama_sampler_reset(smpl) // Reset sampler state
                print("🧹 Context fully reset (KV cache + data cleared, sampler reset)")

                // Determine max generation length
                let contextSize = Int32(ModelConfig.contextSize)

                // Tokenize the prompt
                let maxBufferSize = prompt.count + 2048 // Generous buffer
                var tokens = [llama_token](repeating: 0, count: maxBufferSize)
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
                        "Failed to tokenize prompt",
                        severity: .error,
                        operation: "Text Generation",
                        details: "Token count was 0 or negative"
                    )
                    continuation.resume(returning: nil)
                    return
                }

                print("✅ Tokenized: \(tokenCount) tokens (\(prompt.count) chars → \(tokenCount) tokens)")

                // Keep only the valid tokens
                var promptTokens = Array(tokens.prefix(Int(tokenCount)))
                let promptTokenCount = Int32(promptTokens.count)

                // Create batch using the new API
                // Important: tokens array must remain valid for the lifetime of the batch
                print("🔄 Processing prompt tokens...")
                let decodeResult = promptTokens.withUnsafeMutableBufferPointer { tokensPtr -> Int32 in
                    let batch = llama_batch_get_one(tokensPtr.baseAddress, promptTokenCount)
                    return llama_decode(ctx, batch)
                }

                if decodeResult != 0 {
                    print("❌ Failed to decode prompt (error code: \(decodeResult))")
                    ErrorLogger.shared.logError(
                        "Failed to decode prompt",
                        severity: .error,
                        operation: "Text Generation",
                        details: "Decode result code: \(decodeResult)"
                    )
                    continuation.resume(returning: nil)
                    return
                }

                print("✅ Prompt processed successfully")

                // Generate tokens
                var generatedText = ""
                var nCur = tokenCount

                // If maxTokens is nil, use remaining context size; otherwise use specified limit
                let maxGenTokens = maxTokens ?? Int(contextSize - tokenCount)
                let nLen = nCur + Int32(maxGenTokens)

                print("🎯 Generating up to \(maxGenTokens) new tokens (temp: \(String(format: "%.1f", temperature)))...")

                var lastProgressPrint = Date()
                let progressInterval: TimeInterval = 2.0 // Print progress every 2 seconds

                while nCur < nLen {
                    // Sample the next token using the sampler chain
                    let newTokenId = llama_sampler_sample(smpl, ctx, -1)

                    // Accept the token
                    llama_sampler_accept(smpl, newTokenId)

                    // Check for end of sequence
                    let vocab = llama_model_get_vocab(mdl)
                    if llama_vocab_is_eog(vocab, newTokenId) {
                        print("🏁 End-of-generation token detected")
                        break
                    }

                    // Detokenize to text
                    var buf = [CChar](repeating: 0, count: 32)
                    let pieceSize = llama_token_to_piece(vocab, newTokenId, &buf, Int32(buf.count), 0, false)

                    if pieceSize > 0 {
                        let piece = String(cString: buf)
                        generatedText += piece

                        // Print periodic progress updates instead of every token
                        let now = Date()
                        let tokensGenerated = Int(nCur - tokenCount)
                        if now.timeIntervalSince(lastProgressPrint) >= progressInterval {
                            let progress = Double(tokensGenerated) / Double(maxGenTokens) * 100
                            print(
                                "⏳ Progress: \(tokensGenerated)/\(maxGenTokens) tokens (\(String(format: "%.1f", progress))%) - \(generatedText.count) chars"
                            )
                            lastProgressPrint = now
                        }

                        // Check for stop sequences
                        if !stopSequences.isEmpty {
                            for stopSeq in stopSequences where generatedText.contains(stopSeq) {
                                if let range = generatedText.range(of: stopSeq) {
                                    generatedText = String(generatedText[..<range.lowerBound])
                                }
                                print("🛑 Stop sequence '\(stopSeq)' detected")
                                print("✅ Generated \(tokensGenerated) tokens → \(generatedText.count) chars")
                                print("=== Generation Complete ===\n")
                                continuation.resume(returning: generatedText)
                                return
                            }
                        }
                    }

                    // Create new batch with the new token
                    nCur += 1

                    // Decode the new token - keep token alive during decode
                    var newToken = newTokenId
                    let decodeResult = withUnsafeMutablePointer(to: &newToken) { tokenPtr -> Int32 in
                        let batch = llama_batch_get_one(tokenPtr, 1)
                        return llama_decode(ctx, batch)
                    }

                    if decodeResult != 0 {
                        print("❌ Failed to decode token at position \(nCur) (error: \(decodeResult))")
                        break
                    }
                }

                let tokensGenerated = Int(nCur - tokenCount)
                print("✅ Generation complete: \(tokensGenerated) tokens → \(generatedText.count) chars")
                print("📄 Output preview: \(generatedText.prefix(200))\(generatedText.count > 200 ? "..." : "")")
                print("=== Generation Complete ===\n")
                continuation.resume(returning: generatedText)
            }
        }
    }

    /// Generates embedding vector for the given text
    /// - Parameter text: Input text to embed
    /// - Returns: Float array representing the embedding (typically 768 or 2048 dimensions)
    func generateEmbedding(for text: String) async -> [Float]? {
        guard isLoaded else {
            print("⚠️ Model not loaded")
            return nil
        }

        return await withCheckedContinuation { continuation in
            inferenceQueue.async { [weak self] in
                guard let self = self,
                      let ctx = self.context,
                      let mdl = self.model
                else {
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
                    continuation.resume(returning: nil)
                    return
                }

                // Check if token count exceeds batch size
                if tokenCount > ModelConfig.batchSize {
                    print("⚠️ Token count (\(tokenCount)) exceeds batch size (\(ModelConfig.batchSize)), truncating")
                }

                // Keep only the valid tokens, limited to batch size
                let validTokenCount = min(Int(tokenCount), Int(ModelConfig.batchSize))
                var embeddingTokens = Array(tokens.prefix(validTokenCount))
                let embeddingTokenCount = Int32(embeddingTokens.count)

                // Create batch and decode - keep tokens alive during decode
                let decodeResult = embeddingTokens.withUnsafeMutableBufferPointer { tokensPtr -> Int32 in
                    let batch = llama_batch_get_one(tokensPtr.baseAddress, embeddingTokenCount)
                    return llama_decode(ctx, batch)
                }

                if decodeResult != 0 {
                    print("❌ Failed to decode for embeddings")
                    continuation.resume(returning: nil)
                    return
                }

                // Get embeddings using sequence-level extraction (works with mean pooling)
                let embeddingSize = llama_model_n_embd(mdl)
                guard let embeddingsPtr = llama_get_embeddings_seq(ctx, 0) else {
                    print("❌ Failed to get embeddings")
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
            }
        }
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

        // Check in ~/Library/Application Support/NoteTaker/Models/
        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let modelsDir = appSupport.appendingPathComponent("NoteTaker/Models")
            let modelPath = modelsDir.appendingPathComponent(modelFileName)

            if fileManager.fileExists(atPath: modelPath.path) {
                if verbose {
                    print("✅ Found model in Application Support: \(modelPath.path)")
                }
                return modelPath.path
            }
        }

        // Last resort: Check in the project source directory (for development)
        let devPath = "/Users/projects/Documents/notetaker/NoteTaker/Resources/Models/" + modelFileName
        if fileManager.fileExists(atPath: devPath) {
            if verbose {
                print("✅ Found model in development path: \(devPath)")
            }
            return devPath
        }

        if verbose {
            print("❌ Model not found in any location")
            ErrorLogger.shared.logError(
                "Model file not found: \(modelFileName)",
                severity: .error,
                operation: "Model Loading",
                details: "Searched in Application Support and development directories"
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
        return appSupport.appendingPathComponent("NoteTaker/Models")
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
            return "Model file not found. Place model files in ~/Library/Application Support/NoteTaker/Models/ or use the download feature in settings."
        case .modelLoadFailed:
            return "Failed to load the AI model"
        case .inferenceFailed:
            return "Inference failed"
        case .invalidInput:
            return "Invalid input provided"
        }
    }
}
