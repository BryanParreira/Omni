import SwiftUI
import Combine
import SwiftData
import AppKit

@MainActor
class ContentViewModel: ObservableObject {
    
    var modelContext: ModelContext
    @Published var currentSession: ChatSession
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var shouldFocusInput: Bool = false
    
    // We removed the local attachedFiles array
    
    private let searchService = FileSearchService()
    
    init(modelContext: ModelContext, session: ChatSession) {
        self.modelContext = modelContext
        self.currentSession = session
    }
    
    func focusInput() {
        shouldFocusInput = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldFocusInput = false
        }
    }
    
    func addAttachedFiles(urls: [URL]) {
        for url in urls {
            if !currentSession.attachedFileURLs.contains(url) {
                currentSession.attachedFileURLs.append(url)
            }
        }
    }
    
    func removeAttachment(url: URL) {
        currentSession.attachedFileURLs.removeAll(where: { $0 == url })
    }

    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessageText = inputText
        let sessionAttachments = currentSession.attachedFileURLs
        
        inputText = ""
        let sourceFilePaths = sessionAttachments.map { $0.path }
        
        // --- 1. THIS IS THE FIX ---
        // The user's message *should* show the sources it was sent with.
        let userMessage = ChatMessage(
            content: userMessageText,
            isUser: true,
            sources: sourceFilePaths.isEmpty ? nil : sourceFilePaths
        )
        // --- END OF FIX ---
        
        currentSession.messages.append(userMessage)
        
        if currentSession.title == "New Chat" {
            let title = String(userMessageText.prefix(40))
            currentSession.title = title
        }
        
        isLoading = true
        
        Task {
            var botMessage: ChatMessage
            
            // We use the same source paths for the bot's response
            // to show it's part of the same context.
            let botSourceFilePaths = sessionAttachments.map { $0.path }
            
            do {
                var context = ""
                
                if !sessionAttachments.isEmpty {
                    let reader = FileSearchService()
                    var fileContents: [String] = []
                    
                    for url in sessionAttachments {
                        if let content = await reader.readFileContent(at: url) {
                            fileContents.append("File: \(url.lastPathComponent)\nContent: \(content)")
                        }
                    }
                    if !fileContents.isEmpty {
                        context = fileContents.joined(separator: "\n\n---\n\n")
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
            
            currentSession.messages.append(botMessage)
            try? modelContext.save()
            isLoading = false
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
        currentSession.attachedFileURLs = []
        
        try? modelContext.save()
    }
    
    func performAction(action: String, on message: ChatMessage) {
        // ... (performAction is unchanged) ...
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
    
    private func titleAndIcon(for action: String) -> (String, String) {
        // ... (helper is unchanged) ...
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
}
