import SwiftUI

struct TrendsOverlayModifier: ViewModifier {
    let apiKey: String
    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            .modifier(ShakeDetectorModifier {
                isPresented = true
            })
            .fullScreenCover(isPresented: $isPresented) {
                TrendsChat(apiKey: apiKey)
                    .ignoresSafeArea(edges: .bottom)
                    .safeAreaInset(edge: .top) {
                        HStack {
                            Button {
                                isPresented = false
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.primary)
                                    .padding(12)
                                    .contentShape(Circle())
                                    .glassEffect(.regular.interactive(), in: .circle)
                            }
                            .buttonStyle(.plain)

                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
            }
    }
}

public extension View {
    @ViewBuilder
    func trendsChat(apiKey: String) -> some View {
        #if DEBUG
        modifier(TrendsOverlayModifier(apiKey: apiKey))
        #else
        self
        #endif
    }
}
