import Foundation
import MLXLMCommon
import MLXLLM

enum LLMError: LocalizedError {
    case modelNotLoaded
    case generationFailed(String)

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Model is not loaded. Please load a model first."
        case .generationFailed(let reason):
            return "Generation failed: \(reason)"
        }
    }
}

actor LLMService {
    private var modelContainer: ModelContainer?
    private(set) var isLoading = false
    private(set) var loadProgress: Double = 0

    var isModelLoaded: Bool {
        modelContainer != nil
    }

    func loadModel(path: URL) async throws {
        isLoading = true
        loadProgress = 0
        defer { isLoading = false }

        modelContainer = try await loadModelContainer(directory: path) { _ in
            // Progress updates could be handled here if needed
        }
        loadProgress = 1.0
    }

    func createSession(
        systemPrompt: String?,
        history: [Chat.Message],
        parameters: GenerateParameters
    ) -> ChatSession? {
        guard let container = modelContainer else { return nil }

        if history.isEmpty {
            return ChatSession(
                container,
                instructions: systemPrompt,
                generateParameters: parameters
            )
        } else {
            return ChatSession(
                container,
                instructions: systemPrompt,
                history: history,
                generateParameters: parameters
            )
        }
    }

    func generate(
        prompt: String,
        systemPrompt: String?,
        history: [Chat.Message],
        parameters: GenerateParameters
    ) -> AsyncThrowingStream<Generation, Error> {
        AsyncThrowingStream { continuation in
            Task {
                guard let container = self.modelContainer else {
                    continuation.finish(throwing: LLMError.modelNotLoaded)
                    return
                }

                let session: ChatSession
                if history.isEmpty {
                    session = ChatSession(
                        container,
                        instructions: systemPrompt,
                        generateParameters: parameters
                    )
                } else {
                    session = ChatSession(
                        container,
                        instructions: systemPrompt,
                        history: history,
                        generateParameters: parameters
                    )
                }

                do {
                    for try await generation in session.streamDetails(to: prompt, images: [], videos: []) {
                        continuation.yield(generation)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func unloadModel() {
        modelContainer = nil
    }
}
