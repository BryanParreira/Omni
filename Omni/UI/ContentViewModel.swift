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
                // Only stop access for security-scoped URLs (file drops)
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
            inputText = "" // Clear the input field
            
            Task {
                // Add a placeholder message
                let tempMessage = ChatMessage(content: "Reading from \(url.host ?? "web page")...", isUser: false, sources: nil)
                await MainActor.run {
                    currentSession.messages.append(tempMessage)
                }
                
                guard let cleanText = await scraper.fetchAndCleanText(from: url) else {
                    // Handle error
                    await MainActor.run {
                        tempMessage.content = "Sorry, I couldn't read the content from that URL."
                        isLoading = false
                    }
                    return
                }
                
                // Save the clean text to a temporary file
                let fileName = (url.host ?? "web_source") + ".txt"
                if let tempFileURL = saveTextAsTempFile(text: cleanText, fileName: fileName) {
                    // Use our *existing* function to add this new temp file
                    await MainActor.run {
                        // Remove the placeholder
                        currentSession.messages.removeAll(where: { $0.id == tempMessage.id })
                        modelContext.delete(tempMessage)
                        
                        addAttachedFiles(urls: [tempFileURL])
                        isLoading = false
                        objectWillChange.send() // Force UI to update pills
                    }
                } else {
                    await MainActor.run {
                        tempMessage.content = "Sorry, I couldn't save the web content as a file."
                        isLoading = false
                    }
                }
            }
            return // Stop here. Do not send this as a chat message.
        }
        
        // --- 2. Standard Message Logic ---
        
        objectWillChange.send() // This hides the file pills
        
        let userMessageText = inputText
        let sessionAttachments = currentSession.attachedFileURLs
        
        inputText = ""
        let sourceFilePaths = sessionAttachments.map { $0.path }
        
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
            let botSourceFilePaths = sessionAttachments.map { $0.path }
            
            do {
                var context = ""
                
                if !sessionAttachments.isEmpty {
                    let chunks = await searchService.searchChunks(
                        query: userMessageText,
                        in: sessionAttachments,
                        modelContext: modelContext
                    )
                    
                    if chunks.isEmpty {
                        context = "No relevant context found in the attached files for that query."
                    } else {
                        context = "RELEVANT CONTEXT:\n"
                        context += chunks.map { "Chunk from '\($0.fileName)':\n\($0.text)" }
                                         .joined(separator: "\n\n---\n\n")
                    }
                }
                
                let chatHistory = Array(currentSession.messages)
                
                let aiResponse = try await LLMManager.shared.generateResponse(
                    chatHistory: chatHistory,
                    context: context,
                    files: sessionAttachments
                )
                
                botMessage = ChatMessage(
                    content: aiResponse.content,
                    isUser: false,
                    sources: botSourceFilePaths.isEmpty ? nil : botSourceFilePaths,
                    suggestedAction: aiResponse.action
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
                let generatedNote = try await LLMManager.shared.generateNotebook(
                    chatHistory: Array(currentSession.messages),
                    files: currentSession.attachedFileURLs
                )
                
                self.notebookContent = generatedNote
                self.isGeneratingNotebook = false
                
            } catch {
                self.notebookContent = "Sorry, an error occurred while generating the notebook:\n\n\(error.localizedDescription)"
                self.isGeneratingNotebook = false
            }
        }
    }
    
    func performAction(action: String, on message: ChatMessage) {
        switch action {
        case "DRAFT_EMAIL":
            let summary = message.content
            let subject = "Summary"
            guard let encodedBody = summary.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let mailtoURL = URL(string: "mailto:?subject=\(subject)&body=\(encodedBody)")
            else {
                print("Error creating mailto link")
                return
            }
            NSWorkspace.shared.open(mailtoURL)
            
        case "SUMMARIZE_DOCUMENT":
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(message.content, forType: .string)
            
        case "EXPLAIN_CODE", "FIND_BUGS", "ANALYZE_DATA", "FIND_TRENDS":
            let (title, _) = titleAndIcon(for: action)
            self.inputText = title
            self.focusInput()
            
        default:
            print("Unknown action: \(action)")
        }
    }
    
    // MARK: - Private Helpers
    
    private func titleAndIcon(for action: String) -> (String, String) {
        switch action {
        case "DRAFT_EMAIL":
            return ("Draft an email with this summary", "square.and.pencil")
        case "SUMMARIZE_DOCUMENT":
            return ("Copy this summary", "doc.on.doc")
        case "EXPLAIN_CODE":
            return ("Explain this code", "doc.text.magnifyingglass")
        case "FIND_BUGS":
            return ("Find potential bugs in this code", "ant")
        case "ANALYZE_DATA":
            return ("Analyze this data", "chart.bar")
        case "FIND_TRENDS":
            return ("Find trends in this data", "chart.line.uptrend.xyaxis")
        default:
            return (action.replacingOccurrences(of: "_", with: " ").capitalized, "sparkles")
        }
    }
    
    /// Saves a string of text to a temporary .txt file and returns its URL.
    private func saveTextAsTempFile(text: String, fileName: String) -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
        // Sanitize file name
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
