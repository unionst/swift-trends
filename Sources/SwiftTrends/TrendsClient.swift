import Foundation

actor TrendsClient {
    private let apiKey: String
    private let systemPrompt: String
    private var conversationHistory: [[String: String]] = []

    init(apiKey: String, systemPrompt: String? = nil) {
        self.apiKey = apiKey
        self.systemPrompt = systemPrompt ?? """
            You are a helpful assistant that analyzes app trends and metrics. \
            You help developers understand their app's performance, downloads, revenue, \
            ratings, and market trends. Be concise and actionable in your responses.
            """
    }

    func send(_ message: String) async throws -> String {
        conversationHistory.append(["role": "user", "content": message])

        var messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt]
        ]
        messages.append(contentsOf: conversationHistory)

        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages
        ]

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let responseMessage = choices?.first?["message"] as? [String: String]
        let content = responseMessage?["content"] ?? "Sorry, I couldn't process that."

        conversationHistory.append(["role": "assistant", "content": content])
        return content
    }

    func reset() {
        conversationHistory = []
    }
}
