import SwiftUI
import UnionChat

public struct TrendsChat: View {
    private let client: TrendsClient
    @State private var messages: [TrendsMessage] = []
    @State private var isTyping = false

    public init(apiKey: String, systemPrompt: String? = nil) {
        self.client = TrendsClient(apiKey: apiKey, systemPrompt: systemPrompt)
    }

    public var body: some View {
        Chat(messages, typingUsers: isTyping ? [.user(id: "assistant", displayName: "Trends")] : []) { msg in
            Message(msg.text, role: msg.role, timestamp: msg.timestamp)
        }
        .chatInputPlaceholder("Ask about your trends...")
        .onChatSend { text, _ in
            guard let text else { return }
            let userMessage = TrendsMessage(text: text, role: .me)
            await MainActor.run { messages.append(userMessage) }

            await MainActor.run { isTyping = true }
            do {
                let response = try await client.send(text)
                let assistantMessage = TrendsMessage(
                    text: response,
                    role: .user(id: "assistant", displayName: "Trends")
                )
                await MainActor.run {
                    isTyping = false
                    messages.append(assistantMessage)
                }
            } catch {
                await MainActor.run {
                    isTyping = false
                    messages.append(TrendsMessage(
                        text: "Something went wrong. Please try again.",
                        role: .user(id: "assistant", displayName: "Trends")
                    ))
                }
            }
        }
    }
}
