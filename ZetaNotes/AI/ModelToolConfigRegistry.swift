//
//  ModelToolConfigRegistry.swift
//  ZetaNotes
//
//  Registry of optimized LLM configurations for each model and tool combination
//  Based on 2025 best practices research for 9 AI models
//

import Foundation

/// Central registry providing optimized LLM configurations for each model/tool combination
enum ModelToolConfigRegistry {
    // MARK: - Main Entry Point

    /// Gets the optimized LLM configuration for a specific model and tool
    static func getConfig(for model: AIModel, toolType: ToolType) -> LLMConfig {
        switch model {
        case .tinyLlama:
            return TinyLlamaConfigs.config(for: toolType)
        case .llamaThreeTwoOneB, .llamaThreeTwoThreeB:
            return LlamaThreeTwoConfigs.config(for: toolType)
        case .qwenTwoFiveOneFiveB, .qwenTwoFiveThreeB:
            return QwenTwoFiveConfigs.config(for: toolType)
        case .smolLMTwoOneSevenB:
            return SmolLMTwoConfigs.config(for: toolType)
        case .phi2:
            return Phi2Configs.config(for: toolType)
        case .gemmaTwoTwoB:
            return GemmaTwoConfigs.config(for: toolType)
        case .phiThreeFiveMini:
            return PhiThreeFiveConfigs.config(for: toolType)
        }
    }
}

// MARK: - TinyLlama 1.1B Configurations

/// TinyLlama 1.1B optimized configurations
/// - Format: ChatML with <|im_start|>/<|im_end|> tags (v0.2+)
/// - Best temp range: 0.2-0.7
/// - Stop sequences: <|im_end|> (primary ChatML end token, token ID 32002)
private enum TinyLlamaConfigs {
    static func config(for toolType: ToolType) -> LLMConfig {
        switch toolType {
        case .autocomplete:
            return LLMConfig(
                prompt: "Continue the following text naturally. Write only the next few words that would logically follow.",
                temperature: 0.3,
                maxTokens: 20
            )

        case .patch:
            return LLMConfig(
                prompt: "Fix all spelling and grammar errors. Return ONLY the corrected text with no additional commentary.",
                temperature: 0.05,
                maxTokens: nil
            )

        case .rephrase:
            return LLMConfig(
                prompt: "Rewrite the following text to be clearer and more professional. Return ONLY the rewritten text with no additional commentary.",
                temperature: 0.2,
                maxTokens: nil
            )

        case .summarize:
            return LLMConfig(
                prompt: "Summarize the following text in 1-2 sentences. Return ONLY the summary with no additional commentary.",
                temperature: 0.2,
                maxTokens: 150
            )

        case .translate:
            return LLMConfig(
                prompt: "Translate the following text to {targetLanguage}. Return ONLY the translated text with no additional commentary or labels.",
                temperature: 0.05,
                maxTokens: nil
            )

        case .titleGeneration:
            return LLMConfig(
                prompt: "Title (1-5 words):",
                temperature: 0.2,
                maxTokens: 30
            )

        case .custom:
            return LLMConfig(
                prompt: "You are a helpful assistant.",
                temperature: 0.7,
                maxTokens: nil
            )
        }
    }
}

// MARK: - Llama 3.2 1B/3B Configurations

/// Llama 3.2 optimized configurations (September 2024 release)
/// - Format: <|begin_of_text|><|start_header_id|>role<|end_header_id|>\n\ncontent<|eot_id|>
/// - Optimized for: multilingual dialogue, agentic retrieval, summarization
/// - Best temp range: 0.1-0.6 (1B model benefits from lower temps: 0.05-0.3)
/// - Supports: tool calling, code interpreter, multilingual (8 languages)
/// - Context: 128K tokens (8K for quantized versions)
/// - Stop sequences: <|eot_id|> (token 128009, end of turn), <|end_of_text|> (token 128001, EOS)
/// - Training: Knowledge distillation from Llama 3.1 8B/70B + RLHF alignment
private enum LlamaThreeTwoConfigs {
    static func config(for toolType: ToolType) -> LLMConfig {
        switch toolType {
        case .autocomplete:
            return LLMConfig(
                prompt: "Continue writing. Return only the next 3-8 words that naturally follow.",
                temperature: 0.4,
                maxTokens: 30
            )

        case .patch:
            return LLMConfig(
                prompt: "Fix all spelling and grammar errors. Return only the corrected text with no other commentary.",
                temperature: 0.2,
                maxTokens: nil
            )

        case .rephrase:
            return LLMConfig(
                prompt: "Rewrite this text more clearly. Return only the rewritten version with no explanation.",
                temperature: 0.25,
                maxTokens: nil
            )

        case .summarize:
            return LLMConfig(
                prompt: "Write a 1-2 sentence summary. Return only the summary with no preamble.",
                temperature: 0.2,
                maxTokens: 60
            )

        case .translate:
            return LLMConfig(
                prompt: "Translate to {language}. Return only the translation with no preamble.",
                temperature: 0.3,
                maxTokens: nil
            )

        case .titleGeneration:
            return LLMConfig(
                prompt: "Create a short title for this text. Return only the title with no preamble.",
                temperature: 0.6,
                maxTokens: 30
            )

        case .custom:
            return LLMConfig(
                prompt: "You are a helpful assistant.",
                temperature: 0.3,
                maxTokens: nil
            )
        }
    }
}

// MARK: - Qwen2.5 1.5B/3B Configurations

/// Qwen2.5 optimized configurations
/// - Format: <|im_start|>system\n...<|im_end|>\n<|im_start|>user\n...<|im_end|>
/// - Best temp range: 0.1-0.7
/// - Excellent at structured output and long context
/// - Stop sequences: <|im_end|> (token 151645, turn end), <|endoftext|> (token 151643, EOS)
private enum QwenTwoFiveConfigs {
    static func config(for toolType: ToolType) -> LLMConfig {
        switch toolType {
        case .autocomplete:
            return LLMConfig(
                prompt: "Continue the following text naturally. Write only the next few words that would logically follow.",
                temperature: 0.7, maxTokens: 50
            )

        case .patch:
            return LLMConfig(
                prompt: "Fix all spelling and grammar errors while preserving the original meaning. Return ONLY the corrected text with no additional commentary.",
                temperature: 0.05, maxTokens: nil
            )

        case .rephrase:
            return LLMConfig(
                prompt: "Rewrite the following text to be clearer and more readable. Return ONLY the rewritten text with no additional commentary.",
                temperature: 0.3, maxTokens: nil
            )

        case .summarize:
            return LLMConfig(
                prompt: "Summarize the following text in 1-2 sentences. Return ONLY the summary with no additional commentary.",
                temperature: 0.2, maxTokens: 150
            )

        case .translate:
            return LLMConfig(
                prompt: "Translate the following text to {language}. Return ONLY the translation with no additional commentary.",
                temperature: 0.1, maxTokens: nil
            )

        case .titleGeneration:
            return LLMConfig(
                prompt: "Title (1-5 words):",
                temperature: 0.2, maxTokens: 30
            )

        case .custom:
            return LLMConfig(
                prompt: "You are a helpful assistant.",
                temperature: 0.7, maxTokens: nil
            )
        }
    }
}

// MARK: - SmolLM2 1.7B Configurations

/// SmolLM2 optimized configurations
/// - Format: ChatML with <|im_start|>/<|im_end|>
/// - Best temp: 0.2, top_p: 0.9
/// - Optimized for on-device applications
/// - Stop sequences: <|im_end|> (primary ChatML end token), </s> (EOS)
private enum SmolLMTwoConfigs {
    static func config(for toolType: ToolType) -> LLMConfig {
        switch toolType {
        case .autocomplete:
            return LLMConfig(
                prompt: "Continue the following text naturally. Write only the next few words that would logically follow.",
                temperature: 0.5, maxTokens: 50
            )

        case .patch:
            return LLMConfig(
                prompt: "Fix all spelling and grammar errors while preserving the original meaning. Return ONLY the corrected text with no additional commentary.",
                temperature: 0.05, maxTokens: nil
            )

        case .rephrase:
            return LLMConfig(
                prompt: "Rewrite the following text to be clearer and more readable. Return ONLY the rewritten text with no additional commentary.",
                temperature: 0.2, maxTokens: nil
            )

        case .summarize:
            return LLMConfig(
                prompt: "Summarize the following text in 1-2 sentences. Return ONLY the summary with no additional commentary.",
                temperature: 0.2, maxTokens: 150
            )

        case .translate:
            return LLMConfig(
                prompt: "Translate the following text to {language}. Return ONLY the translation with no additional commentary.",
                temperature: 0.1, maxTokens: nil
            )

        case .titleGeneration:
            return LLMConfig(
                prompt: "Title (1-5 words):",
                temperature: 0.2, maxTokens: 30
            )

        case .custom:
            return LLMConfig(
                prompt: "You are a helpful assistant.",
                temperature: 0.5, maxTokens: nil
            )
        }
    }
}

// MARK: - Phi-2 2.7B Configurations

/// Phi-2 optimized configurations
/// - Format: "Instruct: {prompt}\nOutput:" for concise answers
/// - Base model (not instruction-tuned), tends to be verbose
/// - Best for QA, chat, and code
/// - Stop sequences: <|endoftext|> (EOS token), </s>, common format markers
private enum Phi2Configs {
    static func config(for toolType: ToolType) -> LLMConfig {
        switch toolType {
        case .autocomplete:
            return LLMConfig(
                prompt: "Continue the following text naturally. Write only the next few words that would logically follow.",
                temperature: 0.6, maxTokens: 50
            )

        case .patch:
            return LLMConfig(
                prompt: "Fix all spelling and grammar errors while preserving the original meaning. Return ONLY the corrected text with no additional commentary.",
                temperature: 0.05, maxTokens: nil
            )

        case .rephrase:
            return LLMConfig(
                prompt: "Rewrite the following text to be clearer and more readable. Return ONLY the rewritten text with no additional commentary.",
                temperature: 0.3, maxTokens: nil
            )

        case .summarize:
            return LLMConfig(
                prompt: "Summarize the following text in 1-2 sentences. Return ONLY the summary with no additional commentary.",
                temperature: 0.2, maxTokens: 150
            )

        case .translate:
            return LLMConfig(
                prompt: "Translate the following text to {language}. Return ONLY the translation with no additional commentary.",
                temperature: 0.1, maxTokens: nil
            )

        case .titleGeneration:
            return LLMConfig(
                prompt: "Title (1-5 words):",
                temperature: 0.2, maxTokens: 30
            )

        case .custom:
            return LLMConfig(
                prompt: "You are a helpful assistant.",
                temperature: 0.6, maxTokens: nil
            )
        }
    }
}

// MARK: - Gemma 2 2B Configurations

/// Gemma 2 optimized configurations
/// - Format: <start_of_turn>user\n{prompt}<end_of_turn>\n<start_of_turn>model
/// - System instructions go in user prompt (no separate system role)
/// - Stop sequences: <end_of_turn> (turn marker), <eos> (end of stream, token ID 1)
private enum GemmaTwoConfigs {
    static func config(for toolType: ToolType) -> LLMConfig {
        switch toolType {
        case .autocomplete:
            return LLMConfig(
                prompt: "Continue the following text naturally. Write only the next few words that would logically follow.",
                temperature: 0.6, maxTokens: 50
            )

        case .patch:
            return LLMConfig(
                prompt: "Fix all spelling and grammar errors while preserving the original meaning. Return ONLY the corrected text with no additional commentary.",
                temperature: 0.05, maxTokens: nil
            )

        case .rephrase:
            return LLMConfig(
                prompt: "Rewrite the following text to be clearer and more readable. Return ONLY the rewritten text with no additional commentary.",
                temperature: 0.3, maxTokens: nil
            )

        case .summarize:
            return LLMConfig(
                prompt: "Summarize the following text in 1-2 sentences. Return ONLY the summary with no additional commentary.",
                temperature: 0.2, maxTokens: 150
            )

        case .translate:
            return LLMConfig(
                prompt: "Translate the following text to {language}. Return ONLY the translation with no additional commentary.",
                temperature: 0.1, maxTokens: nil
            )

        case .titleGeneration:
            return LLMConfig(
                prompt: "Title (1-5 words):",
                temperature: 0.2, maxTokens: 30
            )

        case .custom:
            return LLMConfig(
                prompt: "You are a helpful assistant.",
                temperature: 0.6, maxTokens: nil
            )
        }
    }
}

// MARK: - Phi-3.5 Mini 3.8B Configurations

/// Phi-3.5 Mini optimized configurations
/// - Format: <|system|>...<|end|>\n<|user|>...<|end|>\n<|assistant|>
/// - 128K context, trained on Python/common packages
/// - Stop tokens: <|end|> (32007), <|endoftext|> (32000), <|assistant|> (32001)
private enum PhiThreeFiveConfigs {
    static func config(for toolType: ToolType) -> LLMConfig {
        switch toolType {
        case .autocomplete:
            return LLMConfig(
                prompt: "Continue the following text naturally. Write only the next few words that would logically follow.",
                temperature: 0.6, maxTokens: 50
            )

        case .patch:
            return LLMConfig(
                prompt: "Fix all spelling and grammar errors while preserving the original meaning. Return ONLY the corrected text with no additional commentary.",
                temperature: 0.05, maxTokens: nil
            )

        case .rephrase:
            return LLMConfig(
                prompt: "Rewrite the following text to be clearer and more readable. Return ONLY the rewritten text with no additional commentary.",
                temperature: 0.3, maxTokens: nil
            )

        case .summarize:
            return LLMConfig(
                prompt: "Summarize the following text in 1-2 sentences. Return ONLY the summary with no additional commentary.",
                temperature: 0.2, maxTokens: 150
            )

        case .translate:
            return LLMConfig(
                prompt: "Translate the following text to {language}. Return ONLY the translation with no additional commentary.",
                temperature: 0.1, maxTokens: nil
            )

        case .titleGeneration:
            return LLMConfig(
                prompt: "Title (1-5 words):",
                temperature: 0.2, maxTokens: 30
            )

        case .custom:
            return LLMConfig(
                prompt: "You are a helpful assistant.",
                temperature: 0.6, maxTokens: nil
            )
        }
    }
}
