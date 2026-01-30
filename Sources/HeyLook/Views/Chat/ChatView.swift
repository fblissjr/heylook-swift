import SwiftUI

struct ChatView: View {
    @Bindable var viewModel: ChatViewModel
    @State private var showingSamplerSettings = false
    @State private var showingSystemPrompt = false

    var body: some View {
        VStack(spacing: 0) {
            if let conversation = viewModel.selectedConversation {
                MessageListView(
                    messages: conversation.messages,
                    isGenerating: viewModel.isGenerating,
                    onEdit: { messageId, newContent in
                        Task {
                            await viewModel.editMessage(messageId, newContent: newContent)
                        }
                    }
                )
            } else {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Start a new conversation")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Type a message below to begin")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            }

            Divider()

            InputAreaView(
                isGenerating: viewModel.isGenerating,
                isModelLoaded: viewModel.isModelLoaded,
                onSend: { content in
                    Task {
                        await viewModel.sendMessage(content)
                    }
                },
                onStop: {
                    viewModel.stopGeneration()
                },
                onRegenerate: {
                    Task {
                        await viewModel.regenerateLastMessage()
                    }
                }
            )
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if viewModel.isModelLoading {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Loading...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if let error = viewModel.modelLoadError {
                    Button {
                        Task {
                            await viewModel.loadModel()
                        }
                    } label: {
                        Label("Retry", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                    .help("Error: \(error). Click to retry.")
                } else if !viewModel.isModelLoaded {
                    Button {
                        Task {
                            await viewModel.loadModel()
                        }
                    } label: {
                        Label("Load Model", systemImage: "cpu")
                    }
                    .help("Load LLM Model")
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "cpu.fill")
                            .foregroundStyle(.green)
                        Text("Ready")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    .help("Model Loaded")
                }

                Button {
                    showingSystemPrompt = true
                } label: {
                    Image(systemName: "person.text.rectangle")
                }
                .help("System Prompt")

                Button {
                    showingSamplerSettings = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .help("Sampler Settings")
            }
        }
        .sheet(isPresented: $showingSamplerSettings) {
            SamplerSettingsSheet(settings: $viewModel.samplerSettings)
        }
        .sheet(isPresented: $showingSystemPrompt) {
            SystemPromptSheet(systemPrompt: $viewModel.systemPrompt)
        }
        .alert("Model Load Error", isPresented: .init(
            get: { viewModel.modelLoadError != nil },
            set: { if !$0 { viewModel.modelLoadError = nil } }
        )) {
            Button("OK") {
                viewModel.modelLoadError = nil
            }
        } message: {
            if let error = viewModel.modelLoadError {
                Text(error)
            }
        }
    }
}
