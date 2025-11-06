import Foundation
import SwiftData

@Model
final class ChatSession {
    @Attribute(.unique) var id: UUID
    var title: String
    var startDate: Date
    
    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.session)
    var messages: [ChatMessage] = []
    
    // --- THIS IS THE FIX ---
    // 1. We'll store the URLs as 'Data', just like in ChatMessage.
    private var attachedFilesData: Data?
    
    init(title: String) {
        self.id = UUID()
        self.title = title
        self.startDate = Date()
        self.attachedFilesData = nil // Initialize as nil
    }
    
    // 2. We use JSONEncoder/Decoder. This is 100% reliable.
    //    It avoids all the 'NSKeyedArchiver' bugs.
    var attachedFileURLs: [URL] {
        get {
            // Decodes the Data back into an array of URLs
            guard let data = attachedFilesData else { return [] }
            do {
                return try JSONDecoder().decode([URL].self, from: data)
            } catch {
                print("Failed to decode attachedFileURLs: \(error)")
                return []
            }
        }
        set {
            // Encodes the array of URLs into Data
            do {
                let data = try JSONEncoder().encode(newValue)
                self.attachedFilesData = data
            } catch {
                print("Failed to encode attachedFileURLs: \(error)")
            }
        }
    }
    // --- END OF FIX ---
}
