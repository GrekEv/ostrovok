import Foundation

enum AgentIntent: String {
    case booking
    case matching
    case delayedBooking
    case manager
    case general
}

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let isFromUser: Bool
    let text: String
    let createdAt: Date
    var quickReplies: [String]

    init(
        id: UUID = UUID(),
        isFromUser: Bool,
        text: String,
        createdAt: Date = Date(),
        quickReplies: [String] = []
    ) {
        self.id = id
        self.isFromUser = isFromUser
        self.text = text
        self.createdAt = createdAt
        self.quickReplies = quickReplies
    }
}
