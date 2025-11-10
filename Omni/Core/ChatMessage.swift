import Foundation
import SwiftData

@Model
final class ChatMessage {
    @Attribute(.unique) var id: UUID
    var content: String
    var isUser: Bool
    var timestamp: Date
    var session: ChatSession?
    
    // --- Private property for storing sources as Data ---
    private var sourcesData: Data?
    
    /// A computed property to safely get and set an array of [String] for sources.
    /// This is not stored directly in the database.
    var sources: [String]? {
        get {
            // When your app asks for 'sources', we decode it from Data.
            guard let data = sourcesData else { return nil }
            return try? JSONDecoder().decode([String].self, from: data)
        }
        set {
            // When your app sets 'sources', we encode it into Data.
            sourcesData = try? JSONEncoder().encode(newValue)
        }
    }
    
    init(content: String, isUser: Bool, sources: [String]?) {
        self.id = UUID()
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
        
        // This calls the 'set' block of the computed property,
        // automatically encoding and saving the data.
        self.sources = sources
    }
}
