import Foundation

enum LLMMode {
    case openAI
    case local
}

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
        
        var messages: [OpenAIMessage] = []
        
        let systemPrompt = files.isEmpty ? generalSystemPrompt : generateSmartPrompt(for: files)
        messages.append(OpenAIMessage(role: "system", content: systemPrompt))
        
        if !context.isEmpty {
            let contextMessage = "File Context:\n\(context)"
            messages.append(OpenAIMessage(role: "user", content: contextMessage))
        }
        
        for message in chatHistory {
            if message.content.contains("Hi! I'm Omni") && chatHistory.count == 1 {
                continue
            }
            let role = message.isUser ? "user" : "assistant"
            messages.append(OpenAIMessage(role: role, content: message.content))
        }
        
        switch currentMode {
        case .openAI:
            responseText = try await OpenAIClient.shared.generateResponse(
                messages: messages
            )
        case .local:
            responseText = try await LocalLLMRunner.shared.generateResponse(
                messages: messages
            )
        }
        
        return self.parseResponseForAction(responseText)
    }
    
    
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
        1. You will be given a numbered list of context chunks.
        2. Answer the user's query *only* using this context.
        3. **You MUST cite your sources.** At the end of any sentence
           or paragraph that uses information from a chunk, add the
           corresponding number tag, like `[1]` or `[1, 2]`.
        4. If the context has no relevant information, say so clearly.

        \(actionsPrompt)
        """
    }
    
    // --- THIS IS THE FIX ---
    // This new function uses a Regular Expression (Regex) to reliably
    // find and extract the action tag, no matter the format.
    private func parseResponseForAction(_ text: String) -> (content: String, action: String?) {
        // This regex looks for a tag at the *very end* of the string.
        // It matches [ACTION: TAG_NAME] or [TAG_NAME]
        // (?:\s*\[(?:ACTION: )?([A-Z_]+)\]\s*$)
        let pattern = #"(?:\s*\[(?:ACTION: )?([A-Z_]+)\]\s*)$"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return (content: text, action: nil)
        }
        
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        
        // Check if we find a match
        if let match = regex.firstMatch(in: text, options: [], range: range) {
            
            // Get the full range of the *entire tag* (e.g., "[ACTION: DRAFT_EMAIL]")
            let fullTagRange = match.range(at: 0)
            
            // Get the range of *just the action* (e.g., "DRAFT_EMAIL")
            let actionNameRange = match.range(at: 1)

            if let fullTagSwiftRange = Range(fullTagRange, in: text),
               let actionNameSwiftRange = Range(actionNameRange, in: text) {
                
                // Extract the clean content (everything *before* the tag)
                let cleanContent = String(text[..<fullTagSwiftRange.lowerBound])
                                   .trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Extract the clean action name
                let cleanAction = String(text[actionNameSwiftRange])
                
                return (content: cleanContent, action: cleanAction)
            }
        }
        
        // No tag was found, return the original text
        return (content: text.trimmingCharacters(in: .whitespacesAndNewlines), action: nil)
    }
    // --- END OF FIX ---
}
