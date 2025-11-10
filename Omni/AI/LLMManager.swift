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
    
    // MARK: - System Prompts
    
    private let generalSystemPrompt = """
    You are a helpful general-purpose AI assistant named Omni.
    Answer the user's question clearly and concisely.
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
    
    // MARK: - Public API
    
    /// Generates a standard chat response, now returning a simple String.
    func generateResponse(chatHistory: [ChatMessage], context: String, files: [URL]) async throws -> String {
        
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
        
        return responseText.trimmingCharacters(in: .whitespacesAndNewlines)
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
        
        return responseText
    }
    
    /// Generates a full notebook summary from a chat history.
    func generateNotebook(chatHistory: [ChatMessage], files: [URL]) async throws -> String {
        
        var messages: [OpenAIMessage] = []
        
        messages.append(OpenAIMessage(role: "system", content: notebookSystemPrompt))
        
        var fullHistory = "Here is the chat history to summarize:\n\n"
        for message in chatHistory {
            if message.content.contains("Hi! I'm Omni") && chatHistory.count == 1 {
                continue
            }
            let role = message.isUser ? "[User]" : "[Assistant]"
            fullHistory += "\(role)\n\(message.content)\n\n"
        }
        messages.append(OpenAIMessage(role: "user", content: fullHistory))

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
        
        return responseText
    }
    
    // MARK: - Private Helpers
    
    private func generateSmartPrompt(for files: [URL]) -> String {
        // This function is now much simpler.
        // It no longer needs to generate an 'actionsPrompt'.
        
        return """
        You are a File System Analyst AI assistant.
        
        CRITICAL RULES:
        1. Answer questions ONLY based on the file content provided in the context.
        2. ALWAYS cite the source file name (e.g., "According to 'Resume.pdf'...").
        3. If the context has no relevant information, say so clearly.
        4. **SYNTHESIS:** If you combine information from *more than one file* to form an answer, you MUST state this.
           Example: "By combining information from 'Report-A.pdf' and 'Sales-Data.csv', I can see that..."
        """
    }
    
    // --- 🛑 REMOVED 'parseResponseForAction' function 🛑 ---
}
