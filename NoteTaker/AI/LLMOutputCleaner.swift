//
//  LLMOutputCleaner.swift
//  NoteTaker
//
//  Centralized utility for cleaning LLM output artifacts across all models
//

import Foundation

/// Utility for removing model-specific artifacts from LLM outputs
enum LLMOutputCleaner {
    /// Removes all known model artifacts from the output string
    /// Handles artifacts from: TinyLlama, Llama 3.2, Qwen 2.5, SmolLM2, Phi-2, Gemma 2, Phi-3.5
    static func clean(_ output: String) -> String {
        var cleaned = output.trimmingCharacters(in: .whitespacesAndNewlines)

        // TinyLlama, Qwen 2.5, SmolLM2 (ChatML format)
        cleaned = cleaned.replacingOccurrences(of: "<|im_end|>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "|im_end|>", with: "") // Mangled version
        cleaned = cleaned.replacingOccurrences(of: "<|im_start|>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "</s>", with: "")

        // Llama 3.2 (Custom format)
        cleaned = cleaned.replacingOccurrences(of: "<|eot_id|>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "<|end_of_text|>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "<|start_header_id|>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "<|end_header_id|>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "<|begin_of_text|>", with: "")

        // Qwen 2.5, Phi-2
        cleaned = cleaned.replacingOccurrences(of: "<|endoftext|>", with: "")

        // Gemma 2 (Google format)
        cleaned = cleaned.replacingOccurrences(of: "<end_of_turn>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "<start_of_turn>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "<eos>", with: "")

        // Phi-3.5 (Microsoft format)
        cleaned = cleaned.replacingOccurrences(of: "<|end|>", with: "")

        // Common role markers and artifacts
        cleaned = cleaned.replacingOccurrences(of: "<|assistant|>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "<|user|>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "<|system|>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "_id|>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "|>", with: "") // Partial artifact

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
