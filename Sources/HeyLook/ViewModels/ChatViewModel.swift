import Foundation
import SwiftUI
import MLXLMCommon

@Observable
final class ChatViewModel {
    // MARK: - State

    var conversations: [Conversation] = []
    var selectedConversationId: UUID?
    var isGenerating = false
    var streamingContent = ""
    var currentMetrics: Message.Metrics?
    var samplerSettings = SamplerSettings()
    var systemPrompt = ""
    var isModelLoaded = false
    var isModelLoading = false
    var modelLoadError: String?

    // MARK: - Private

    private let llmService = LLMService()
    private var generationTask: Task<Void, Never>?

    private static let defaultModelPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Storage/llms/Qwen/Qwen3-4B-Instruct-2507-mlx")

    // MARK: - Computed Properties

    var selectedConversation: Conversation? {
        get {
            guard let id = selectedConversationId else { return nil }
            return conversations.first { $0.id == id }
        }
        set {
            guard let id = selectedConversationId,
                  let newValue = newValue,
                  let index = conversations.firstIndex(where: { $0.id == id }) else { return }
            conversations[index] = newValue
        }
    }

    var selectedConversationIndex: Int? {
        guard let id = selectedConversationId else { return nil }
        return conversations.firstIndex { $0.id == id }
    }

    // MARK: - Model Management

    func loadModel(path: URL? = nil) async {
        isModelLoading = true
        modelLoadError = nil

        let modelPath = path ?? Self.defaultModelPath
        print("[HeyLook] Starting model load from: \(modelPath.path)")

        do {
            try await llmService.loadModel(path: modelPath)
            isModelLoaded = await llmService.isModelLoaded
            print("[HeyLook] Model loaded successfully: \(isModelLoaded)")
        } catch {
            modelLoadError = error.localizedDescription
            isModelLoaded = false
            print("[HeyLook] Model load failed: \(error)")
        }

        isModelLoading = false
    }

    // MARK: - Conversation Management

    func createNewConversation() {
        let conversation = Conversation()
        conversations.insert(conversation, at: 0)
        selectedConversationId = conversation.id
    }

    func deleteConversation(_ id: UUID) {
        conversations.removeAll { $0.id == id }
        if selectedConversationId == id {
            selectedConversationId = conversations.first?.id
        }
    }

    func selectConversation(_ id: UUID) {
        selectedConversationId = id
    }

    // MARK: - Message Sending

    func sendMessage(_ content: String) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let index = selectedConversationIndex else {
            createNewConversation()
            await sendMessage(content)
            return
        }

        // Add user message
        let userMessage = Message(role: .user, content: content)
        conversations[index].addMessage(userMessage)

        // Update title from first user message
        if conversations[index].messages.count == 1 {
            conversations[index].updateTitle(from: content)
        }

        // Add placeholder assistant message
        let assistantMessage = Message(role: .assistant, content: "", isStreaming: true)
        conversations[index].addMessage(assistantMessage)

        await generateResponse(at: index)
    }

    private func generateResponse(at conversationIndex: Int) async {
        isGenerating = true
        streamingContent = ""
        currentMetrics = nil

        let assistantMessageIndex = conversations[conversationIndex].messages.count - 1

        generationTask = Task {
            do {
                let history = buildChatHistory(for: conversationIndex, excludingLast: true)
                let prompt = conversations[conversationIndex].messages
                    .last(where: { $0.role == .user })?.content ?? ""

                let stream = await llmService.generate(
                    prompt: prompt,
                    systemPrompt: systemPrompt.isEmpty ? nil : systemPrompt,
                    history: history,
                    parameters: samplerSettings.toGenerateParameters()
                )

                var fullContent = ""

                for try await generation in stream {
                    if Task.isCancelled { break }

                    switch generation {
                    case .chunk(let text):
                        fullContent += text
                        streamingContent = fullContent
                        conversations[conversationIndex].messages[assistantMessageIndex].content = fullContent

                    case .info(let info):
                        currentMetrics = Message.Metrics(
                            tokensPerSecond: info.tokensPerSecond,
                            promptTokenCount: info.promptTokenCount,
                            generationTokenCount: info.generationTokenCount
                        )
                        conversations[conversationIndex].messages[assistantMessageIndex].metrics = currentMetrics

                    case .toolCall:
                        break
                    }
                }

                conversations[conversationIndex].messages[assistantMessageIndex].isStreaming = false

            } catch {
                if !Task.isCancelled {
                    conversations[conversationIndex].messages[assistantMessageIndex].content =
                        "Error: \(error.localizedDescription)"
                    conversations[conversationIndex].messages[assistantMessageIndex].isStreaming = false
                }
            }
        }

        await generationTask?.value
        isGenerating = false
    }

    private func buildChatHistory(for conversationIndex: Int, excludingLast: Bool) -> [Chat.Message] {
        let messages = conversations[conversationIndex].messages
        let messagesToConvert = excludingLast ? Array(messages.dropLast()) : messages

        return messagesToConvert.compactMap { msg -> Chat.Message? in
            switch msg.role {
            case .user:
                return .user(msg.content)
            case .assistant:
                return .assistant(msg.content)
            case .system:
                return .system(msg.content)
            }
        }
    }

    // MARK: - Generation Control

    func stopGeneration() {
        generationTask?.cancel()
        generationTask = nil
        isGenerating = false

        if let index = selectedConversationIndex,
           let lastIndex = conversations[index].messages.indices.last {
            conversations[index].messages[lastIndex].isStreaming = false
        }
    }

    func regenerateLastMessage() async {
        guard let index = selectedConversationIndex else { return }
        guard conversations[index].messages.count >= 2 else { return }

        // Remove the last assistant message
        if conversations[index].messages.last?.role == .assistant {
            conversations[index].messages.removeLast()
        }

        // Add new placeholder
        let assistantMessage = Message(role: .assistant, content: "", isStreaming: true)
        conversations[index].addMessage(assistantMessage)

        await generateResponse(at: index)
    }

    func editMessage(_ messageId: UUID, newContent: String) async {
        guard let convIndex = selectedConversationIndex else { return }

        guard let msgIndex = conversations[convIndex].messages.firstIndex(where: { $0.id == messageId }) else {
            return
        }

        // Update the message content
        conversations[convIndex].messages[msgIndex].content = newContent

        // Remove all messages after this one
        let removeCount = conversations[convIndex].messages.count - msgIndex - 1
        if removeCount > 0 {
            conversations[convIndex].messages.removeLast(removeCount)
        }

        // If it was a user message, regenerate
        if conversations[convIndex].messages[msgIndex].role == .user {
            let assistantMessage = Message(role: .assistant, content: "", isStreaming: true)
            conversations[convIndex].addMessage(assistantMessage)
            await generateResponse(at: convIndex)
        }
    }
}
