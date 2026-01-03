import Foundation

class OpenAIService {
    static let shared = OpenAIService()
    
    private var apiKey: String {
        UserDefaults.standard.string(forKey: "openAIKey") ?? ""
    }
    
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    struct ChatMessage: Codable {
        let role: String
        let content: String
    }
    
    struct ChatRequest: Codable {
        let model: String
        let messages: [ChatMessage]
        let temperature: Double
        let response_format: ResponseFormat?
    }
    
    struct ResponseFormat: Codable {
        let type: String
    }
    
    struct ChatResponse: Codable {
        let choices: [Choice]
    }
    
    struct Choice: Codable {
        let message: ChatMessage
    }
    
    enum OpenAIError: LocalizedError {
        case noAPIKey
        case invalidURL
        case invalidResponse
        case httpError(statusCode: Int, message: String)
        case networkError(Error)
        case decodingError(Error)

        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "Please set your OpenAI API key in Settings"
            case .invalidURL:
                return "Invalid API URL configuration"
            case .invalidResponse:
                return "Invalid response from OpenAI"
            case .httpError(let statusCode, let message):
                return "API error (\(statusCode)): \(message)"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .decodingError(let error):
                return "Decoding error: \(error.localizedDescription)"
            }
        }
    }

    struct APIErrorResponse: Codable {
        let error: APIError?

        struct APIError: Codable {
            let message: String
            let type: String?
            let code: String?
        }
    }
    
    func chat(systemPrompt: String, userMessage: String, jsonMode: Bool = false) async throws -> String {
        guard !apiKey.isEmpty else {
            throw OpenAIError.noAPIKey
        }

        guard let url = URL(string: baseURL) else {
            throw OpenAIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let messages = [
            ChatMessage(role: "system", content: systemPrompt),
            ChatMessage(role: "user", content: userMessage)
        ]

        let chatRequest = ChatRequest(
            model: "gpt-4o-mini",
            messages: messages,
            temperature: 0.7,
            response_format: jsonMode ? ResponseFormat(type: "json_object") : nil
        )

        request.httpBody = try JSONEncoder().encode(chatRequest)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenAIError.invalidResponse
            }

            // Handle non-success HTTP status codes
            if !(200...299).contains(httpResponse.statusCode) {
                let errorMessage: String
                if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data),
                   let message = apiError.error?.message {
                    errorMessage = message
                } else {
                    errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                }
                throw OpenAIError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
            }

            let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)

            guard let content = chatResponse.choices.first?.message.content else {
                throw OpenAIError.invalidResponse
            }

            return content
        } catch let error as OpenAIError {
            throw error
        } catch let error as DecodingError {
            throw OpenAIError.decodingError(error)
        } catch {
            throw OpenAIError.networkError(error)
        }
    }
}
