import Foundation

enum CoinGeckoError: LocalizedError {
    case invalidURL
    case decodingError(String)
    case networkError(String)
    case serverError(Int, String)
    case unauthorized
    case rateLimited
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .decodingError(let message):
            return "Data decoding error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .unauthorized:
            return "Invalid API key or unauthorized access"
        case .rateLimited:
            return "API request limit exceeded"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
} 