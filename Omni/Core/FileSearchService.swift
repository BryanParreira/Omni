import Foundation
import SwiftData

/// A struct to hold a *chunk* search result.
struct ChunkSearchResult {
    let text: String
    let fileName: String
    let chunkIndex: Int
}

/// This class searches the SwiftData database for relevant *chunks*.
class FileSearchService {
    
    func searchChunks(query: String, in fileURLs: [URL], modelContext: ModelContext) async -> [ChunkSearchResult] {
        
        do {
            // --- 1. PRIMARY (KEYWORD) SEARCH ---
            let keywordDescriptor = FetchDescriptor<FileChunk>(
                predicate: #Predicate { chunk in
                    chunk.text.localizedStandardContains(query)
                }
            )
            let allQueryChunks = try modelContext.fetch(keywordDescriptor)
            
            let validChunks = allQueryChunks.filter { chunk in
                guard let fileID = chunk.file?.id else { return false }
                return fileURLs.contains(fileID)
            }

            // --- 2. FALLBACK (GENERIC) SEARCH ---
            if validChunks.isEmpty && !fileURLs.isEmpty {
                
                // --- 🛑 CLEANUP 🛑 ---
                // Removed the debug 'print' statement from this block
                // --- 🛑 END OF CLEANUP 🛑 ---
                
                let allChunksDescriptor = FetchDescriptor<FileChunk>()
                let allChunksInDB = try modelContext.fetch(allChunksDescriptor)
                
                let fallbackChunks = allChunksInDB
                    .filter { chunk in
                        guard let fileID = chunk.file?.id else { return false }
                        return fileURLs.contains(fileID)
                    }
                    .sorted { $0.chunkIndex < $1.chunkIndex } // Sort by index
                    .prefix(5) // Take the first 5
                
                return fallbackChunks.map { chunk in
                    ChunkSearchResult(
                        text: chunk.text,
                        fileName: chunk.file?.fileName ?? "Unknown",
                        chunkIndex: chunk.chunkIndex
                    )
                }
            }
            
            // --- 3. RETURN KEYWORD RESULTS ---
            return validChunks.map { chunk in
                ChunkSearchResult(
                    text: chunk.text,
                    fileName: chunk.file?.fileName ?? "Unknown",
                    chunkIndex: chunk.chunkIndex
                )
            }
            
        } catch {
            print("Failed to fetch chunks: \(error)")
            return []
        }
    }
}
