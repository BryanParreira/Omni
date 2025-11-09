import Foundation

enum LLMMode {
    case openAI
    case local
}

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
    
    private let overviewSystemPrompt = """
    You are an expert document analyst. You will be given the first few chunks of a document.
    Your task is to generate a concise summary, 3-4 key topics, and 3 suggested questions.
    You MUST respond in this exact format, with no other text:
    
    Summary: [Your 1-2 sentence summary]
    Key Topics:
    - [Topic 1]
    - [Topic 2]
    - [Topic 3]
    Suggested Questions:
    1. [Suggested Question 1]
    2. [Suggested Question 2]
    3. [Suggested Question 3]
    """

    // --- 🛑 NEW NOTEBOOK PROMPT 🛑 ---
    private let notebookSystemPrompt = """
    You are a professional research assistant. Your task is to synthesize a chat discussion into a clean, structured notebook entry.
    The user will provide the full chat history.
    Analyze the entire conversation and generate a comprehensive summary in Markdown format.
    The summary should include:
    1. A concise overview of the main topic.
    2. Key insights or conclusions reached.
    3. A list of important bullet points, facts, or data mentioned.

    Respond ONLY with the Markdown-formatted note. Do not add any conversational text.
    """
    // --- 🛑 END OF NEW PROMPT 🛑 ---

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
    
    /// Generates a summary overview for a new file.
    func generateOverview(chunks: [String], fileName: String) async throws -> String {
        
        let context = "CONTEXT FROM '\(fileName)':\n" + chunks.joined(separator: "\n---\n")
        let messages = [
            OpenAIMessage(role: "system", content: overviewSystemPrompt),
            OpenAIMessage(role: "user", content: context)
        ]
        
        let responseText: String
        switch currentMode {
        case .openAI:
            responseText = try await OpenAIClient.shared.generateResponse(messages: messages)
        case .local:
            responseText = try await LocalLLMRunner.shared.generateResponse(messages: messages)
        }
        
        // The overview response doesn't have an "action"
        return responseText
    }
    
    // --- 🛑 NEW NOTEBOOK FUNCTION 🛑 ---
    func generateNotebook(chatHistory: [ChatMessage], files: [URL]) async throws -> String {
        
        var messages: [OpenAIMessage] = []
        
        // 1. Add the new system prompt
        messages.append(OpenAIMessage(role: "system", content: notebookSystemPrompt))
        
        // 2. Add the full chat history (excluding the first welcome message)
        // We'll format it slightly to make it clearer to the AI
        var fullHistory = "Here is the chat history to summarize:\n\n"
        for message in chatHistory {
            if message.content.contains("Hi! I'm Omni") && chatHistory.count == 1 {
                continue
            }
            let role = message.isUser ? "[User]" : "[Assistant]"
            fullHistory += "\(role)\n\(message.content)\n\n"
        }
        messages.append(OpenAIMessage(role: "user", content: fullHistory))

        // 3. Generate the response
        let responseText: String
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
        
        // 4. Return the raw text
        return responseText
    }
    // --- 🛑 END OF NEW FUNCTION 🛑 ---
    
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
        3. If the context has no relevant information, say so clearly.

        \(actionsPrompt)
        """
    }
    
    private func parseResponseForAction(_ text: String) -> (content: String, action: String?) {
        let pattern = #"(?:\s*\[(?:ACTION: )?([A-Z_]+)\]\s*)$"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return (content: text, action: nil)
        }
        
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        
        if let match = regex.firstMatch(in: text, options: [], range: range) {
            
            let fullTagRange = match.range(at: 0)
            let actionNameRange = match.range(at: 1)

            if let fullTagSwiftRange = Range(fullTagRange, in: text),
               let actionNameSwiftRange = Range(actionNameRange, in: text) {
                
                let cleanContent = String(text[..<fullTagSwiftRange.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                let cleanAction = String(text[actionNameSwiftRange])
                
                return (content: cleanContent, action: cleanAction)
            }
        }
        
        return (content: text.trimmingCharacters(in: .whitespacesAndNewlines), action: nil)
    }
}
