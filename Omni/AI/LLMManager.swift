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
    
    private let defaultSystemPrompt = """
    You are a helpful File System Analyst AI assistant.
    Answer questions ONLY based on the file content provided.
    If the context doesn't contain relevant information, say so clearly.
    """
    
    // This is the function signature that was causing the error in ContentViewModel
    // It now correctly accepts the 'files' array.
    func generateResponse(query: String, context: String, files: [URL]) async throws -> (content: String, action: String?) {
        
        let responseText: String
        
        // This function creates a new prompt based on the file types
        let smartPrompt = generateSmartPrompt(for: files)
        
        switch currentMode {
        case .openAI:
            responseText = try await OpenAIClient.shared.generateResponse(
                query: query,
                context: context,
                systemPrompt: smartPrompt // Pass in the new smart prompt
            )
        case .local:
            responseText = try await LocalLLMRunner.shared.generateResponse(
                query: query,
                context: context,
                systemPrompt: smartPrompt // Pass in the new smart prompt
            )
        }
        
        // --- FIX: Added 'self.' to fix the "Cannot find in scope" error ---
        return self.parseResponseForAction(responseText)
    }
    
    private func generateSmartPrompt(for files: [URL]) -> String {
        guard !files.isEmpty else {
            return defaultSystemPrompt // Use the fallback if no files
        }
        
        var fileTypes = Set<String>()
        for file in files {
            fileTypes.insert(file.pathExtension.lowercased())
        }
        
        // This prompt is much more specific about the action format
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
        
        // Fallback action
        actionsPrompt += "\n- For a generic request, you can suggest 'DRAFT_EMAIL'."
        actionsPrompt += "\n- Example ending: [ACTION: EXPLAIN_CODE]"

        // Combine all parts into the final prompt
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
        // --- THIS IS THE FIX for the parsing bug ---
        // We will try two formats: [ACTION: TAG] and [TAG]
        
        // 1. Try to find the format [ACTION: TAG]
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
        
        // 2. Try to find the format [TAG] (like your screenshot)
        if let range = text.range(of: "[", options: .backwards), let endRange = text.range(of: "]", options: .backwards), range.lowerBound < endRange.lowerBound {
            
            let tag = text[range.upperBound..<endRange.lowerBound]
            
            // Check if the tag is a valid, single-word action
            // This avoids parsing "summarize this [document]" as an action
            let potentialAction = String(tag).trimmingCharacters(in: .whitespacesAndNewlines)
            if potentialAction.allSatisfy({ $0.isUppercase || $0 == "_" }) {
                let cleanContent = text[..<range.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
                return (content: cleanContent, action: potentialAction)
            }
        }
        // --- END OF FIX ---
        
        // No action found, return the full text
        return (content: text.trimmingCharacters(in: .whitespacesAndNewlines), action: nil)
    }
} // <-- This was the missing brace that caused the compile error
