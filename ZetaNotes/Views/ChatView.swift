//
//  ChatView.swift
//  ZetaNotes
//
//  AI Chat interface with resizable sidebar
//

import SwiftUI

struct ChatView: View {
    @ObservedObject var chatManager = ChatManager.shared
    @EnvironmentObject var aiEngine: AIEngine
    @Binding var isPresented: Bool
    @Binding var sidebarWidth: CGFloat

    @State private var inputText: String = ""
    @State private var isGenerating: Bool = false
    @State private var scrollProxy: ScrollViewProxy?

    let minWidth: CGFloat = 250
    let maxWidth: CGFloat = 500

    var body: some View {
        HStack(spacing: 0) {
            // Chat Sidebar
            VStack(spacing: 0) {
                // Header
                chatHeader
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                // Messages
                chatMessages
                    .background(Color(nsColor: .textBackgroundColor))

                // Input Area
                chatInput
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color(nsColor: .controlBackgroundColor))
            }
            .frame(width: sidebarWidth)
            .background(Color(nsColor: .controlBackgroundColor))

            // Resizable Divider
            resizableDivider
        }
        .transition(.move(edge: .leading).combined(with: .opacity))
    }

    // MARK: - Header

    private var chatHeader: some View {
        HStack(spacing: 12) {
            // Title
            HStack(spacing: 6) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)

                Text("AI Chat")
                    .font(.system(size: 14, weight: .semibold))
            }

            Spacer()

            // Clear button
            Button(action: {
                chatManager.clearMessages()
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Clear conversation")
            .disabled(chatManager.messages.isEmpty)
        }
    }

    // MARK: - Messages

    private var chatMessages: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if chatManager.messages.isEmpty {
                        emptyState
                    } else {
                        ForEach(chatManager.messages) { message in
                            if message.role != .system {
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .onAppear {
                scrollProxy = proxy
                scrollToBottom()
            }
            .onChange(of: chatManager.messages.count) { _ in
                scrollToBottom()
            }
        }
    }

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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Input

    private var chatInput: some View {
        VStack(spacing: 8) {
            // Dump to note button
            if !chatManager.messages.isEmpty {
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
    }

    // MARK: - Resizable Divider

    private var resizableDivider: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.2))
            .frame(width: 1)
            .overlay(
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 8)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newWidth = sidebarWidth + value.translation.width
                                sidebarWidth = min(max(newWidth, minWidth), maxWidth)
                            }
                    )
                    .onHover { hovering in
                        if hovering {
                            NSCursor.resizeLeftRight.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
            )
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

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .user {
                Spacer(minLength: 40)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                // Message content
                Text(message.content)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(message.role == .user ? Color.blue.opacity(0.15) : Color.secondary.opacity(0.1))
                    )
                    .textSelection(.enabled)

                // Timestamp and dump button (on same line for assistant messages)
                HStack(spacing: 6) {
                    Text(message.formattedTimestamp)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary.opacity(0.7))

                    if message.role == .assistant {
                        Button(action: {
                            dumpMessageToNote(message: message)
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.down.doc")
                                    .font(.system(size: 9))
                                Text("Dump")
                                    .font(.system(size: 9, weight: .medium))
                            }
                            .foregroundColor(AppTheme.Colors.accentBlue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AppTheme.Colors.accentBlue.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .strokeBorder(AppTheme.Colors.accentBlue.opacity(0.2), lineWidth: 0.5)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .help("Dump this message to note")
                    }
                }
                .padding(.horizontal, 4)
            }

            if message.role == .assistant {
                Spacer(minLength: 40)
            }
        }
    }

    private func dumpMessageToNote(message: ChatMessage) {
        // Format the message with timestamp
        let markdown = """
        ---
        `Assistant Response • \(message.formattedTimestamp)`
        ---

        \(message.content)
        """

        // Post notification to insert into current note
        NotificationCenter.default.post(
            name: .insertTextIntoNote,
            object: markdown
        )
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let insertTextIntoNote = Notification.Name("insertTextIntoNote")
}
