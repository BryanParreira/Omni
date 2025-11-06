import Foundation

// MARK: - Ollama Codable Structs

// This request struct is correct. Ollama's /api/generate endpoint
// takes a single "prompt" string, not a message array.
private struct OllamaGenerateRequest: Encodable {
    let model: String
    let prompt: String
    let stream: Bool = false
}

private struct OllamaGenerateResponse: Decodable {
    let response: String
}

private struct OllamaTagsResponse: Decodable {
    let models: [OllamaModel]
}

struct OllamaModel: Decodable, Identifiable {
    let name: String
    var id: String { name }
}


// MARK: - Local LLM Runner
class LocalLLMRunner {
    static let shared = LocalLLMRunner()
    private init() {}
    
    private let ollamaURL = URL(string: "http://localhost:11434/")!
    
    private var selectedModel: String {
        UserDefaults.standard.string(forKey: "selected_model") ?? "llama-3-8b-instruct"
    }

    // --- 1. THIS IS THE FIX ---
    // We update the function signature to accept the 'messages' array
    // This matches what LLMManager is now sending.
    func generateResponse(messages: [OpenAIMessage]) async throws -> String {
    // --- END OF FIX ---
        
        // --- 2. NEW LOGIC ---
        // We must convert the 'messages' array back into a
        // single 'fullPrompt' string, because Ollama's /api/generate
        // endpoint (unlike OpenAI's) expects a single prompt.
        
        // We'll build the prompt, ignoring roles (Ollama's simple
        // models work best this way).
        let fullPrompt = messages.map { $0.content }.joined(separator: "\n\n")
        // --- END OF NEW LOGIC ---
        
        let requestBody = OllamaGenerateRequest(model: selectedModel, prompt: fullPrompt)
        
        let url = ollamaURL.appendingPathComponent("api/generate")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            print("Ollama connection error: \(error)")
            throw AIError.networkError(error)
        }
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Ollama returned non-200 status")
            throw AIError.networkError(NSError(domain: "OllamaError", code: 500))
        }
        
        do {
            let ollamaResponse = try JSONDecoder().decode(OllamaGenerateResponse.self, from: data)
            return ollamaResponse.response
        } catch {
            print("Ollama decoding error: \(error)")
            throw AIError.invalidResponse
        }
    }
    
    // Function to fetch installed models
    func fetchInstalledModels() async throws -> [OllamaModel] {
        // ... (this function is unchanged) ...
        let url = ollamaURL.appendingPathComponent("api/tags")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AIError.networkError(error)
        }
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw AIError.networkError(NSError(domain: "OllamaTagsError", code: 500))
        }
        
        do {
            let tagsResponse = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
            return tagsResponse.models
        } catch {
            throw AIError.invalidResponse
        }
    }
}
