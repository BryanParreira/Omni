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
        // TODO: Add cases for Anthropic and Gemini
        return .local
    }
    
    // NEW: Updated system prompt to ask for actions
    private let systemPrompt = """
    You are a File System Analyst AI assistant.
    
    CRITICAL RULES:
    1. Answer questions ONLY based on the file content provided in the context.
    2. ALWAYS cite the source file name (e.g., "According to Finance Q3.xlsx...").
    3. If the context doesn't contain relevant information, say so clearly.
    
    ACTIONS:
    - If you provide a summary of text, suggest a "DRAFT_EMAIL" action.
    - End your response with the action tag, like this: [ACTION: DRAFT_EMAIL]
    - Only suggest one action.
    """
    
    // NEW: Return type now includes an optional action
    func generateResponse(query: String, context: String) async throws -> (content: String, action: String?) {
        
        let responseText: String
        
        switch currentMode {
        case .openAI:
            responseText = try await OpenAIClient.shared.generateResponse(
                query: query,
                context: context,
                systemPrompt: systemPrompt
            )
        case .local:
            responseText = try await LocalLLMRunner.shared.generateResponse(
                query: query,
                context: context,
                systemPrompt: systemPrompt
            )
        }
        
        // NEW: Parse the response
        return parseResponseForAction(responseText)
    }
    
    // NEW: Helper function to find and strip the action tag
    private func parseResponseForAction(_ text: String) -> (content: String, action: String?) {
        // Look for a tag like [ACTION: DRAFT_EMAIL]
        if let range = text.range(of: "[ACTION:", options: .backwards) {
            let tagPart = text[range.lowerBound...]
            if let endRange = tagPart.range(of: "]") {
                let actionTag = tagPart[range.upperBound..<endRange.lowerBound]
                let cleanContent = text[..<range.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
                return (content: cleanContent, action: String(actionTag))
            }
        }
        
        // No action found, return the full text
        return (content: text, action: nil)
    }
}
