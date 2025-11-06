import Foundation

enum LLMMode {
    case openAI
    case local
}

// --- 1. WE HAVE DELETED THE 'LLMMessage' STRUCT ---
// We will use 'OpenAIMessage' from your OpenAIClient.swift file instead.

class LLMManager {
    static let shared = LLMManager()
    
    private init() {}
    
    private var currentMode: LLMMode {
        let apiKey = UserDefaults.standard.string(forKey: "openai_api_key")
        let provider = UserDefaults.standard.string(forKey: "selected_provider")
        
        if provider == "openai" && (apiKey != nil && !apiKey!.isEmpty) {
            return .openAI
        }
        return .local
    }
    
    private let generalSystemPrompt = """
    You are a helpful general-purpose AI assistant named Omni.
    Answer the user's question clearly and concisely.
    You can optionally suggest one follow-up action.
    The tag format is [ACTION: ACTION_NAME].
    Example: [ACTION: DRAFT_EMAIL]
    """

    func generateResponse(chatHistory: [ChatMessage], context: String, files: [URL]) async throws -> (content: String, action: String?) {
        
        let responseText: String
        
        // --- 2. BUILD THE CHAT HISTORY (using OpenAIMessage) ---
        var messages: [OpenAIMessage] = [] // <-- Use OpenAIMessage
        
        let systemPrompt = files.isEmpty ? generalSystemPrompt : generateSmartPrompt(for: files)
        messages.append(OpenAIMessage(role: "system", content: systemPrompt)) // <-- Use OpenAIMessage
        
        if !context.isEmpty {
            let contextMessage = "File Context:\n\(context)"
            messages.append(OpenAIMessage(role: "user", content: contextMessage)) // <-- Use OpenAIMessage
        }
        
        for message in chatHistory {
            if message.content.contains("Hi! I'm Omni") && chatHistory.count == 1 {
                continue
            }
            let role = message.isUser ? "user" : "assistant"
            messages.append(OpenAIMessage(role: role, content: message.content)) // <-- Use OpenAIMessage
        }
        
        // --- 3. UPDATE THE CALLS ---
        switch currentMode {
        case .openAI:
            // This call is now correct and will compile
            responseText = try await OpenAIClient.shared.generateResponse(
                messages: messages
            )
        case .local:
            // This call will still have an error, which is expected
            responseText = try await LocalLLMRunner.shared.generateResponse(
                messages: messages
            )
        }
        
        return self.parseResponseForAction(responseText)
    }
    
    // --- (generateSmartPrompt and parseResponseForAction are unchanged) ---
    
    private func generateSmartPrompt(for files: [URL]) -> String {
        var fileTypes = Set<String>()
        for file in files {
            fileTypes.insert(file.pathExtension.lowercased())
        }
        
        var actionsPrompt = """
        ACTIONS:
        Your response MUST end with a single action tag.
        The tag format is [ACTION: ACTION_NAME].
        """
        
        if fileTypes.contains("pdf") || fileTypes.contains("txt") || fileTypes.contains("md") {
            actionsPrompt += "\n- For this document, suggest 'SUMMARIZE_DOCUMENT'."
            actionsPrompt += "\n- If the user asks for a summary, suggest 'DRAFT_EMAIL'."
        }
        if fileTypes.contains("swift") || fileTypes.contains("py") || fileTypes.contains("js") {
            actionsPrompt += "\n- For this code file, suggest 'EXPLAIN_CODE' or 'FIND_BUGS'."
        }
        if fileTypes.contains("csv") {
            actionsPrompt += "\n- For this CSV file, suggest 'ANALYZE_DATA' or 'FIND_TRENDS'."
        }
        actionsPrompt += "\n- For a generic request, you can suggest 'DRAFT_EMAIL'."
        actionsPrompt += "\n- Example ending: [ACTION: EXPLAIN_CODE]"

        return """
        You are a File System Analyst AI assistant.
        
        CRITICAL RULES:
        1. Answer questions ONLY based on the file content provided in the context.
        2. ALWAYS cite the source file name (e.g., "According to 'Resume.pdf'...").
        3. If the context doesn't contain relevant information, say so clearly.

        \(actionsPrompt)
        """
    }
    
    private func parseResponseForAction(_ text: String) -> (content: String, action: String?) {
        if let range = text.range(of: "[ACTION:", options: .backwards) {
            let tagPart = text[range.lowerBound...]
            if let endRange = tagPart.range(of: "]") {
                let actionTag = tagPart[range.upperBound..<endRange.lowerBound]
                let cleanContent = text[..<range.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
                let cleanAction = String(actionTag).trimmingCharacters(in: .whitespacesAndNewlines)
                
                if cleanAction.isEmpty { return (content: cleanContent, action: nil) }
                return (content: cleanContent, action: cleanAction)
            }
        }
        
        if let range = text.range(of: "[", options: .backwards), let endRange = text.range(of: "]", options: .backwards), range.lowerBound < endRange.lowerBound {
            
            let tag = text[range.upperBound..<endRange.lowerBound]
            
            let potentialAction = String(tag).trimmingCharacters(in: .whitespacesAndNewlines)
            if potentialAction.allSatisfy({ $0.isUppercase || $0 == "_" }) {
                let cleanContent = text[..<range.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
                return (content: cleanContent, action: potentialAction)
            }
        }
        
        return (content: text.trimmingCharacters(in: .whitespacesAndNewlines), action: nil)
    }
}
