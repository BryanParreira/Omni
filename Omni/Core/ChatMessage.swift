import Foundation
import SwiftData

@Model
final class ChatMessage {
    @Attribute(.unique) var id: UUID
    var content: String
    var isUser: Bool
    
    // --- THIS IS THE FIX ---
    // 1. We store the sources as raw 'Data'.
    //    SwiftData knows how to store 'Data' perfectly.
    private var sourcesData: Data?
    // --- END OF FIX ---
    
    var timestamp: Date
    
    // NEW: Property for AI-suggested actions
    var suggestedAction: String?
    
    var session: ChatSession?
    
    // --- THIS IS THE FIX ---
    // 2. We create a "computed property" (a variable with a get/set).
    //    This 'sources' variable is *not* saved to the database.
    //    It's just a clean way for the rest of your app to
    //    get and set the 'sourcesData'.
    var sources: [String]? {
        get {
            // When your app asks for 'sources', we decode it from Data.
            guard let data = sourcesData else { return nil }
            return try? JSONDecoder().decode([String].self, from: data)
        }
        set {
            // When your app sets 'sources', we encode it into Data.
            // 'newValue' is the [String]? array being passed in.
            sourcesData = try? JSONEncoder().encode(newValue)
        }
    }
    // --- END OF FIX ---
    
    init(content: String, isUser: Bool, sources: [String]?, suggestedAction: String? = nil) {
        self.id = UUID()
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
        self.suggestedAction = suggestedAction
        
        // --- THIS IS THE FIX ---
        // 3. This 'init' will now call the 'set' block of our computed
        //    property, automatically encoding and saving the data.
        self.sources = sources
        // --- END OF FIX ---
    }
}
