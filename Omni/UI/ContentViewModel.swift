import SwiftUI
import Combine
import SwiftData
import AppKit

@MainActor
class ContentViewModel: ObservableObject {
    
    // MARK: - Properties
    
    var modelContext: ModelContext
    @Published var currentSession: ChatSession
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var shouldFocusInput: Bool = false
    
    @Published var isShowingNotebook: Bool = false
    @Published var notebookContent: String = ""
    @Published var isGeneratingNotebook: Bool = false
    
    @Published var useGlobalLibrary: Bool = false
    
    private var fileIndexer: FileIndexer
    private let searchService = FileSearchService()
    private let scraper = WebScraperService()
    
    // MARK: - Init
    
    init(modelContext: ModelContext, session: ChatSession, fileIndexer: FileIndexer) {
        self.modelContext = modelContext
        self.currentSession = session
        self.fileIndexer = fileIndexer
    }
    
    // MARK: - Public Methods
    
    func focusInput() {
        shouldFocusInput = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldFocusInput = false
        }
    }
    
    func addAttachedFiles(urls: [URL]) {
        objectWillChange.send()
        
        var newURLs: [URL] = []
        for url in urls {
            if !currentSession.attachedFileURLs.contains(url) {
                currentSession.attachedFileURLs.append(url)
                newURLs.append(url)
            }
        }
        
        Task {
            _ = await fileIndexer.indexFiles(at: newURLs)
            
            for url in newURLs {
                _ = url.startAccessingSecurityScopedResource()
                url.stopAccessingSecurityScopedResource()
            }
            
            await MainActor.run {
                try? modelContext.save()
            }
        }
    }
    
    func removeAttachment(url: URL) {
        objectWillChange.send()
        currentSession.attachedFileURLs.removeAll(where: { $0 == url })
        url.stopAccessingSecurityScopedResource()
        try? modelContext.save()
    }

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        // --- 1. URL Check ---
        if let url = URL(string: text), ["http", "https"].contains(url.scheme?.lowercased()) {
            
            isLoading = true
            inputText = ""
            
            Task {
                let tempMessage = ChatMessage(content: "Reading from \(url.host ?? "web page")...", isUser: false, sources: nil)
                await MainActor.run {
                    currentSession.messages.append(tempMessage)
                }
                
                guard let cleanText = await scraper.fetchAndCleanText(from: url) else {
                    await MainActor.run {
                        tempMessage.content = "Sorry, I couldn't read the content from that URL."
                        isLoading = false
                    }
                    return
                }
                
                let fileName = (url.host ?? "web_source") + ".txt"
                if let tempFileURL = saveTextAsTempFile(text: cleanText, fileName: fileName) {
                    await MainActor.run {
                        currentSession.messages.removeAll(where: { $0.id == tempMessage.id })
                        modelContext.delete(tempMessage)
                        
                        addAttachedFiles(urls: [tempFileURL])
                        isLoading = false
                        objectWillChange.send()
                    }
                } else {
                    await MainActor.run {
                        tempMessage.content = "Sorry, I couldn't save the web content as a file."
                        isLoading = false
                    }
                }
            }
            return
        }
        
        // --- 2. Standard Message Logic ---
        
        objectWillChange.send()
        
        let userMessageText = inputText
        
        // START: Modified to use LibraryManager instead of GlobalSourceFile
        var allSourceURLs = currentSession.attachedFileURLs
        var libraryFileURLs: [URL] = []
        
        // Get library context if enabled
        var libraryContextText = ""
        if useGlobalLibrary {
            let activeFiles = LibraryManager.shared.getActiveProjectFiles()
            libraryFileURLs = activeFiles.map { $0.url }
            
            // Get formatted context for AI
            libraryContextText = LibraryManager.shared.getActiveProjectContext()
            
            // Add library file URLs to sources for search
            allSourceURLs.append(contentsOf: libraryFileURLs)
        }
        // END: Modified section
        
        inputText = ""
        let sourceFilePaths = allSourceURLs.map { $0.path }
        
        let userMessage = ChatMessage(
            content: userMessageText,
            isUser: true,
            sources: sourceFilePaths.isEmpty ? nil : sourceFilePaths
        )
        currentSession.messages.append(userMessage)
        
        if currentSession.title == "New Chat" {
            let title = String(userMessageText.prefix(40))
            currentSession.title = title
        }
        
        isLoading = true
        
        Task {
            var botMessage: ChatMessage
            
            do {
                var context = ""
                
                // Add library context first if available
                if !libraryContextText.isEmpty {
                    context = libraryContextText + "\n\n---\n\n"
                }
                
                if !allSourceURLs.isEmpty {
                    let chunks = await searchService.searchChunks(
                        query: userMessageText,
                        in: allSourceURLs,
                        modelContext: modelContext
                    )
                    
                    if chunks.isEmpty && libraryContextText.isEmpty {
                        context = "No relevant context found in the attached files for that query."
                    } else if !chunks.isEmpty {
                        context += "RELEVANT CONTEXT FROM SEARCH:\n"
                        context += chunks.map { chunk in
                            let displayName = normalizeFileName(chunk.fileName)
                            return "Chunk from '\(displayName)':\n\(chunk.text)"
                        }.joined(separator: "\n\n---\n\n")
                    }
                }
                
                let chatHistory = Array(currentSession.messages)
                
                let aiResponse = try await LLMManager.shared.generateResponse(
                    chatHistory: chatHistory,
                    context: context,
                    files: allSourceURLs
                )
                
                botMessage = ChatMessage(
                    content: aiResponse,
                    isUser: false,
                    sources: sourceFilePaths.isEmpty ? nil : sourceFilePaths
                )
                
            } catch {
                let errorMessage = "Sorry, an error occurred: \(error.localizedDescription)"
                botMessage = ChatMessage(
                    content: errorMessage,
                    isUser: false,
                    sources: nil
                )
            }
            
            await MainActor.run {
                currentSession.messages.append(botMessage)
                try? modelContext.save()
                isLoading = false
            }
        }
    }
    
    func clearChat() {
        for message in currentSession.messages {
            modelContext.delete(message)
        }
        
        let welcomeMessage = ChatMessage(
            content: "Chat cleared. How can I help you today?",
            isUser: false,
            sources: nil
        )
        currentSession.messages.append(welcomeMessage)
        currentSession.title = "New Chat"
        
        objectWillChange.send()
        for url in currentSession.attachedFileURLs {
            url.stopAccessingSecurityScopedResource()
        }
        
        currentSession.attachedFileURLs = []
        
        try? modelContext.save()
    }
    
    func generateNotebook() {
        guard !isGeneratingNotebook else { return }

        isGeneratingNotebook = true
        notebookContent = "Generating your notebook, please wait..."
        isShowingNotebook = true
        
        Task {
            do {
                // Include library files in notebook generation if enabled
                var allFiles = currentSession.attachedFileURLs
                if useGlobalLibrary {
                    let libraryFiles = LibraryManager.shared.getActiveProjectFiles()
                    allFiles.append(contentsOf: libraryFiles.map { $0.url })
                }
                
                let generatedNote = try await LLMManager.shared.generateNotebook(
                    chatHistory: Array(currentSession.messages),
                    files: allFiles
                )
                
                self.notebookContent = generatedNote
                self.isGeneratingNotebook = false
                
            } catch {
                self.notebookContent = "Sorry, an error occurred while generating the notebook:\n\n\(error.localizedDescription)"
                self.isGeneratingNotebook = false
            }
        }
    }
    
    // MARK: - Private Helpers
    
    /// Normalizes filenames so images appear as generic documents to the AI
    private func normalizeFileName(_ fileName: String) -> String {
        let imageExtensions = ["jpg", "jpeg", "png", "heic", "tiff", "gif", "bmp"]
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        
        if imageExtensions.contains(fileExtension) {
            return "Document.txt"
        }
        
        return fileName
    }
    
    /// Saves a string of text to a temporary .txt file and returns its URL.
    private func saveTextAsTempFile(text: String, fileName: String) -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
        let sanitizedName = fileName.replacingOccurrences(of: "[^a-zA-Z0-9.-]", with: "_", options: .regularExpression)
        let fileURL = tempDirectory.appendingPathComponent("\(sanitizedName).txt")
        
        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error saving temp file: \(error.localizedDescription)")
            return nil
        }
    }
}
