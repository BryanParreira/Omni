import SwiftUI
import Combine
import SwiftData
import AppKit

@MainActor
class ContentViewModel: ObservableObject {
    
    // ... (all your existing properties) ...
    var modelContext: ModelContext
    @Published var currentSession: ChatSession
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var shouldFocusInput: Bool = false
    @Published var attachedFiles: [URL] = []
    private let searchService = FileSearchService()
    
    init(modelContext: ModelContext, session: ChatSession) {
        // ... (init is unchanged) ...
        self.modelContext = modelContext
        self.currentSession = session
    }
    
    // ... (focusInput, addAttachedFiles, removeAttachment) ...
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
        // ... (sendMessage is unchanged) ...
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessageText = inputText
        let userAttachments = attachedFiles
        
        inputText = ""
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
                
                let aiResponse = try await LLMManager.shared.generateResponse(
                    query: userMessageText,
                    context: context,
                    files: userAttachments
                )
                
                botMessage = ChatMessage(
                    content: aiResponse.content,
                    isUser: false,
                    sources: finalSourceFilePaths.isEmpty ? nil : finalSourceFilePaths,
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
            
            currentSession.messages.append(botMessage)
            try? modelContext.save()
            isLoading = false
        }
    }
    
    func clearChat() {
        // ... (clearChat is unchanged) ...
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
        
        try? modelContext.save()
        self.attachedFiles = []
    }
    
    // --- THIS IS THE FIX ---
    // We add all our new actions to the 'switch' statement
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
            // "Copy this summary" action
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(message.content, forType: .string)
            
        case "EXPLAIN_CODE", "FIND_BUGS", "ANALYZE_DATA", "FIND_TRENDS":
            // For these actions, let's pre-fill the user's input
            // text and let them send the new message.
            let (title, _) = titleAndIcon(for: action) // Get the button title
            self.inputText = title // Set the text field
            self.focusInput() // Focus the text field
            
        default:
            print("Unknown action: \(action)")
        }
    }
    
    // Helper to get the button title (to avoid duplicating logic)
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
    // --- END OF FIX ---
}
