import Foundation
import SwiftData

@Model
final class ChatSession {
    @Attribute(.unique) var id: UUID
    var title: String
    var startDate: Date
    
    // --- 1. ADD THIS NEW PROPERTY ---
    // This will store the ID of the attached Library Project
    var attachedProjectID: UUID?
    
    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.session)
    var messages: [ChatMessage] = []
    
    private var attachedFilesData: Data?
    
    init(title: String) {
        self.id = UUID()
        self.title = title
        self.startDate = Date()
        self.attachedFilesData = nil
        self.attachedProjectID = nil // Initialize the new property
    }
    
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
}
