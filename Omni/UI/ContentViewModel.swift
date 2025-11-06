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
    
    // --- 1. NEW PROPERTIES ---
    private var fileIndexer: FileIndexer // The new service
    private let searchService = FileSearchService() // We'll use this for searching chunks
    
    // --- 2. UPDATED INIT ---
    // It now accepts the FileIndexer, fixing the compile error from ContentView
    init(modelContext: ModelContext, session: ChatSession, fileIndexer: FileIndexer) {
        self.modelContext = modelContext
        self.currentSession = session
        self.fileIndexer = fileIndexer // Store it
    }
    
    func focusInput() {
        shouldFocusInput = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldFocusInput = false
        }
    }
    
    // --- 3. UPDATED FILE HANDLING ---
    // This function now saves the file to the session *and*
    // triggers the background indexing.
    func addAttachedFiles(urls: [URL]) {
        var newURLs: [URL] = []
        for url in urls {
            if !currentSession.attachedFileURLs.contains(url) {
                currentSession.attachedFileURLs.append(url)
                newURLs.append(url)
            }
        }
        
        // Trigger background indexing for the new files
        Task {
            // This now returns the overview data, but we'll use it in the next step.
            // For now, just call it.
            _ = await fileIndexer.indexFiles(at: newURLs)
            // Save after indexing is done
            try? modelContext.save()
        }
    }
    
    func removeAttachment(url: URL) {
        currentSession.attachedFileURLs.removeAll(where: { $0 == url })
        // TODO: We could also delete the index here, but for now this is fine.
        try? modelContext.save() // Fixed your typo: modelDeltac -> modelContext
    }

    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
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
                
                // --- 4. THIS IS THE NEW RAG LOGIC ---
                // If we have files, we search for *chunks*, not the whole file
                if !sessionAttachments.isEmpty {
                    
                    // 1. Search for relevant chunks in the database
                    //    (We will build this function in the next step)
                    let chunks = await searchService.searchChunks(
                        query: userMessageText,
                        in: sessionAttachments,
                        modelContext: modelContext
                    )
                    
                    if chunks.isEmpty {
                        // Fallback if no relevant chunks are found
                        // (This is what you saw in your screenshot!)
                        context = "No relevant context found in the attached files for that query."
                    } else {
                        // 2. Build the context ONLY from the relevant chunks
                        context = "RELEVANT CONTEXT:\n"
                        context += chunks.map { "Chunk from '\($0.fileName)':\n\($0.text)" }
                                         .joined(separator: "\n\n---\n\n")
                    }
                }
                // --- END OF NEW RAG LOGIC ---
                
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
