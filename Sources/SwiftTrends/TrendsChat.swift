import SwiftUI
import UIKit
import UnionChat

@Observable
final class ChatState {
    var messages: [TrendsMessage] = []
    var isTyping = false
    var conversationId: String?
    var responseId: String?
}

public struct TrendsChat: View {
    private let backend: TrendsBackend
    @State private var state = ChatState()

    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "App"
    }

    private var appIcon: Image? {
        guard let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primaryIconsDictionary = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIconsDictionary["CFBundleIconFiles"] as? [String],
              let lastIcon = iconFiles.last,
              let uiImage = UIImage(named: lastIcon) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }

    public init(apiKey: String) {
        self.backend = TrendsBackend(apiKey: apiKey)
    }

    public var body: some View {
        let _ = print("[TrendsChat] body called, messages.count = \(state.messages.count)")
        Chat(state.messages, typingUsers: state.isTyping ? [.user(id: "trends-typing", displayName: "Trends")] : []) { msg in
            Message(msg.text, role: msg.role, timestamp: msg.timestamp)
        }
        .chatHeader {
            ChatHeader(title: "\(appName) Trends", avatar: appIcon)
        }
        .chatInputPlaceholder("Ask about your data...")
        .onChatSend { text, _ in
            guard let text else { return }
            await sendMessage(text)
        }
        .task {
            await sendMessage("How's the app doing? Any interesting trends or things I should know about?")
        }
    }

    private func sendMessage(_ text: String) async {
        print("[TrendsChat] sendMessage called: \(text.prefix(50))")
        let userMessage = TrendsMessage(text: text, role: .me)
        print("[TrendsChat] User message id=\(userMessage.id)")

        state.messages.append(userMessage)
        state.isTyping = true
        print("[TrendsChat] isTyping = true")

        do {
            print("[TrendsChat] Calling backend.send...")
            let response = try await backend.send(
                text,
                conversationId: state.conversationId,
                responseId: state.responseId,
                onTyping: nil,
                onMessage: { [state] messageText, isFinal in
                    print("[TrendsChat] onMessage (final=\(isFinal)): \(messageText.prefix(30))")
                    await MainActor.run {
                        let role = ChatRole.user(id: "assistant", displayName: "Trends")
                        state.messages.append(TrendsMessage(text: messageText, role: role))
                        print("[TrendsChat] Updated, count=\(state.messages.count)")
                    }
                }
            )
            print("[TrendsChat] backend.send returned")
            state.isTyping = false
            state.conversationId = response.conversationId
            state.responseId = response.responseId
            print("[TrendsChat] Updated state")
        } catch {
            print("[TrendsChat] ERROR: \(error)")
            state.isTyping = false
            state.messages.append(TrendsMessage(
                text: "Error: \(error.localizedDescription)",
                role: .user(id: "assistant", displayName: "Trends")
            ))
        }
    }
}
