import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage
    
    // NEW: This view now needs the ViewModel to perform actions
    @EnvironmentObject var viewModel: ContentViewModel
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.isUser {
                Spacer(minLength: 100)
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                Text(message.content)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "EAEAEA"))
                    .lineSpacing(4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(message.isUser ? Color(hex: "2A2A2A") : Color(hex: "242424")))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(message.isUser ? Color.clear : Color(hex: "2F2F2F"), lineWidth: 1))
                
                if let sources = message.sources, !sources.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 9))
                            Text("Sources")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "8A8A8A"))
                        
                        ForEach(sources, id: \.self) { sourcePath in
                            Button(action: {
                                NSWorkspace.shared.open(URL(fileURLWithPath: sourcePath))
                            }) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color(hex: "FF6B6B"))
                                        .frame(width: 4, height: 4)
                                    Text(URL(fileURLWithPath: sourcePath).lastPathComponent)
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(hex: "AAAAAA"))
                                        .lineLimit(1)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color(hex: "1E1E1E")))
                }
            }
            .frame(maxWidth: 480, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser {
                Spacer(minLength: 100)
            }
        }
    }
}
