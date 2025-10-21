//
//  LLMOutputCleaner.swift
//  ZetaNotes
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

        // EDGE CASE FIX: Remove partial/broken prompt fragments (e.g., "ize the text" from "Summarize the text")
        // This happens when the model partially generates its instruction
        let partialPromptFragments = [
            "ize the text", "ixed Text", "ephrased Text", "ranslation to",
            "ummary:", "itle:", "utput ONLY"
        ]
        for fragment in partialPromptFragments {
            if let range = cleaned.range(of: fragment, options: [.caseInsensitive]) {
                // Remove everything up to and including the fragment
                cleaned = String(cleaned[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }

        // EDGE CASE FIX: Remove single letter prefixes (e.g., "T " from "T I decided")
        // This happens when the model starts generating but gets confused
        if cleaned.count > 2 {
            let firstTwoChars = cleaned.prefix(2)
            if firstTwoChars.count == 2 {
                let firstChar = firstTwoChars.first!
                let secondChar = firstTwoChars.dropFirst().first!
                if firstChar.isUppercase && secondChar == " " {
                    cleaned = String(cleaned.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }

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

        // Llama 3.2 reserved special tokens (appear with large contexts)
        // Format: <|reserved_special_token_XXX| where XXX is a number
        // Use regex to catch all variants
        if let regex = try? NSRegularExpression(pattern: "<\\|reserved_special_token_\\d+\\|?>", options: []) {
            let range = NSRange(cleaned.startIndex..., in: cleaned)
            cleaned = regex.stringByReplacingMatches(in: cleaned, options: [], range: range, withTemplate: "")
        }

        // Mangled/partial Llama 3.2 variants (appear when generation is cut off)
        cleaned = cleaned.replacingOccurrences(of: "<|end_header", with: "")
        cleaned = cleaned.replacingOccurrences(of: "</|end_header", with: "")
        cleaned = cleaned.replacingOccurrences(of: "<|eot_", with: "")
        cleaned = cleaned.replacingOccurrences(of: "<|start_header", with: "")

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

        // Remove trailing incomplete tokens (e.g., "App Notarization<" where < is start of <|eot_id|>)
        let trailingIncompleteTokens = ["<", "<|", "<|e", "<|eo", "<|eot", "|>", ">"]
        for token in trailingIncompleteTokens {
            if cleaned.hasSuffix(token) {
                cleaned = String(cleaned.dropLast(token.count))
            }
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
