import Foundation

// MARK: - Ollama Codable Structs
private struct OllamaGenerateRequest: Codable {
    let model: String
    let prompt: String
    let stream: Bool = false
}

private struct OllamaGenerateResponse: Codable {
    let response: String
}

// These structs were declared in the old LocalLLMService and were conflicting.
// They now live here.
private struct OllamaTagsResponse: Codable {
    let models: [OllamaModel]
}

struct OllamaModel: Codable, Identifiable {
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

    func generateResponse(query: String, context: String, systemPrompt: String) async throws -> String {
        
        let fullPrompt = """
        \(systemPrompt)
        
        File Context:
        \(context)
        
        User Query:
        \(query)
        """
        
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
