import SwiftUI

/// A simple 3-dot loading animation.
struct LoadingIndicatorView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color(hex: "8A8A8A"))
                            .frame(width: 6, height: 6)
                            .scaleEffect(isAnimating ? 1.0 : 0.5)
                            .opacity(isAnimating ? 1.0 : 0.5)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                value: isAnimating
                            )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: "242424")).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "2F2F2F"), lineWidth: 1)))
            }
            Spacer(minLength: 100)
        }
        .onAppear { isAnimating = true }
    }
}
