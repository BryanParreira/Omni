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
        
        return parseResponseForAction(responseText)
    }
    
    private func parseResponseForAction(_ text: String) -> (content: String, action: String?) {
        // Look for a tag like [ACTION: DRAFT_EMAIL]
        if let range = text.range(of: "[ACTION:", options: .backwards) {
            let tagPart = text[range.lowerBound...]
            if let endRange = tagPart.range(of: "]") {
                let actionTag = tagPart[range.upperBound..<endRange.lowerBound]
                let cleanContent = text[..<range.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
                
                // --- THIS IS THE FIX ---
                // We trim whitespace and newlines from the action tag,
                // just in case the LLM adds extra spaces.
                let cleanAction = String(actionTag).trimmingCharacters(in: .whitespacesAndNewlines)
                
                // If the tag was just whitespace, count it as no action
                if cleanAction.isEmpty {
                    return (content: cleanContent, action: nil)
                }
                
                return (content: cleanContent, action: cleanAction)
                // --- END OF FIX ---
            }
        }
        
        // No action found, return the full text
        return (content: text, action: nil)
    }
}
