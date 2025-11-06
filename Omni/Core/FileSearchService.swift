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
            // First, fetch *all* chunks that contain the query text.
            let keywordDescriptor = FetchDescriptor<FileChunk>(
                predicate: #Predicate { chunk in
                    chunk.text.localizedStandardContains(query)
                }
            )
            let allQueryChunks = try modelContext.fetch(keywordDescriptor)
            
            // Now, filter them in Swift to match *only* our session's files.
            let validChunks = allQueryChunks.filter { chunk in
                // This is the correct, safe way to check
                guard let fileID = chunk.file?.id else { return false }
                return fileURLs.contains(fileID)
            }

            // --- 2. FALLBACK (GENERIC) SEARCH ---
            // If the keyword search found nothing, but we *do* have files...
            if validChunks.isEmpty && !fileURLs.isEmpty {
                print("No specific chunks found. Falling back to generic context.")
                
                // Fetch *all* chunks from the database
                let allChunksDescriptor = FetchDescriptor<FileChunk>()
                let allChunksInDB = try modelContext.fetch(allChunksDescriptor)
                
                // Filter *in Swift* for just the files we care about
                let fallbackChunks = allChunksInDB
                    .filter { chunk in
                        guard let fileID = chunk.file?.id else { return false }
                        return fileURLs.contains(fileID)
                    }
                    .sorted { $0.chunkIndex < $1.chunkIndex } // Sort by index
                    .prefix(5) // Take the first 5
                
                // Return the formatted fallback chunks
                return fallbackChunks.map { chunk in
                    ChunkSearchResult(
                        text: chunk.text,
                        fileName: chunk.file?.fileName ?? "Unknown",
                        chunkIndex: chunk.chunkIndex
                    )
                }
            }
            
            // --- 3. RETURN KEYWORD RESULTS ---
            // If the primary search *did* find chunks, return them.
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
