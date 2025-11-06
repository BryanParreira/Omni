import Foundation
import SwiftData

@Model
final class ChatMessage {
    @Attribute(.unique) var id: UUID
    var content: String
    var isUser: Bool
    var sources: [String]?
    var timestamp: Date
    
    // NEW: Property for AI-suggested actions
    var suggestedAction: String?
    
    var session: ChatSession?
    
    init(content: String, isUser: Bool, sources: [String]?, suggestedAction: String? = nil) {
        self.id = UUID()
        self.content = content
        self.isUser = isUser
        self.sources = sources
        self.timestamp = Date()
        self.suggestedAction = suggestedAction
    }
}
