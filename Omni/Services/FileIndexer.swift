import Foundation
import SwiftData
import PDFKit // To read PDFs
import SwiftUI
import Vision // Import Vision for OCR

@MainActor
@Observable
class FileIndexer {
    
    private let modelContainer: ModelContainer
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    /// Indexes files at the given URLs on a background thread.
    /// - Parameter urls: The array of file URLs to index.
    /// - Returns: A dictionary mapping each file URL to its first 5 text chunks, for overview generation.
    func indexFiles(at urls: [URL]) async -> [URL: [String]] {
        // Use a ModelActor for 100% safe background thread database work.
        let indexerActor = IndexerActor(modelContainer: self.modelContainer)
        let overviewData = await indexerActor.indexFiles(at: urls)
        return overviewData
    }
}

@ModelActor
actor IndexerActor {
    
    // Add OCRService instance
    private let ocrService = OCRService()
    
    /// This function runs safely on a background thread via the ModelActor.
    func indexFiles(at urls: [URL]) async -> [URL: [String]] {
        
        var overviewData: [URL: [String]] = [:]
        
        for url in urls {
            
            // Check if the file is in our app's temp directory (e.g., a web scrape)
            let isTempFile = url.path.starts(with: FileManager.default.temporaryDirectory.path)
            
            // If it's NOT a temp file, we must perform the security check.
            if !isTempFile {
                guard url.startAccessingSecurityScopedResource() else {
                    print("Failed to get security access for file: \(url.lastPathComponent)")
                    continue
                }
                defer { url.stopAccessingSecurityScopedResource() }
            }
            
            // Changed to 'await' for OCR support
            guard let content = await self.readFileContent(at: url) else {
                print("Unsupported file type or failed to read: \(url.lastPathComponent)")
                continue
            }
            
            let chunks = self.chunk(text: content)
            guard !chunks.isEmpty else {
                print("File was empty or could not be chunked: \(url.lastPathComponent)")
                continue
            }
            
            // Store the first 5 chunks to return for the summary
            let overviewChunks = Array(chunks.prefix(5))
            overviewData[url] = overviewChunks
            
            // Save the file and all its chunks to the database
            await self.save(chunks: chunks, for: url, context: self.modelContext)
        }
        
        return overviewData
    }

    // MARK: - File Reading
    
    // Made async to support OCR
    private func readFileContent(at url: URL) async -> String? {
        switch url.pathExtension.lowercased() {
        case "pdf":
            return readPDF(at: url)
        case "txt", "md", "swift", "py", "js", "html", "css", "json", "xml":
            return readText(at: url)
        // Add image support with OCR
        case "jpg", "jpeg", "png", "heic", "tiff", "gif", "bmp":
            return await ocrService.extractText(from: url)
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
    
    /// Splits a large block of text into smaller, more manageable chunks.
    private func chunk(text: String) -> [String] {
        return text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && $0.count > 10 } // Ignore empty or very short lines
    }
    
    // MARK: - Database Operations
    
    private func save(chunks: [String], for url: URL, context: ModelContext) async {
        // Clear out any old data for this same file URL
        let existingFile = fetchExistingFile(for: url, context: context)
        if let existingFile {
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
