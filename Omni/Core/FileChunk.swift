import Foundation
import SwiftData

@Model
final class FileChunk {
    var text: String          // The actual text of the paragraph
    var chunkIndex: Int       // The order of this chunk (e.g., 0, 1, 2, 3...)
    
    // This links a chunk back to its parent file
    var file: IndexedFile?
    
    init(text: String, chunkIndex: Int, file: IndexedFile) {
        self.text = text
        self.chunkIndex = chunkIndex
        self.file = file
    }
}
