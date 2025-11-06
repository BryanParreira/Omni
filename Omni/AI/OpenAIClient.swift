import Foundation

// MARK: - OpenAI Codable Structs

// 1. We make these 'internal' (by removing 'private') so LLMManager can see them
struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

// (The response structs can stay private)
private struct OpenAIResponse: Codable {
    let choices: [Choice]
    struct Choice: Codable {
        let message: OpenAIMessage
    }
}

// MARK: - OpenAI Client
class OpenAIClient {
    static let shared = OpenAIClient()
    private init() {}

    private let openAIURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    
    private var apiKey: String {
        UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
    }
    
    private var selectedModel: String {
        UserDefaults.standard.string(forKey: "selected_model") ?? "gpt-4o-mini"
    }
    
    // --- 2. THIS IS THE FIX ---
    // We update the function signature to accept the 'messages' array
    // This matches what LLMManager is now sending.
    func generateResponse(messages: [OpenAIMessage]) async throws -> String {
    // --- END OF FIX ---
        
        guard !apiKey.isEmpty else {
            throw AIError.invalidAPIKey
        }
        
        // --- 3. THE OLD LOGIC IS REMOVED ---
        // We no longer build the 'messages' array here.
        // It's now passed in directly.
        
        let requestBody = OpenAIRequest(model: selectedModel, messages: messages)
        
        var request = URLRequest(url: openAIURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AIError.networkError(error)
        }

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw AIError.networkError(NSError(domain: "OpenAIError", code: 500))
        }
        
        do {
            let aiResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            return aiResponse.choices.first?.message.content ?? "No response from AI."
        } catch {
            throw AIError.invalidResponse
        }
    }
}
