import Foundation
import SwiftData

@Model
final class IndexedFile {
    // We use the file's URL as its unique ID
    @Attribute(.unique) var id: URL
    var fileName: String
    var lastIndexed: Date
    
    // This creates the relationship: one file has many chunks
    @Relationship(deleteRule: .cascade)
    var chunks: [FileChunk] = []
    
    init(url: URL) {
        self.id = url
        self.fileName = url.lastPathComponent
        self.lastIndexed = Date()
    }
}
