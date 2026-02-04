import Foundation

public struct TrendsBackend: Sendable {
    private let apiKey: String
    private let endpoint = URL(string: "https://swift-trends-server-67c54feffa03.herokuapp.com/chat")!

    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    public func send(
        _ message: String,
        conversationId: String?,
        responseId: String?,
        onTyping: (@Sendable (Bool) -> Void)? = nil,
        onMessage: (@Sendable (String, Bool) async -> Void)? = nil
    ) async throws -> TrendsResponse {
        print("[Trends] Starting request...")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        var body: [String: Any] = ["message": message]
        if let conversationId { body["conversation_id"] = conversationId }
        if let responseId { body["previous_response_id"] = responseId }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        request.timeoutInterval = 120

        print("[Trends] Sending request to server...")
        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("[Trends] ERROR: Not an HTTP response")
            throw TrendsError.serverError(message: "Request failed")
        }
        print("[Trends] Got response: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            print("[Trends] ERROR: Bad status code \(httpResponse.statusCode)")
            throw TrendsError.serverError(message: "Request failed")
        }

        var allMessages: [String] = []
        var finalConversationId: String?
        var finalResponseId: String?

        print("[Trends] Starting to read stream...")
        for try await line in bytes.lines {
            print("[Trends] Got line: \(line.prefix(100))")
            guard line.hasPrefix("data: ") else { continue }
            let jsonString = String(line.dropFirst(6))
            guard let data = jsonString.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("[Trends] Failed to parse JSON")
                continue
            }

            if let error = json["error"] as? String {
                print("[Trends] ERROR from server: \(error)")
                onTyping?(false)
                throw TrendsError.serverError(message: error)
            }

            if let status = json["status"] as? String {
                print("[Trends] Status: \(status)")
                if let convId = json["conversation_id"] as? String {
                    finalConversationId = convId
                }
                if status == "done" {
                    print("[Trends] Got done, breaking")
                    onTyping?(false)
                    break
                } else if status == "typing", let typing = json["typing"] as? Bool {
                    print("[Trends] Typing: \(typing)")
                    onTyping?(typing)
                } else if status == "message", let text = json["text"] as? String {
                    let isFinal = json["final"] as? Bool ?? false
                    print("[Trends] Message (final=\(isFinal)): \(text)")
                    allMessages.append(text)
                    if isFinal {
                        onTyping?(false)
                        finalResponseId = json["response_id"] as? String
                    }
                    await onMessage?(text, isFinal)
                }
            }
        }

        print("[Trends] Stream ended, collected \(allMessages.count) messages")
        onTyping?(false)

        guard let conversationId = finalConversationId else {
            print("[Trends] ERROR: No conversation ID received")
            throw TrendsError.invalidResponse
        }

        print("[Trends] Request complete, returning response")
        return TrendsResponse(messages: allMessages, conversationId: conversationId, responseId: finalResponseId)
    }
}

public struct TrendsResponse: Sendable {
    public let messages: [String]
    public let conversationId: String
    public let responseId: String?
}

public enum TrendsError: Error, LocalizedError {
    case invalidResponse
    case serverError(message: String)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let message):
            return message
        }
    }
}
