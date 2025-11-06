import Foundation
import CoreServices // For Core Spotlight
import PDFKit       // For reading PDFs
import Vision       // For OCR
import AppKit       // For reading rich text
import SwiftUI      // To read @AppStorage

/// A struct to hold a file search result
struct FileSearchResult {
    let id = UUID()
    let filePath: String
    let fileContent: String // The *full text content* of the file
}

/// This class will be responsible for searching the user's files
class FileSearchService {
    
    // Reads the user's setting
    @AppStorage("selected_search_scope") private var selectedSearchScope: String = "home"
    
    private var metadataQuery: NSMetadataQuery?
    private var continuation: CheckedContinuation<[URL], Error>?

    // --- DEEP SEARCH (SLOW) ---
    // This is now the only search function
    func search(query: String) async -> [FileSearchResult] {
        
        guard let fileURLs = try? await findFilePaths(query: query) else {
            return []
        }
        
        var results: [FileSearchResult] = []
        for url in fileURLs {
            if let content = await readFileContent(at: url), !content.isEmpty {
                results.append(FileSearchResult(filePath: url.path, fileContent: content))
            }
        }
        
        return results
    }
    
    // searchFileNames function has been removed
    
    // findFilePaths is now simplified
    private func findFilePaths(query: String) async throws -> [URL] {
        if metadataQuery != nil {
            metadataQuery?.stop()
            metadataQuery = nil
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            let newMetadataQuery = NSMetadataQuery()
            self.metadataQuery = newMetadataQuery
            
            // Set the search scope based on the user's setting
            let fileManager = FileManager.default
            var scopes: [Any] = []
            
            switch selectedSearchScope {
            case "documents":
                if let docURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                    scopes.append(docURL)
                }
            case "desktop":
                if let deskURL = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first {
                    scopes.append(deskURL)
                }
            default: // "home"
                scopes.append(NSMetadataQueryUserHomeScope)
            }
            
            newMetadataQuery.searchScopes = scopes
            
            // We only need the one deep search predicate
            newMetadataQuery.predicate = NSPredicate(format: "kMDItemTextContent CONTAINS[c] %@ OR kMDItemDisplayName CONTAINS[c] %@", query, query)
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(queryDidFinish),
                name: .NSMetadataQueryDidFinishGathering,
                object: newMetadataQuery
            )
            
            newMetadataQuery.start()
        }
    }
    
    @objc private func queryDidFinish(_ notification: Notification) {
        guard let finishedQuery = notification.object as? NSMetadataQuery else { return }
        finishedQuery.stop()
        
        var fileURLs: [URL] = []
        
        let maxResults = 10
        for item in finishedQuery.results.prefix(maxResults) {
            guard let metadataItem = item as? NSMetadataItem,
                  let filePath = metadataItem.value(forAttribute: kMDItemPath as String) as? String else {
                continue
            }
            
            let fileURL = URL(fileURLWithPath: filePath)
            
            if !isPathInSystemFolder(filePath) {
                fileURLs.append(fileURL)
            }
        }
        
        continuation?.resume(returning: fileURLs)
        continuation = nil
        
        NotificationCenter.default.removeObserver(self)
        self.metadataQuery = nil
    }
    
    func readFileContent(at url: URL) async -> String? {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "pdf":
            guard let pdfDocument = PDFDocument(url: url) else { return nil }
            return pdfDocument.string
            
        case "docx", "doc", "rtf", "html":
            do {
                let data = try Data(contentsOf: url)
                let attributedString = try NSAttributedString(
                    data: data,
                    options: [.documentType: documentType(for: fileExtension)],
                    documentAttributes: nil
                )
                return attributedString.string
            } catch {
                print("Failed to read rich text file: \(error)")
                return nil
            }
        
        case "png", "jpg", "jpeg":
            return await extractTextFromImage(url: url)
            
        case "txt", "md", "swift", "py", "js", "css", "json", "xml", "yml", "yaml", "csv", "java", "c", "h", "cpp", "cs", "go", "rb", "php", "ts":
            do {
                return try String(contentsOf: url, encoding: .utf8)
            } catch {
                print("Failed to read text file: \(error)")
                return nil
            }
            
        default:
            return nil
        }
    }
    
    private func documentType(for fileExtension: String) -> NSAttributedString.DocumentType {
        switch fileExtension {
        case "docx":
            return .officeOpenXML
        case "doc":
            return .docFormat
        case "rtf":
            return .rtf
        case "html":
            return .html
        default:
            return .plain
        }
    }
    
    private func extractTextFromImage(url: URL) async -> String? {
        let requestHandler: VNImageRequestHandler
        
        if let imageData = try? Data(contentsOf: url) {
            requestHandler = VNImageRequestHandler(data: imageData)
        } else if let image = NSImage(contentsOf: url), let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            requestHandler = VNImageRequestHandler(cgImage: cgImage)
        } else {
            return nil
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate

        return await withCheckedContinuation { continuation in
            do {
                try requestHandler.perform([request])
                
                guard let observations = request.results else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                continuation.resume(returning: recognizedStrings.joined(separator: "\n"))
                
            } catch {
                print("Vision text recognition failed: \(error)")
                continuation.resume(returning: nil)
            }
        }
    }
    
    private func isPathInSystemFolder(_ path: String) -> Bool {
        let systemFolders = ["/Library/", "/System/", "/Applications/", "/private/", "/.Trash/"]
        let userLibrary = "/Users/\(NSUserName())/Library/"
        
        if path.contains(userLibrary) { return true }
        
        for folder in systemFolders {
            if path.hasPrefix(folder) { return true }
        }
        
        return false
    }
}
