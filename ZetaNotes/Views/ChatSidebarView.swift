//
//  ChatSidebarView.swift
//  ZetaNotes
//
//  AI Chat sidebar with native macOS styling
//

import SwiftUI

struct ChatSidebarView: View {
    @ObservedObject var chatManager = ChatManager.shared
    @EnvironmentObject var aiEngine: AIEngine
    @State private var inputText: String = ""
    @State private var isGenerating: Bool = false
    @State private var scrollProxy: ScrollViewProxy?

    var body: some View {
        ZStack(alignment: .leading) {
            VStack(spacing: 0) {
                // Header - AI Chat title (now at the top)
                HStack(spacing: 6) {
                    Text("AI Chat")
                        .font(.system(size: AppTheme.Typography.chatTitleSize, weight: .semibold))

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, AppTheme.Spacing.chatHeaderTopPadding)
                .padding(.bottom, AppTheme.Spacing.chatHeaderBottomPadding)
                .background(AppTheme.Colors.controlBackground)

                // Messages
                if chatManager.messages.isEmpty {
                    emptyState
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(nsColor: .textBackgroundColor))
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 16) {
                                ForEach(chatManager.messages) { message in
                                    if message.role != .system {
                                        MessageBubble(message: message)
                                            .id(message.id)
                                    }
                                }
                            }
                            .padding(16)
                        }
                        .background(Color(nsColor: .textBackgroundColor))
                        .onAppear {
                            scrollProxy = proxy
                            scrollToBottom()
                        }
                        .onChange(of: chatManager.messages.count) { _ in
                            scrollToBottom()
                        }
                    }
                }

                // Input Area
                VStack(spacing: 8) {
                    // Action buttons (when messages exist)
                    if !chatManager.messages.isEmpty {
                        HStack(spacing: 8) {
                            // Dump to note button
                            Button(action: {
                                dumpConversationToNote()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.down.doc")
                                        .font(.system(size: 11))
                                    Text("Dump to Note")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundColor(.blue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(Color.blue.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 5)
                                                .strokeBorder(Color.blue.opacity(0.3), lineWidth: 0.5)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .help("Insert conversation into current note")

                            // Clear conversation button
                            Button(action: {
                                chatManager.clearMessages()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 11))
                                    Text("Clear conversation")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundColor(.red)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(Color.red.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 5)
                                                .strokeBorder(Color.red.opacity(0.3), lineWidth: 0.5)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .help("Clear all messages")
                        }
                    }

                    // Text input
                    HStack(spacing: 8) {
                        TextField("Message...", text: $inputText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .lineLimit(1 ... 5)
                            .disabled(isGenerating)
                            .onSubmit {
                                sendMessage()
                            }

                        Button(action: {
                            sendMessage()
                        }) {
                            if isGenerating {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .frame(width: 20, height: 20)
                            } else {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(inputText.isEmpty ? .secondary : .blue)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(inputText.isEmpty || isGenerating)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(nsColor: .textBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color(nsColor: .controlBackgroundColor))
            }
            .ignoresSafeArea(edges: .top)
            .background(AppTheme.Colors.controlBackground)
            .overlay(
                // Top border matching toolbar
                Rectangle()
                    .fill(AppTheme.Colors.toolbarBorder)
                    .frame(height: AppTheme.Effects.borderWidth),
                alignment: .top
            )
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))

            Text("Start a conversation")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Ask me anything about your notes or general questions")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Actions

    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let userMessage = inputText
        inputText = ""

        // Add user message
        chatManager.addMessage(role: .user, content: userMessage)

        // Generate response
        Task {
            isGenerating = true

            let chatService = ChatService(llmService: aiEngine.llmService)
            let response = await chatService.generateResponse(
                messages: chatManager.messages,
                settings: chatManager.settings,
                onToken: { _ in
                    // For future streaming implementation
                }
            )

            await MainActor.run {
                isGenerating = false

                if let response = response {
                    chatManager.addMessage(role: .assistant, content: response)
                } else {
                    // Error handling
                    chatManager.addMessage(
                        role: .assistant,
                        content: "I'm sorry, I couldn't generate a response. Please try again."
                    )
                }
            }
        }
    }

    private func scrollToBottom() {
        if let lastMessage = chatManager.messages.last {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        }
    }

    private func dumpConversationToNote() {
        let markdown = chatManager.exportToMarkdown()

        // Post notification to insert into current note
        NotificationCenter.default.post(
            name: .insertTextIntoNote,
            object: markdown
        )
    }
}
