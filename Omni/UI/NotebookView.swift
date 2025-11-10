import SwiftUI
import UniformTypeIdentifiers

// --- 🛑 We need the Primary Button Style from SetupView 🛑 ---
// (You can move this to a shared "Helpers" file if you want)
private let brandGradient = LinearGradient(
    colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

private struct PrimaryButtonStyle: ButtonStyle {
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold)) // Slightly smaller for a header
            .foregroundColor(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(brandGradient)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(isDisabled ? 0.5 : (configuration.isPressed ? 0.9 : 1.0))
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    var isDisabled: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(Color(hex: "EAEAEA"))
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(Color(hex: "3A3A3A")) // Neutral gray
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(isDisabled ? 0.5 : (configuration.isPressed ? 0.9 : 1.0))
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}


struct NotebookView: View {
    @Binding var noteContent: String
    @Binding var isShowing: Bool
    
    @State private var didCopy = false // For "Copy" button animation
    
    var body: some View {
        VStack(spacing: 0) {
            
            // --- 1. IMPROVED HEADER ---
            HStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.title2)
                    .foregroundStyle(brandGradient)
                
                Text("Generated Notebook")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "EAEAEA"))
                
                Spacer()
                
                // --- 2. NEW "COPY" BUTTON ---
                Button(action: copyToClipboard) {
                    Label(didCopy ? "Copied!" : "Copy All", systemImage: didCopy ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(SecondaryButtonStyle())
                .animation(.easeInOut, value: didCopy)
                
                Button(action: saveNote) {
                    Text("Save As...")
                }
                .buttonStyle(PrimaryButtonStyle()) // Use the premium button style

                Button(action: { isShowing = false }) {
                    Text("Done")
                }
                .buttonStyle(SecondaryButtonStyle())
                .keyboardShortcut(.escape, modifiers: []) // Allow closing with ESC
            }
            .padding()
            .background(Color(hex: "242424"))
            
            Divider().background(Color(hex: "2F2F2F"))

            // --- 3. IMPROVED TEXT EDITOR ---
            // Removed the extra ScrollView
            // The TextEditor is now *directly* editable
            TextEditor(text: $noteContent)
                .font(.body)
                .foregroundColor(Color(hex: "EAEAEA"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(20)
                .scrollContentBackground(.hidden) // Hides the default white bg
                .background(Color(hex: "1A1A1A"))
        }
        .frame(minWidth: 600, minHeight: 650) // Made slightly larger
        .background(Color(hex: "1A1A1A"))
    }
    
    // MARK: - Helper Functions
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(noteContent, forType: .string)
        
        // Show "Copied!" for 2 seconds
        withAnimation {
            didCopy = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                didCopy = false
            }
        }
    }
    
    private func saveNote() {
        let savePanel = NSSavePanel()
        savePanel.title = "Save Notebook"
        savePanel.nameFieldStringValue = "Generated Note.md"
        savePanel.allowedContentTypes = [.text, .markdown] // Allow .txt and .md
        
        guard let window = NSApp.keyWindow else {
            print("Error: Could not find the key window.")
            return
        }
        
        savePanel.beginSheetModal(for: window) { response in
            if response == .OK {
                if let url = savePanel.url {
                    do {
                        try noteContent.write(to: url, atomically: true, encoding: .utf8)
                    } catch {
                        print("Error saving file: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

extension UTType {
    public static let markdown = UTType("net.daringfireball.markdown")!
}
