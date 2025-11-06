import Foundation
import SwiftData
import PDFKit // To read PDFs
import SwiftUI

@MainActor
@Observable
class FileIndexer {
    
    private let modelContainer: ModelContainer
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    // The function now returns a dictionary: [File URL: [First 5 Chunks]]
    func indexFiles(at urls: [URL]) async -> [URL: [String]] {
        
        // --- 1. THIS IS THE FIX ---
        // We create a ModelActor, which is the *only*
        // 100% safe way to use SwiftData on a background thread.
        let indexerActor = IndexerActor(modelContainer: self.modelContainer)
        
        // We now call the actor to do the background work.
        let overviewData = await indexerActor.indexFiles(at: urls)
        return overviewData
        // --- END OF FIX ---
    }
}

// --- 2. NEW ACTOR ---
// This new 'actor' lives in the *same file* (FileIndexer.swift).
// Its only job is to safely handle background database work.
@ModelActor
actor IndexerActor {
    
    // This function will run safely on a background thread
    func indexFiles(at urls: [URL]) async -> [URL: [String]] {
        
        var overviewData: [URL: [String]] = [:]
        
        for url in urls {
            guard url.startAccessingSecurityScopedResource() else {
                print("Failed to get security access for file: \(url.lastPathComponent)")
                continue
            }
            defer { url.stopAccessingSecurityScopedResource() }
            
            print("Starting to index: \(url.lastPathComponent)")
            
            guard let content = self.readFileContent(at: url) else {
                print("Unsupported file type or failed to read: \(url.lastPathComponent)")
                continue
            }
            
            let chunks = self.chunk(text: content)
            guard !chunks.isEmpty else {
                print("File was empty or could not be chunked: \(url.lastPathComponent)")
                continue
            }
            
            let overviewChunks = Array(chunks.prefix(5))
            overviewData[url] = overviewChunks
            
            // We use the actor's *own* safe context
            await self.save(chunks: chunks, for: url, context: self.modelContext)
            
            print("Successfully indexed \(chunks.count) chunks for \(url.lastPathComponent)")
        }
        
        return overviewData
    }

    // --- All helper functions are now part of the actor ---
    
    private func readFileContent(at url: URL) -> String? {
        switch url.pathExtension.lowercased() {
        case "pdf":
            return readPDF(at: url)
        case "txt", "md", "swift", "py", "js", "html", "css", "json", "xml":
            return readText(at: url)
        default:
            return nil
        }
    }
    
    private func readPDF(at url: URL) -> String? {
        guard let pdfDocument = PDFDocument(url: url) else { return nil }
        var fullText = ""
        for i in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: i) else { continue }
            if let pageText = page.string {
                fullText.append(pageText + "\n\n")
            }
        }
        return fullText.isEmpty ? nil : fullText
    }
    
    private func readText(at url: URL) -> String? {
        try? String(contentsOf: url, encoding: .utf8)
    }
    
    private func chunk(text: String) -> [String] {
        return text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && $0.count > 10 }
    }
    
    private func save(chunks: [String], for url: URL, context: ModelContext) async {
        let existingFile = fetchExistingFile(for: url, context: context)
        if let existingFile {
            print("Re-indexing... deleting old file data.")
            context.delete(existingFile)
        }
        
        let indexedFile = IndexedFile(url: url)
        
        for (index, chunkText) in chunks.enumerated() {
            let fileChunk = FileChunk(
                text: chunkText,
                chunkIndex: index,
                file: indexedFile
            )
            indexedFile.chunks.append(fileChunk)
        }
        
        context.insert(indexedFile)
        
        do {
            try context.save()
        } catch {
            print("Failed to save indexed file to database: \(error)")
        }
    }
    
    private func fetchExistingFile(for url: URL, context: ModelContext) -> IndexedFile? {
        let descriptor = FetchDescriptor<IndexedFile>(
            predicate: #Predicate { $0.id == url }
        )
        return (try? context.fetch(descriptor))?.first
    }
}
