import SwiftUI

struct TrendsOverlayModifier: ViewModifier {
    let apiKey: String
    let systemPrompt: String?
    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            .modifier(ShakeDetectorModifier {
                isPresented = true
            })
            .fullScreenCover(isPresented: $isPresented) {
                NavigationStack {
                    TrendsChat(apiKey: apiKey, systemPrompt: systemPrompt)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    isPresented = false
                                }
                            }
                        }
                }
            }
    }
}

public extension View {
    @ViewBuilder
    func trendsChat(apiKey: String, systemPrompt: String? = nil) -> some View {
        #if DEBUG
        modifier(TrendsOverlayModifier(apiKey: apiKey, systemPrompt: systemPrompt))
        #else
        self
        #endif
    }
}
