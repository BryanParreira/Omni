import SwiftUI
import Combine
import SwiftData

@MainActor
class ContentViewModel: ObservableObject {
    
    // --- Properties ---
    var modelContext: ModelContext
    @Published var currentSession: ChatSession
    
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var shouldFocusInput: Bool = false
    @Published var attachedFiles: [URL] = []
    
    // We are removing the @-mention popover logic
    
    private let searchService = FileSearchService()
    
    // NEW: The init now requires a Session
    init(modelContext: ModelContext, session: ChatSession) {
        self.modelContext = modelContext
        self.currentSession = session
    }
    
    // All the old init() and loadLastSession() code is GONE
    
    func focusInput() {
        shouldFocusInput = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldFocusInput = false
        }
    }
    
    func addAttachedFiles(urls: [URL]) {
        for url in urls {
            if !attachedFiles.contains(url) {
                attachedFiles.append(url)
            }
        }
    }
    
    func removeAttachment(url: URL) {
        attachedFiles.removeAll(where: { $0 == url })
    }

    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessageText = inputText
        let userAttachments = attachedFiles
        
        inputText = ""
        // Files are kept for conversational memory
        
        let sourceFilePaths = userAttachments.map { $0.path }
        
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
                var context = "No file context found."
                var finalSourceFilePaths: [String] = []
                
                if !userAttachments.isEmpty {
                    let reader = FileSearchService()
                    var fileContents: [String] = []
                    
                    for url in userAttachments {
                        if let content = await reader.readFileContent(at: url) {
                            fileContents.append("File: \(url.lastPathComponent)\nContent: \(content)")
                            finalSourceFilePaths.append(url.path)
                        }
                    }
                    if !fileContents.isEmpty {
                        context = fileContents.joined(separator: "\n\n---\n\n")
                    }
                } else {
                    let searchResults = await searchService.search(query: userMessageText)
                    if !searchResults.isEmpty {
                        context = searchResults
                            .map { "File: \($0.filePath)\nContent: \($0.fileContent)" }
                            .joined(separator: "\n\n---\n\n")
                        finalSourceFilePaths = searchResults.map { $0.filePath }
                    }
                }
                
                // --- THIS IS THE FIX (Line 109) ---
                // 1. Store the full tuple response (which is (content: String, action: String?))
                let aiResponse = try await LLMManager.shared.generateResponse(
                    query: userMessageText,
                    context: context
                )
                
                botMessage = ChatMessage(
                    // 2. Access the .content property from the tuple (Line 115)
                    content: aiResponse.content,
                    isUser: false,
                    sources: finalSourceFilePaths.isEmpty ? nil : finalSourceFilePaths
                )
                // --- END OF FIX ---
                
            } catch {
                let errorMessage = "Sorry, an error occurred: \(error.localizedDescription)"
                botMessage = ChatMessage(
                    content: errorMessage,
                    isUser: false,
                    sources: nil
                )
            }
            
            currentSession.messages.append(botMessage)
            try? modelContext.save()
            isLoading = false
        }
    }
    
    // NEW: "Clear Chat" now just deletes all messages in *this* session
    // It does not create a new one. The sidebar "New Chat" button does.
    func clearChat() {
        for message in currentSession.messages {
            modelContext.delete(message)
        }
        
        // Add the welcome message back
        let welcomeMessage = ChatMessage(
            content: "Chat cleared. How can I help you today?",
            isUser: false,
            sources: nil
        )
        currentSession.messages.append(welcomeMessage)
        currentSession.title = "New Chat" // Reset title
        
        try? modelContext.save()
        self.attachedFiles = []
    }
}
