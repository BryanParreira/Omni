import Foundation

// MARK: - OpenAI Codable Structs
private struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
}

private struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

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
    
    func generateResponse(query: String, context: String, systemPrompt: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw AIError.invalidAPIKey
        }
        
        let messages = [
            OpenAIMessage(role: "system", content: systemPrompt),
            OpenAIMessage(role: "user", content: "File Context:\n\(context)"),
            OpenAIMessage(role: "user", content: "User Query:\n\(query)")
        ]
        
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
