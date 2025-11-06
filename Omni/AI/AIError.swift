import Foundation

enum AIError: Error {
    case invalidAPIKey
    case networkError(Error)
    case invalidResponse
}
