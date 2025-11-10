import Foundation
import SwiftData

@Model
final class GlobalSourceFile {
    
    // We store the bookmark data as the unique ID.
    // This is a secure way to save a file reference.
    @Attribute(.unique) var id: Data
    
    var fileName: String
    var dateAdded: Date
    
    init(bookmarkData: Data, fileName: String) {
        self.id = bookmarkData
        self.fileName = fileName
        self.dateAdded = Date()
    }
    
    /// This helper function safely converts the secure bookmark data
    /// back into a usable URL that we can read.
    func getURL() -> URL? {
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: self.id,
                              options: .withSecurityScope, // Crucial for sandboxed apps
                              relativeTo: nil,
                              bookmarkDataIsStale: &isStale)
            
            if isStale {
                // In a future version, we could refresh the bookmark,
                // but for now, this is fine.
                print("Bookmark is stale for: \(self.fileName)")
            }
            
            return url
        } catch {
            print("Error resolving bookmark data: \(error.localizedDescription)")
            return nil
        }
    }
}
