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
    
    @Published var isShowingNotebook: Bool = false
    @Published var notebookContent: String = ""
    @Published var isGeneratingNotebook: Bool = false
    
    private var fileIndexer: FileIndexer
    private let searchService = FileSearchService()
    
    init(modelContext: ModelContext, session: ChatSession, fileIndexer: FileIndexer) {
        self.modelContext = modelContext
        self.currentSession = session
        self.fileIndexer = fileIndexer
    }
    
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
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // --- 🛑 ONE-LINE FIX 🛑 ---
        // Force the UI to update when the message is sent,
        // which will re-evaluate 'shouldShowFilePills' and hide the pills.
        objectWillChange.send()
        // --- 🛑 END OF FIX 🛑 ---
        
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
}
