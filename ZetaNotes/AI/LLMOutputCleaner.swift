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

        // EDGE CASE FIX: Remove single letter prefixes ONLY if followed by lowercase (e.g., "T i decided")
        // This happens when the model starts generating but gets confused
        // BUT preserve legitimate single letters before proper nouns (e.g., "X Interview", "A Company")
        if cleaned.count > 3 {
            let firstThreeChars = cleaned.prefix(3)
            if firstThreeChars.count == 3 {
                let firstChar = firstThreeChars.first!
                let secondChar = firstThreeChars.dropFirst().first!
                let thirdChar = firstThreeChars.dropFirst(2).first!
                // Only remove if: single uppercase + space + lowercase (confused generation)
                // Keep if: single uppercase + space + uppercase (proper title like "X Interview")
                if firstChar.isUppercase && secondChar == " " && thirdChar.isLowercase {
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
        cleaned = cleaned.replacingOccurrences(of: "<|end_request", with: "")

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

        // Common role markers and partial artifacts (CLEAN THESE EARLY - before checking for isolated words)
        cleaned = cleaned.replacingOccurrences(of: "<|assistant|>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "<|user|>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "<|system|>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "<|system_info", with: "") // Broken system_info token
        cleaned = cleaned.replacingOccurrences(of: "_id|>", with: "")
        cleaned = cleaned
            .replacingOccurrences(
                of: "|>",
                with: ""
            ) // Partial artifact - IMPORTANT: clean this before ygiene_code check

        // Llama 3.2 1B specific artifacts (broken template markers appearing as standalone words)
        // Use regex to remove these ONLY when they appear as isolated words
        let isolatedArtifacts = ["_header", "assistant", "system", "user", "ygiene_code", "_code", "header_"]
        for artifact in isolatedArtifacts {
            // Remove if at start of string followed by whitespace
            if let regex = try? NSRegularExpression(
                pattern: "^" + NSRegularExpression.escapedPattern(for: artifact) + "\\s*",
                options: [.caseInsensitive]
            ) {
                let range = NSRange(cleaned.startIndex..., in: cleaned)
                cleaned = regex.stringByReplacingMatches(in: cleaned, options: [], range: range, withTemplate: "")
            }
            // Remove if preceded by whitespace or newline (isolated word)
            if let regex = try? NSRegularExpression(
                pattern: "\\s+" + NSRegularExpression.escapedPattern(for: artifact) + "(?=\\s|$)",
                options: [.caseInsensitive]
            ) {
                let range = NSRange(cleaned.startIndex..., in: cleaned)
                cleaned = regex.stringByReplacingMatches(in: cleaned, options: [], range: range, withTemplate: " ")
            }
        }

        // Additional Llama 3.2 broken artifacts with wildcards (case-insensitive)
        // Matches: ygiene_*, hygiene_*, _model, _modei, _mode, etc.
        let brokenArtifactPatterns = [
            // Pattern 1: [Yy]giene with optional underscore and any suffix
            "(?:^|\\s)([Yy]giene(?:_\\w+)?)(?=\\s|$)",

            // Pattern 2: [Hh]ygiene with optional underscore and any suffix
            "(?:^|\\s)([Hh]ygiene(?:_\\w+)?)(?=\\s|$)",

            // Pattern 3: _model variants (_model, _modei, _mode)
            "(?:^|\\s)(_model[ei]?)(?=\\s|$)"
        ]

        for pattern in brokenArtifactPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(cleaned.startIndex..., in: cleaned)
                // Replace with single space to maintain word separation
                cleaned = regex.stringByReplacingMatches(
                    in: cleaned,
                    options: [],
                    range: range,
                    withTemplate: " "
                )
            }
        }

        // Clean up any double spaces or leading/trailing spaces
        cleaned = cleaned.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
        cleaned = cleaned.trimmingCharacters(in: .whitespaces)

        // Qwen 2.5, Phi-2
        cleaned = cleaned.replacingOccurrences(of: "<|endoftext|>", with: "")

        // Gemma 2 (Google format)
        cleaned = cleaned.replacingOccurrences(of: "<end_of_turn>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "<start_of_turn>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "<eos>", with: "")

        // Phi-3.5 (Microsoft format)
        cleaned = cleaned.replacingOccurrences(of: "<|end|>", with: "")

        // Remove trailing incomplete tokens (e.g., "App Notarization<" where < is start of <|eot_id|>)
        let trailingIncompleteTokens = ["<", "<|", "<|e", "<|eo", "<|eot", ">"]
        for token in trailingIncompleteTokens {
            if cleaned.hasSuffix(token) {
                cleaned = String(cleaned.dropLast(token.count))
            }
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
