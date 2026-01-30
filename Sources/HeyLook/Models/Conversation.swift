import Foundation

struct Conversation: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var messages: [Message]
    var systemPrompt: String?
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "New Conversation",
        messages: [Message] = [],
        systemPrompt: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.systemPrompt = systemPrompt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    mutating func addMessage(_ message: Message) {
        messages.append(message)
        updatedAt = Date()
    }

    mutating func updateTitle(from content: String) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstLine = trimmed.components(separatedBy: .newlines).first ?? trimmed
        let maxLength = 50
        if firstLine.count > maxLength {
            title = String(firstLine.prefix(maxLength)) + "..."
        } else {
            title = firstLine.isEmpty ? "New Conversation" : firstLine
        }
    }
}
