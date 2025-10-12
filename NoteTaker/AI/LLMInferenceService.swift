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
enum AIModel: String, CaseIterable, Codable {
    case tinyLlama = "TinyLlama 1.1B"
    case qwen25_3B = "Qwen2.5 3B"

    var displayName: String {
        self.rawValue
    }

    var fileName: String {
        switch self {
        case .tinyLlama:
            return "tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
        case .qwen25_3B:
            return "qwen2.5-3b-instruct-q4_k_m.gguf"
        }
    }

    var fileSize: String {
        switch self {
        case .tinyLlama:
            return "0.7 GB"
        case .qwen25_3B:
            return "2.0 GB"
        }
    }

    var memoryUsage: String {
        switch self {
        case .tinyLlama:
            return "~1.5 GB RAM"
        case .qwen25_3B:
            return "~2.5 GB RAM"
        }
    }

    var speedRating: String {
        switch self {
        case .tinyLlama:
            return "Very Fast"
        case .qwen25_3B:
            return "Fast"
        }
    }

    var qualityRating: String {
        switch self {
        case .tinyLlama:
            return "Basic"
        case .qwen25_3B:
            return "High"
        }
    }

    var description: String {
        switch self {
        case .tinyLlama:
            return "Lightweight model, best for autocomplete and embeddings. Limited instruction-following quality."
        case .qwen25_3B:
            return "3B parameter model with excellent instruction-following. Much better for patch, reformulate, and title generation."
        }
    }

    var huggingFaceURL: String {
        switch self {
        case .tinyLlama:
            return "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF"
        case .qwen25_3B:
            return "https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf"
        }
    }
}

/// Service handling direct LLM inference
/// Wraps llama.cpp or Core ML for running quantized GGUF models
class LLMInferenceService: @unchecked Sendable {

    // MARK: - Configuration

    private struct ModelConfig {
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
        if isLoaded && currentModel == modelType {
            return
        }

        // If different model requested, unload current model first
        if isLoaded && currentModel != modelType {
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

                    // Add samplers to the chain
                    if let topK = llama_sampler_init_top_k(40) {
                        llama_sampler_chain_add(samplerChain, topK)
                    }
                    if let topP = llama_sampler_init_top_p(0.9, 1) {
                        llama_sampler_chain_add(samplerChain, topP)
                    }
                    if let temp = llama_sampler_init_temp(0.7) {
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
    ///   - maxTokens: Maximum number of tokens to generate
    ///   - temperature: Sampling temperature (0.0 = deterministic, 1.0 = creative)
    ///   - stopSequences: Sequences that stop generation when encountered
    /// - Returns: Generated text
    func generate(
        prompt: String,
        maxTokens: Int = 100,
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
                      let smpl = self.sampler else {
                    continuation.resume(returning: nil)
                    return
                }

                print("🔄 Starting text generation...")
                print("📝 Prompt: \(prompt.prefix(100))...")

                // Tokenize the prompt
                var tokens = [llama_token](repeating: 0, count: prompt.count + maxTokens + 16)
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
                    continuation.resume(returning: nil)
                    return
                }

                print("✅ Tokenized: \(tokenCount) tokens")

                // Keep only the valid tokens
                var promptTokens = Array(tokens.prefix(Int(tokenCount)))
                let promptTokenCount = Int32(promptTokens.count)

                // Create batch using the new API
                // Important: tokens array must remain valid for the lifetime of the batch
                print("🔄 Decoding prompt batch...")
                let decodeResult = promptTokens.withUnsafeMutableBufferPointer { tokensPtr -> Int32 in
                    let batch = llama_batch_get_one(tokensPtr.baseAddress, promptTokenCount)
                    return llama_decode(ctx, batch)
                }

                if decodeResult != 0 {
                    print("❌ Failed to decode prompt")
                    continuation.resume(returning: nil)
                    return
                }

                print("✅ Prompt decoded, starting generation...")

                // Generate tokens
                var generatedText = ""
                var nCur = tokenCount
                let nLen = nCur + Int32(maxTokens)

                print("🔄 Generating up to \(maxTokens) tokens...")
                while nCur < nLen {
                    // Sample the next token using the sampler chain
                    let newTokenId = llama_sampler_sample(smpl, ctx, -1)

                    if nCur == tokenCount {
                        print("✅ First token sampled: \(newTokenId)")
                    }

                    // Accept the token
                    llama_sampler_accept(smpl, newTokenId)

                    // Check for end of sequence
                    let vocab = llama_model_get_vocab(mdl)
                    if llama_vocab_is_eog(vocab, newTokenId) {
                        print("✅ End of generation detected")
                        break
                    }

                    // Detokenize to text
                    var buf = [CChar](repeating: 0, count: 32)
                    let pieceSize = llama_token_to_piece(vocab, newTokenId, &buf, Int32(buf.count), 0, false)

                    if pieceSize > 0 {
                        let piece = String(cString: buf)
                        generatedText += piece

                        if nCur < tokenCount + 5 {
                            print("🔤 Token \(nCur): '\(piece)'")
                        }

                        // Check for stop sequences
                        if !stopSequences.isEmpty {
                            for stopSeq in stopSequences {
                                if generatedText.contains(stopSeq) {
                                    if let range = generatedText.range(of: stopSeq) {
                                        generatedText = String(generatedText[..<range.lowerBound])
                                    }
                                    continuation.resume(returning: generatedText)
                                    return
                                }
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
                        print("❌ Failed to decode token at position \(nCur)")
                        break
                    }
                }

                // Clear KV cache after generation to free memory slots
                let mem = llama_get_memory(ctx)
                _ = llama_memory_seq_rm(mem, 0, 0, -1) // Remove all tokens from sequence 0

                print("✅ Generated: \(generatedText)")
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
                      let mdl = self.model else {
                    continuation.resume(returning: nil)
                    return
                }

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
                }                // Get embeddings
                let embeddingSize = llama_model_n_embd(mdl)
                guard let embeddingsPtr = llama_get_embeddings(ctx) else {
                    print("❌ Failed to get embeddings")
                    continuation.resume(returning: nil)
                    return
                }

                // Convert to Swift array
                let embedding = Array(UnsafeBufferPointer(start: embeddingsPtr, count: Int(embeddingSize)))

                // Clear KV cache after embedding generation to free memory slots
                let mem = llama_get_memory(ctx)
                _ = llama_memory_seq_rm(mem, 0, 0, -1) // Remove all tokens from sequence 0

                print("✅ Generated embedding with \(embedding.count) dimensions")
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
        }
        return nil
    }

    /// Returns the Application Support directory path for storing models
    func getModelsDirectory() -> URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
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
