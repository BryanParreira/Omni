import SwiftUI

// --- 1. NEW HELPER STRUCT ---
// This struct will hold the pieces of our parsed message
private struct ParsedTextComponent: Identifiable {
    let id = UUID()
    let string: String
    let isCitation: Bool
}

struct MessageBubbleView: View {
    let message: ChatMessage
    
    @EnvironmentObject var viewModel: ContentViewModel
    
    @State private var isHovered = false
    
    // --- 2. NEW PARSING FUNCTION ---
    /// This function splits the AI's response into normal text and citation tags.
    /// "Hello [1]" -> [ ("Hello ", false), ("[1]", true) ]
    private func parseCitations(from content: String) -> [ParsedTextComponent] {
        var components: [ParsedTextComponent] = []
        
        // This regex looks for tags like [1] or [1, 2]
        let pattern = #"\[([\d, ]+)\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            // If regex fails, just return the whole string as non-citation
            return [ParsedTextComponent(string: content, isCitation: false)]
        }
        
        let range = NSRange(content.startIndex..<content.endIndex, in: content)
        var lastEnd: String.Index = content.startIndex

        regex.enumerateMatches(in: content, options: [], range: range) { match, _, _ in
            guard let match = match, let matchRange = Range(match.range, in: content) else { return }
            
            // Add the text *before* the citation
            let textBefore = String(content[lastEnd..<matchRange.lowerBound])
            if !textBefore.isEmpty {
                components.append(ParsedTextComponent(string: textBefore, isCitation: false))
            }
            
            // Add the citation *itself*
            let citationText = String(content[matchRange])
            components.append(ParsedTextComponent(string: citationText, isCitation: true))
            
            lastEnd = matchRange.upperBound
        }
        
        // Add any remaining text *after* the last citation
        let textAfter = String(content[lastEnd..<content.endIndex])
        if !textAfter.isEmpty {
            components.append(ParsedTextComponent(string: textAfter, isCitation: false))
        }
        
        // If no matches were found, return the whole string
        if components.isEmpty {
            return [ParsedTextComponent(string: content, isCitation: false)]
        }
        
        return components
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.isUser {
                Spacer(minLength: 100)
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                
                // --- 3. REPLACED 'Text(message.content)' ---
                // We now dynamically build the text to style citations
                let components = parseCitations(from: message.content)
                
                // We use .reduce() to combine all our Text pieces into one
                // This is the only way to make text wrap correctly.
                components.reduce(Text(""), { (result, component) in
                    let textChunk = Text(component.string)
                        // Style citations differently!
                        .font(.system(size: 14, weight: component.isCitation ? .bold : .regular))
                        .foregroundColor(component.isCitation ? Color(hex: "FF8E53") : Color(hex: "EAEAEA"))
                    
                    return result + textChunk
                })
                .lineSpacing(4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 10).fill(message.isUser ? Color(hex: "2A2A2A") : Color(hex: "242424")))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(message.isUser ? Color.clear : Color(hex: "2F2F2F"), lineWidth: 1))
                .textSelection(.enabled) // Allow user to select text
                
                // --- END OF REPLACEMENT ---
                
                if let sources = message.sources, !sources.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 9))
                            Text("Sources")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "8A8A8a"))
                        
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
