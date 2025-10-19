//
//  ModelPromptRegistry.swift
//  ZetaNotes
//
//  Model-specific prompt templates optimized for each AI model
//  Based on official documentation and best practices research (2025)
//

import Foundation

/// Registry of optimized prompts for each AI model
/// Each model has specific prompt formats and best practices based on their training
enum ModelPromptRegistry {
    // MARK: - Prompt Types

    enum PromptType {
        case autocomplete
        case summarization
        case translation
        case titleGeneration
        case autoCorrect
        case reformulate
    }

    // MARK: - Get Prompt for Model

    /// Returns the optimized prompt template for a specific model and task
    static func getPrompt(for model: AIModel, type: PromptType) -> String {
        switch model {
        case .tinyLlama:
            return TinyLlamaPrompts.prompt(for: type)
        case .llamaThreeTwoOneB:
            return LlamaThreeTwoPrompts.prompt(for: type)
        case .qwenTwoFiveOneFiveB:
            return QwenTwoFivePrompts.prompt(for: type)
        case .smolLMTwoOneSevenB:
            return SmolLMTwoPrompts.prompt(for: type)
        case .phi2:
            return Phi2Prompts.prompt(for: type)
        case .gemmaTwoTwoB:
            return GemmaTwoPrompts.prompt(for: type)
        case .qwenTwoFiveThreeB:
            return QwenTwoFivePrompts.prompt(for: type) // Same as 1.5B version
        case .llamaThreeTwoThreeB:
            return LlamaThreeTwoPrompts.prompt(for: type) // Same as 1B version
        case .phiThreeFiveMini:
            return PhiThreeFivePrompts.prompt(for: type)
        }
    }
}

// MARK: - TinyLlama 1.1B Prompts

/// TinyLlama uses ChatML format: <|im_start|>role\ncontent<|im_end|>
/// Best practices: Simple instructions, lower temperature (0.2-0.5), stop token: <s>
private enum TinyLlamaPrompts {
    static func prompt(for type: ModelPromptRegistry.PromptType) -> String {
        switch type {
        case .autocomplete:
            return """
            Continue the following text naturally. Write only the next few words that would logically follow.
            """

        case .summarization:
            return """
            <|system|>
            You are a helpful assistant.</s>
            <|user|>
            Summarize in 1-2 sentences:

            {content}</s>
            <|assistant|>

            """

        case .translation:
            return """
            <|system|>
            You are a translator.</s>
            <|user|>
            Translate to {language}:

            {content}</s>
            <|assistant|>

            """

        case .titleGeneration:
            return """
            <|system|>
            You are a helpful assistant.</s>
            <|user|>
            Create a short title (5-8 words) that captures the main idea of the following text:

            {content}</s>
            <|assistant|>

            """

        case .autoCorrect:
            return """
            <|system|>
            You are a helpful assistant.</s>
            <|user|>
            Fix spelling and grammar:

            {content}</s>
            <|assistant|>

            """

        case .reformulate:
            return """
            <|system|>
            You are a helpful assistant.</s>
            <|user|>
            Rewrite more clearly:

            {content}</s>
            <|assistant|>

            """
        }
    }
}

// MARK: - Llama 3.2 1B/3B Prompts

/// Llama 3.2 uses special header tokens
/// Format: <|begin_of_text|><|start_header_id|>system<|end_header_id|>...<|eot_id|>
/// Best practices: Concise system prompts, supports tool calling, code interpreter with Environment: ipython
private enum LlamaThreeTwoPrompts {
    static func prompt(for type: ModelPromptRegistry.PromptType) -> String {
        switch type {
        case .autocomplete:
            return """
            <|begin_of_text|><|start_header_id|>system<|end_header_id|>

            You are a helpful writing assistant. Continue text naturally and concisely.<|eot_id|><|start_header_id|>user<|end_header_id|>

            Continue the following text with just the next few words:

            """

        case .summarization:
            return """
            <|begin_of_text|><|start_header_id|>system<|end_header_id|>

            You are a helpful assistant that creates concise summaries.<|eot_id|><|start_header_id|>user<|end_header_id|>

            Summarize the following text in 1-2 sentences:

            {content}<|eot_id|><|start_header_id|>assistant<|end_header_id|>

            """

        case .translation:
            return """
            <|begin_of_text|><|start_header_id|>system<|end_header_id|>

            You are an expert translator.<|eot_id|><|start_header_id|>user<|end_header_id|>

            Translate the following text to {language}:

            {content}<|eot_id|><|start_header_id|>assistant<|end_header_id|>

            """

        case .titleGeneration:
            return """
            <|begin_of_text|><|start_header_id|>system<|end_header_id|>

            You are a helpful assistant that creates concise titles.<|eot_id|><|start_header_id|>user<|end_header_id|>

            Create a short, descriptive title (5-8 words) for the following text:

            {content}<|eot_id|><|start_header_id|>assistant<|end_header_id|>

            """

        case .autoCorrect:
            return """
            <|begin_of_text|><|start_header_id|>system<|end_header_id|>

            You are a grammar and spelling correction assistant. Fix errors while preserving meaning.<|eot_id|><|start_header_id|>user<|end_header_id|>

            Fix all spelling and grammar errors in the following text:

            {content}<|eot_id|><|start_header_id|>assistant<|end_header_id|>

            """

        case .reformulate:
            return """
            <|begin_of_text|><|start_header_id|>system<|end_header_id|>

            You are a writing improvement assistant. Rewrite text for clarity and readability.<|eot_id|><|start_header_id|>user<|end_header_id|>

            Rewrite the following text more clearly:

            {content}<|eot_id|><|start_header_id|>assistant<|end_header_id|>

            """
        }
    }
}

// MARK: - Qwen2.5 1.5B/3B Prompts

/// Qwen2.5 uses ChatML format with excellent instruction following
/// Format: <|im_start|>system\n{prompt}<|im_end|>\n<|im_start|>user\n{prompt}<|im_end|>\n<|im_start|>assistant
/// Best practices: Supports long context (128K), excellent at structured output (JSON), strong instruction following
private enum QwenTwoFivePrompts {
    static func prompt(for type: ModelPromptRegistry.PromptType) -> String {
        switch type {
        case .autocomplete:
            return """
            <|im_start|>system
            You are Qwen, created by Alibaba Cloud. You are a helpful assistant that continues text naturally.<|im_end|>
            <|im_start|>user
            Continue the following text with just the next few words that would logically follow:

            """

        case .summarization:
            return """
            <|im_start|>system
            You are Qwen, created by Alibaba Cloud. You are a helpful assistant that creates clear, concise summaries.<|im_end|>
            <|im_start|>user
            Summarize the following text in 1-2 sentences:

            {content}<|im_end|>
            <|im_start|>assistant

            """

        case .translation:
            return """
            <|im_start|>system
            You are Qwen, created by Alibaba Cloud. You are an expert translator that provides accurate translations.<|im_end|>
            <|im_start|>user
            Translate the following text to {language}:

            {content}<|im_end|>
            <|im_start|>assistant

            """

        case .titleGeneration:
            return """
            <|im_start|>system
            You are Qwen, created by Alibaba Cloud. You are a helpful assistant that creates concise, descriptive titles.<|im_end|>
            <|im_start|>user
            Create a short, descriptive title (5-8 words) that captures the main idea:

            {content}<|im_end|>
            <|im_start|>assistant

            """

        case .autoCorrect:
            return """
            <|im_start|>system
            You are Qwen, created by Alibaba Cloud. You are a helpful assistant that fixes spelling and grammar errors while preserving the original meaning.<|im_end|>
            <|im_start|>user
            Fix all spelling and grammar errors in the following text:

            {content}<|im_end|>
            <|im_start|>assistant

            """

        case .reformulate:
            return """
            <|im_start|>system
            You are Qwen, created by Alibaba Cloud. You are a helpful assistant that rewrites text for improved clarity and readability.<|im_end|>
            <|im_start|>user
            Rewrite the following text more clearly and concisely:

            {content}<|im_end|>
            <|im_start|>assistant

            """
        }
    }
}

// MARK: - SmolLM2 1.7B Prompts

/// SmolLM2 uses ChatML format, optimized for on-device applications
/// Format: <|im_start|>system\n{prompt}<|im_end|>\n<|im_start|>user\n{prompt}<|im_end|>\n<|im_start|>assistant
/// Best practices: Good for summarization, rewriting, function calling; use temperature 0.2, top_p 0.9
private enum SmolLMTwoPrompts {
    static func prompt(for type: ModelPromptRegistry.PromptType) -> String {
        switch type {
        case .autocomplete:
            return """
            <|im_start|>system
            You are a helpful assistant that continues text naturally and concisely.<|im_end|>
            <|im_start|>user
            Continue the following text with only the next few words:

            """

        case .summarization:
            return """
            <|im_start|>system
            Provide a concise, objective summary of the input text in up to two sentences, focusing on key points without using second or third person pronouns.<|im_end|>
            <|im_start|>user
            Summarize the following text:

            {content}<|im_end|>
            <|im_start|>assistant

            """

        case .translation:
            return """
            <|im_start|>system
            You are an expert translator. Provide accurate translations that preserve the original meaning.<|im_end|>
            <|im_start|>user
            Translate the following text to {language}:

            {content}<|im_end|>
            <|im_start|>assistant

            """

        case .titleGeneration:
            return """
            <|im_start|>system
            You are a helpful assistant that creates short, descriptive titles.<|im_end|>
            <|im_start|>user
            Create a concise title (5-8 words) that captures the main idea:

            {content}<|im_end|>
            <|im_start|>assistant

            """

        case .autoCorrect:
            return """
            <|im_start|>system
            You are a helpful assistant that fixes spelling and grammar errors while keeping the original meaning intact.<|im_end|>
            <|im_start|>user
            Fix spelling and grammar errors in the following text:

            {content}<|im_end|>
            <|im_start|>assistant

            """

        case .reformulate:
            return """
            <|im_start|>system
            You are a helpful assistant that rewrites text to improve clarity and readability.<|im_end|>
            <|im_start|>user
            Rewrite the following text more clearly:

            {content}<|im_end|>
            <|im_start|>assistant

            """
        }
    }
}

// MARK: - Phi-2 2.7B Prompts

/// Phi-2 is a base model (not instruction-tuned) best suited for QA, chat, and code
/// Format: Standalone questions, "Instruct: {prompt}\nOutput:", or "Human:/AI:" chat format
/// Best practices: Often verbose, use QA format with "Instruct/Output" for concise answers
private enum Phi2Prompts {
    static func prompt(for type: ModelPromptRegistry.PromptType) -> String {
        switch type {
        case .autocomplete:
            return """
            Instruct: Continue the following text naturally. Write only the next few words.
            Output:
            """

        case .summarization:
            return """
            Instruct: Read the following text and create a concise summary in 1-2 sentences.

            {content}

            Output:
            """

        case .translation:
            return """
            Instruct: Translate the following text to {language}. Provide only the translation.

            {content}

            Output:
            """

        case .titleGeneration:
            return """
            Instruct: Create a short, descriptive title (5-8 words) for the following text.

            {content}

            Output:
            """

        case .autoCorrect:
            return """
            Instruct: Fix all spelling and grammar errors in the following text. Preserve the original meaning.

            {content}

            Output:
            """

        case .reformulate:
            return """
            Instruct: Rewrite the following text more clearly and concisely.

            {content}

            Output:
            """
        }
    }
}

// MARK: - Gemma 2 2B Prompts

/// Gemma 2 uses turn-based format with special tokens
/// Format: <bos><start_of_turn>user\n{prompt}<end_of_turn>\n<start_of_turn>model
/// Best practices: System instructions go in initial user prompt (no separate system role)
private enum GemmaTwoPrompts {
    static func prompt(for type: ModelPromptRegistry.PromptType) -> String {
        switch type {
        case .autocomplete:
            return """
            <start_of_turn>user
            You are a helpful writing assistant. Continue the following text with just the next few words that would naturally follow:

            """

        case .summarization:
            return """
            <start_of_turn>user
            You are a helpful assistant that creates concise summaries. Summarize the following text in 1-2 sentences:

            {content}<end_of_turn>
            <start_of_turn>model

            """

        case .translation:
            return """
            <start_of_turn>user
            You are an expert translator. Translate the following text to {language}:

            {content}<end_of_turn>
            <start_of_turn>model

            """

        case .titleGeneration:
            return """
            <start_of_turn>user
            You are a helpful assistant. Create a short, descriptive title (5-8 words) for the following text:

            {content}<end_of_turn>
            <start_of_turn>model

            """

        case .autoCorrect:
            return """
            <start_of_turn>user
            You are a grammar and spelling correction assistant. Fix all spelling and grammar errors in the following text while preserving its meaning:

            {content}<end_of_turn>
            <start_of_turn>model

            """

        case .reformulate:
            return """
            <start_of_turn>user
            You are a writing improvement assistant. Rewrite the following text more clearly and concisely:

            {content}<end_of_turn>
            <start_of_turn>model

            """
        }
    }
}

// MARK: - Phi-3.5 Mini 3.8B Prompts

/// Phi-3.5 uses a specific chat format with special tokens
/// Format: <|system|>...<|end|>\n<|user|>...<|end|>\n<|assistant|>
/// Best practices: Use chat format, 128K context, trained on Python/common packages
private enum PhiThreeFivePrompts {
    static func prompt(for type: ModelPromptRegistry.PromptType) -> String {
        switch type {
        case .autocomplete:
            return """
            <|system|>
            You are a helpful writing assistant. Continue text naturally and concisely.<|end|>
            <|user|>
            Continue the following text with just the next few words:

            """

        case .summarization:
            return """
            <|system|>
            You are a helpful assistant that creates clear, concise summaries.<|end|>
            <|user|>
            Summarize the following text in 1-2 sentences:

            {content}<|end|>
            <|assistant|>

            """

        case .translation:
            return """
            <|system|>
            You are an expert translator that provides accurate translations.<|end|>
            <|user|>
            Translate the following text to {language}:

            {content}<|end|>
            <|assistant|>

            """

        case .titleGeneration:
            return """
            <|system|>
            You are a helpful assistant that creates concise, descriptive titles.<|end|>
            <|user|>
            Create a short, descriptive title (5-8 words) for the following text:

            {content}<|end|>
            <|assistant|>

            """

        case .autoCorrect:
            return """
            <|system|>
            You are a helpful assistant that fixes spelling and grammar errors while preserving meaning.<|end|>
            <|user|>
            Fix all spelling and grammar errors in the following text:

            {content}<|end|>
            <|assistant|>

            """

        case .reformulate:
            return """
            <|system|>
            You are a helpful assistant that rewrites text for improved clarity and readability.<|end|>
            <|user|>
            Rewrite the following text more clearly:

            {content}<|end|>
            <|assistant|>

            """
        }
    }
}
