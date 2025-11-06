import Foundation
import SwiftData

@Model
final class ChatSession {
    @Attribute(.unique) var id: UUID
    var title: String
    var startDate: Date
    
    // This tells SwiftData that a Session can have many Messages
    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.session)
    var messages: [ChatMessage] = []
    
    init(title: String) {
        self.id = UUID()
        self.title = title
        self.startDate = Date()
    }
}
