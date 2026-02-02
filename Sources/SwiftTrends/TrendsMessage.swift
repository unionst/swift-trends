import Foundation
import UnionChat

struct TrendsMessage: Identifiable, Sendable {
    let id: UUID
    let text: String
    let role: ChatRole
    let timestamp: Date

    init(id: UUID = UUID(), text: String, role: ChatRole, timestamp: Date = .now) {
        self.id = id
        self.text = text
        self.role = role
        self.timestamp = timestamp
    }
}
