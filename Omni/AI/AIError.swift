import Foundation

// We make the error conform to LocalizedError
// This lets us provide clean, user-facing descriptions.
enum AIError: Error, LocalizedError {
    
    // --- THIS IS THE NEW CASE YOU NEEDED ---
    /// The API key is missing, malformed, or invalid.
    case invalidAPIKey
    
    /// The AI service (OpenAI, Anthropic) returned a specific error.
    case apiError(String)
    
    /// The AI service sent back data we couldn't understand (e.g., malformed JSON).
    case invalidResponse
    
    /// A networking issue, like no internet or the server is down.
    case networkError(Error)
    
    /// A generic, unexpected error.
    case unknownError(String)

    /// This computed property provides a professional, user-friendly message for each error case.
    public var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API Key. Please check your API key in Settings and try again."
            
        case .apiError(let message):
            // This is a specific error from the AI provider
            return "An API error occurred: \(message)"
            
        case .invalidResponse:
            // This means the AI sent back garbage data
            return "The AI returned an invalid or empty response. This might be a temporary service issue. Please try again."
            
        case .networkError(let underlyingError):
            // This is a connection error
            return "Network Error: Could not connect to the AI service. Please check your internet connection.\n\n`\(underlyingError.localizedDescription)`"
            
        case .unknownError(let message):
            return "An unexpected error occurred: \(message)"
        }
    }
}
