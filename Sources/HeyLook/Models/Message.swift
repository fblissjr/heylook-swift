import Foundation

struct Message: Identifiable, Codable, Equatable {
    let id: UUID
    var role: Role
    var content: String
    var isStreaming: Bool
    var metrics: Metrics?
    let timestamp: Date

    enum Role: String, Codable {
        case user
        case assistant
        case system
    }

    struct Metrics: Codable, Equatable {
        let tokensPerSecond: Double
        let promptTokenCount: Int
        let generationTokenCount: Int
    }

    init(
        id: UUID = UUID(),
        role: Role,
        content: String,
        isStreaming: Bool = false,
        metrics: Metrics? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.isStreaming = isStreaming
        self.metrics = metrics
        self.timestamp = timestamp
    }
}
