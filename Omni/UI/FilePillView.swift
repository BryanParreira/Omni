import SwiftUI

/// A "pill" view that shows an attached file's name and an "x" to remove it.
struct FilePillView: View {
    let url: URL
    let onRemove: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "AAAAAA"))
            
            Text(url.lastPathComponent)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "EAEAEA"))
                .lineLimit(1)
                .frame(maxWidth: 150)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isHovered ? Color(hex: "EAEAEA") : Color(hex: "8A8A8A"))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color(hex: "3A3A3A") : Color(hex: "2A2A2A"))
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
    }
}
