//
//  ModelToolConfigRegistry.swift
//  NoteTaker
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
    static let stopSequences = ["<|im_end|>", "</s>", "_id|>"]

    static func config(for toolType: ToolType) -> LLMConfig {
        switch toolType {
        case .autocomplete:
            return LLMConfig(
                prompt: "Continue the following text naturally. Write only the next few words that would logically follow.",
                temperature: 0.7,
                maxTokens: 50,
                stopSequences: ["\n", ".", "!", "?"]
            )

        case .patch:
            return LLMConfig(
                prompt: """
                <|system|>
                You are a helpful assistant. Return only the corrected text.</s>
                <|user|>
                Fix spelling and grammar. Output only the corrected text:

                {content}</s>
                <|assistant|>

                """,
                temperature: 0.05,
                maxTokens: nil,
                stopSequences: stopSequences
            )

        case .rephrase:
            return LLMConfig(
                prompt: """
                <|system|>
                You are a helpful assistant. Return only the rewritten text.</s>
                <|user|>
                Rewrite more clearly. Output only the rewritten text:

                {content}</s>
                <|assistant|>

                """,
                temperature: 0.2,
                maxTokens: nil,
                stopSequences: stopSequences
            )

        case .summarize:
            return LLMConfig(
                prompt: """
                <|system|>
                You are a helpful assistant. Return only the summary.</s>
                <|user|>
                Summarize in 1-2 sentences. Output only the summary:

                {content}</s>
                <|assistant|>

                """,
                temperature: 0.2,
                maxTokens: 150,
                stopSequences: stopSequences
            )

        case .translate:
            return LLMConfig(
                prompt: """
                <|system|>
                You are a translator. Return only the translation.</s>
                <|user|>
                Translate to {language}. Output only the translation:

                {content}</s>
                <|assistant|>

                """,
                temperature: 0.1,
                maxTokens: nil,
                stopSequences: stopSequences + ["\n\nOutput:"]
            )

        case .custom:
            return LLMConfig(
                prompt: "",
                temperature: 0.7,
                maxTokens: nil,
                stopSequences: stopSequences
            )
        }
    }
}

// MARK: - Llama 3.2 1B/3B Configurations

/// Llama 3.2 optimized configurations
/// - Format: <|begin_of_text|><|start_header_id|>system<|end_header_id|>...<|eot_id|>
/// - Best temp range: 0.1-0.6
/// - Supports tool calling and code interpreter
/// - Stop sequences: <|eot_id|> (token 128009, end of turn), <|end_of_text|> (token 128001, EOS)
private enum LlamaThreeTwoConfigs {
    static let stopSequences = [
        "<|eot_id|>",
        "<|end_of_text|>",
        "_id|>",
        "\n\nHere is",
        "\n\nHere's",
        "\n\nThe text is",
        "\n\n---"
    ]

    static func config(for toolType: ToolType) -> LLMConfig {
        switch toolType {
        case .autocomplete:
            return LLMConfig(
                prompt: """
                <|begin_of_text|><|start_header_id|>system<|end_header_id|>

                You are a helpful writing assistant. Continue text naturally and concisely.<|eot_id|><|start_header_id|>user<|end_header_id|>

                Continue the following text with just the next few words:

                """,
                temperature: 0.6,
                maxTokens: 50,
                stopSequences: ["\n", ".", "!", "?", "<|eot_id|>"]
            )

        case .patch:
            return LLMConfig(
                prompt: """
                <|begin_of_text|><|start_header_id|>system<|end_header_id|>

                You are a grammar and spelling correction assistant. Fix errors while preserving meaning. Output ONLY the corrected text. Do not include any explanations, preambles, or commentary. Start your response directly with the corrected text.<|eot_id|><|start_header_id|>user<|end_header_id|>

                Fix all spelling and grammar errors in the following text. Return only the corrected text:

                {content}<|eot_id|><|start_header_id|>assistant<|end_header_id|>

                """,
                temperature: 0.05,
                maxTokens: nil,
                stopSequences: stopSequences
            )

        case .rephrase:
            return LLMConfig(
                prompt: """
                <|begin_of_text|><|start_header_id|>system<|end_header_id|>

                You are a writing improvement assistant. Rewrite text for clarity and readability. Output ONLY the rewritten text. Do not include any explanations, preambles like "Here is", or commentary. Start your response directly with the rewritten text.<|eot_id|><|start_header_id|>user<|end_header_id|>

                Rewrite the following text more clearly. Return only the rewritten text:

                {content}<|eot_id|><|start_header_id|>assistant<|end_header_id|>

                """,
                temperature: 0.3,
                maxTokens: nil,
                stopSequences: stopSequences
            )

        case .summarize:
            return LLMConfig(
                prompt: """
                <|begin_of_text|><|start_header_id|>system<|end_header_id|>

                You are a helpful assistant that creates concise summaries. Return ONLY the summary without any preamble or explanation.<|eot_id|><|start_header_id|>user<|end_header_id|>

                Summarize the following text in 1-2 sentences. Return only the summary:

                {content}<|eot_id|><|start_header_id|>assistant<|end_header_id|>

                """,
                temperature: 0.2,
                maxTokens: 150,
                stopSequences: stopSequences
            )

        case .translate:
            return LLMConfig(
                prompt: """
                <|begin_of_text|><|start_header_id|>system<|end_header_id|>

                You are an expert translator. Return ONLY the translation without any explanations or notes.<|eot_id|><|start_header_id|>user<|end_header_id|>

                Translate the following text to {language}. Return only the translation:

                {content}<|eot_id|><|start_header_id|>assistant<|end_header_id|>

                """,
                temperature: 0.1,
                maxTokens: nil,
                stopSequences: stopSequences
            )

        case .custom:
            return LLMConfig(
                prompt: """
                <|begin_of_text|><|start_header_id|>system<|end_header_id|>

                You are a helpful assistant.<|eot_id|><|start_header_id|>user<|end_header_id|>

                """,
                temperature: 0.6,
                maxTokens: nil,
                stopSequences: stopSequences
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
    static let stopSequences = ["<|im_end|>", "<|endoftext|>", "_id|>"]

    static func config(for toolType: ToolType) -> LLMConfig {
        switch toolType {
        case .autocomplete:
            return LLMConfig(
                prompt: """
                <|im_start|>system
                You are Qwen, created by Alibaba Cloud. You are a helpful assistant that continues text naturally.<|im_end|>
                <|im_start|>user
                Continue the following text with just the next few words that would logically follow:

                """,
                temperature: 0.7,
                maxTokens: 50,
                stopSequences: ["\n", ".", "!", "?", "<|im_end|>"]
            )

        case .patch:
            return LLMConfig(
                prompt: """
                <|im_start|>system
                You are Qwen, created by Alibaba Cloud. You fix spelling and grammar errors while preserving the original meaning. Output ONLY the corrected text without explanations.<|im_end|>
                <|im_start|>user
                Fix all spelling and grammar errors. Return only the corrected text:

                {content}<|im_end|>
                <|im_start|>assistant

                """,
                temperature: 0.05,
                maxTokens: nil,
                stopSequences: stopSequences
            )

        case .rephrase:
            return LLMConfig(
                prompt: """
                <|im_start|>system
                You are Qwen, created by Alibaba Cloud. You rewrite text for improved clarity and readability. Output ONLY the rewritten text without explanations.<|im_end|>
                <|im_start|>user
                Rewrite the following text more clearly. Return only the rewritten text:

                {content}<|im_end|>
                <|im_start|>assistant

                """,
                temperature: 0.3,
                maxTokens: nil,
                stopSequences: stopSequences
            )

        case .summarize:
            return LLMConfig(
                prompt: """
                <|im_start|>system
                You are Qwen, created by Alibaba Cloud. You create clear, concise summaries. Output ONLY the summary without preamble.<|im_end|>
                <|im_start|>user
                Summarize the following text in 1-2 sentences. Return only the summary:

                {content}<|im_end|>
                <|im_start|>assistant

                """,
                temperature: 0.2,
                maxTokens: 150,
                stopSequences: stopSequences
            )

        case .translate:
            return LLMConfig(
                prompt: """
                <|im_start|>system
                You are Qwen, created by Alibaba Cloud. You are an expert translator. Output ONLY the translation without notes or explanations.<|im_end|>
                <|im_start|>user
                Translate the following text to {language}. Return only the translation:

                {content}<|im_end|>
                <|im_start|>assistant

                """,
                temperature: 0.1,
                maxTokens: nil,
                stopSequences: stopSequences
            )

        case .custom:
            return LLMConfig(
                prompt: """
                <|im_start|>system
                You are Qwen, created by Alibaba Cloud. You are a helpful assistant.<|im_end|>
                <|im_start|>user

                """,
                temperature: 0.7,
                maxTokens: nil,
                stopSequences: stopSequences
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
    static let stopSequences = ["<|im_end|>", "</s>", "_id|>"]

    static func config(for toolType: ToolType) -> LLMConfig {
        switch toolType {
        case .autocomplete:
            return LLMConfig(
                prompt: """
                <|im_start|>system
                You are a helpful assistant that continues text naturally and concisely.<|im_end|>
                <|im_start|>user
                Continue the following text with only the next few words:

                """,
                temperature: 0.5,
                maxTokens: 50,
                stopSequences: ["\n", ".", "!", "?", "<|im_end|>"]
            )

        case .patch:
            return LLMConfig(
                prompt: """
                <|im_start|>system
                You fix spelling and grammar errors while keeping the original meaning intact. Output ONLY the corrected text.<|im_end|>
                <|im_start|>user
                Fix spelling and grammar errors. Return only the corrected text:

                {content}<|im_end|>
                <|im_start|>assistant

                """,
                temperature: 0.05,
                maxTokens: nil,
                stopSequences: stopSequences
            )

        case .rephrase:
            return LLMConfig(
                prompt: """
                <|im_start|>system
                You rewrite text to improve clarity and readability. Output ONLY the rewritten text.<|im_end|>
                <|im_start|>user
                Rewrite the following text more clearly. Return only the rewritten text:

                {content}<|im_end|>
                <|im_start|>assistant

                """,
                temperature: 0.2,
                maxTokens: nil,
                stopSequences: stopSequences
            )

        case .summarize:
            return LLMConfig(
                prompt: """
                <|im_start|>system
                Provide a concise, objective summary in up to two sentences. Output ONLY the summary.<|im_end|>
                <|im_start|>user
                Summarize the following text. Return only the summary:

                {content}<|im_end|>
                <|im_start|>assistant

                """,
                temperature: 0.2,
                maxTokens: 150,
                stopSequences: stopSequences
            )

        case .translate:
            return LLMConfig(
                prompt: """
                <|im_start|>system
                You are an expert translator. Output ONLY the translation.<|im_end|>
                <|im_start|>user
                Translate the following text to {language}. Return only the translation:

                {content}<|im_end|>
                <|im_start|>assistant

                """,
                temperature: 0.1,
                maxTokens: nil,
                stopSequences: stopSequences
            )

        case .custom:
            return LLMConfig(
                prompt: """
                <|im_start|>system
                You are a helpful assistant.<|im_end|>
                <|im_start|>user

                """,
                temperature: 0.5,
                maxTokens: nil,
                stopSequences: stopSequences
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
    static let stopSequences = [
        "<|endoftext|>",
        "</s>",
        "_id|>",
        "\n\nInstruct:",
        "\n\nOutput:",
        "\n\nHuman:",
        "\n\nText:",
        "\n\nNote:",
        "\n\nExplanation:"
    ]

    static func config(for toolType: ToolType) -> LLMConfig {
        switch toolType {
        case .autocomplete:
            return LLMConfig(
                prompt: "Instruct: Continue the following text naturally. Write only the next few words.\nOutput:",
                temperature: 0.6,
                maxTokens: 50,
                stopSequences: ["\n", ".", "!", "?"] + stopSequences
            )

        case .patch:
            return LLMConfig(
                prompt: "Instruct: Fix all spelling and grammar errors in the following text. Preserve the original meaning. Return only the corrected text.\n\n{content}\n\nOutput:",
                temperature: 0.05,
                maxTokens: nil,
                stopSequences: stopSequences
            )

        case .rephrase:
            return LLMConfig(
                prompt: "Instruct: Rewrite the following text more clearly and concisely. Return only the rewritten text.\n\n{content}\n\nOutput:",
                temperature: 0.3,
                maxTokens: nil,
                stopSequences: stopSequences
            )

        case .summarize:
            return LLMConfig(
                prompt: "Instruct: Read the following text and create a concise summary in 1-2 sentences. Return only the summary.\n\n{content}\n\nOutput:",
                temperature: 0.2,
                maxTokens: 150,
                stopSequences: stopSequences
            )

        case .translate:
            return LLMConfig(
                prompt: "Instruct: Translate the following text to {language}. Provide only the translation.\n\n{content}\n\nOutput:",
                temperature: 0.1,
                maxTokens: nil,
                stopSequences: stopSequences
            )

        case .custom:
            return LLMConfig(
                prompt: "Instruct: ",
                temperature: 0.6,
                maxTokens: nil,
                stopSequences: stopSequences
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
    static let stopSequences = ["<end_of_turn>", "<eos>", "_id|>"]

    static func config(for toolType: ToolType) -> LLMConfig {
        switch toolType {
        case .autocomplete:
            return LLMConfig(
                prompt: """
                <start_of_turn>user
                You are a helpful writing assistant. Continue the following text with just the next few words that would naturally follow:

                """,
                temperature: 0.6,
                maxTokens: 50,
                stopSequences: ["\n", ".", "!", "?", "<end_of_turn>"]
            )

        case .patch:
            return LLMConfig(
                prompt: """
                <start_of_turn>user
                You are a grammar and spelling correction assistant. Fix all spelling and grammar errors while preserving meaning. Output ONLY the corrected text without any explanations.

                Fix the following text and return only the corrected version:

                {content}<end_of_turn>
                <start_of_turn>model

                """,
                temperature: 0.05,
                maxTokens: nil,
                stopSequences: stopSequences
            )

        case .rephrase:
            return LLMConfig(
                prompt: """
                <start_of_turn>user
                You are a writing improvement assistant. Rewrite text more clearly and concisely. Output ONLY the rewritten text without explanations.

                Rewrite the following text and return only the rewritten version:

                {content}<end_of_turn>
                <start_of_turn>model

                """,
                temperature: 0.3,
                maxTokens: nil,
                stopSequences: stopSequences
            )

        case .summarize:
            return LLMConfig(
                prompt: """
                <start_of_turn>user
                You are a helpful assistant that creates concise summaries. Output ONLY the summary without preamble.

                Summarize the following text in 1-2 sentences. Return only the summary:

                {content}<end_of_turn>
                <start_of_turn>model

                """,
                temperature: 0.2,
                maxTokens: 150,
                stopSequences: stopSequences
            )

        case .translate:
            return LLMConfig(
                prompt: """
                <start_of_turn>user
                You are an expert translator. Output ONLY the translation without notes or explanations.

                Translate the following text to {language}. Return only the translation:

                {content}<end_of_turn>
                <start_of_turn>model

                """,
                temperature: 0.1,
                maxTokens: nil,
                stopSequences: stopSequences
            )

        case .custom:
            return LLMConfig(
                prompt: """
                <start_of_turn>user
                You are a helpful assistant.

                """,
                temperature: 0.6,
                maxTokens: nil,
                stopSequences: stopSequences
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
    static let stopSequences = ["<|end|>", "<|endoftext|>", "<|assistant|>", "_id|>"]

    static func config(for toolType: ToolType) -> LLMConfig {
        switch toolType {
        case .autocomplete:
            return LLMConfig(
                prompt: """
                <|system|>
                You are a helpful writing assistant. Continue text naturally and concisely.<|end|>
                <|user|>
                Continue the following text with just the next few words:

                """,
                temperature: 0.6,
                maxTokens: 50,
                stopSequences: ["\n", ".", "!", "?", "<|end|>"]
            )

        case .patch:
            return LLMConfig(
                prompt: """
                <|system|>
                You fix spelling and grammar errors while preserving meaning. Output ONLY the corrected text without explanations.<|end|>
                <|user|>
                Fix all spelling and grammar errors. Return only the corrected text:

                {content}<|end|>
                <|assistant|>

                """,
                temperature: 0.05,
                maxTokens: nil,
                stopSequences: stopSequences
            )

        case .rephrase:
            return LLMConfig(
                prompt: """
                <|system|>
                You rewrite text for improved clarity and readability. Output ONLY the rewritten text without explanations.<|end|>
                <|user|>
                Rewrite the following text more clearly. Return only the rewritten text:

                {content}<|end|>
                <|assistant|>

                """,
                temperature: 0.3,
                maxTokens: nil,
                stopSequences: stopSequences
            )

        case .summarize:
            return LLMConfig(
                prompt: """
                <|system|>
                You create clear, concise summaries. Output ONLY the summary without preamble.<|end|>
                <|user|>
                Summarize the following text in 1-2 sentences. Return only the summary:

                {content}<|end|>
                <|assistant|>

                """,
                temperature: 0.2,
                maxTokens: 150,
                stopSequences: stopSequences
            )

        case .translate:
            return LLMConfig(
                prompt: """
                <|system|>
                You are an expert translator. Output ONLY the translation without notes or explanations.<|end|>
                <|user|>
                Translate the following text to {language}. Return only the translation:

                {content}<|end|>
                <|assistant|>

                """,
                temperature: 0.1,
                maxTokens: nil,
                stopSequences: stopSequences
            )

        case .custom:
            return LLMConfig(
                prompt: """
                <|system|>
                You are a helpful assistant.<|end|>
                <|user|>

                """,
                temperature: 0.6,
                maxTokens: nil,
                stopSequences: stopSequences
            )
        }
    }
}
