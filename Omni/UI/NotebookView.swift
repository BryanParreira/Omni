import SwiftUI
import UniformTypeIdentifiers // Import this at the top

struct NotebookView: View {
    @Binding var noteContent: String
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // --- Header ---
            HStack {
                Text("Generated Notebook")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "EAEAEA"))
                
                Spacer()
                
                // --- 🛑 NEW SAVE BUTTON 🛑 ---
                Button(action: { saveNote() }) {
                    Text("Save As...")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "3A3A3A")) // A neutral gray
                        .foregroundColor(Color(hex: "EAEAEA"))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
                // --- 🛑 END OF NEW BUTTON 🛑 ---

                Button(action: { isShowing = false }) {
                    Text("Done")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(hex: "242424"))
            
            Rectangle()
                .fill(Color(hex: "2A2A2A"))
                .frame(height: 1)

            // --- Note Content ---
            ScrollView {
                // --- 🛑 MODIFICATION 🛑 ---
                // We must use a TextEditor if we want the text to be
                // selectable AND scrollable in a way that works well.
                // We'll make it look like the Text view you had.
                TextEditor(text: .constant(noteContent))
                    .font(.body)
                    .foregroundColor(Color(hex: "EAEAEA"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .scrollContentBackground(.hidden) // Hides the default white bg
                    .background(Color.clear)
                // --- 🛑 END OF MODIFICATION 🛑 ---
            }
            .background(Color(hex: "1A1A1A"))
            
        }
        .frame(minWidth: 500, minHeight: 600)
        .background(Color(hex: "1A1A1A"))
    }
    
    // --- 🛑 NEW SAVE FUNCTION 🛑 ---
    private func saveNote() {
        let savePanel = NSSavePanel()
        savePanel.title = "Save Notebook"
        savePanel.nameFieldStringValue = "Generated Note.md"
        savePanel.allowedContentTypes = [.text, .markdown] // Allow .txt and .md
        
        // Get the current window to present the sheet
        guard let window = NSApp.keyWindow else {
            print("Error: Could not find the key window.")
            return
        }
        
        savePanel.beginSheetModal(for: window) { response in
            if response == .OK {
                // If the user clicked "Save"
                if let url = savePanel.url {
                    do {
                        // Try to write the note content to the chosen URL
                        try noteContent.write(to: url, atomically: true, encoding: .utf8)
                    } catch {
                        // Handle errors (e.g., show an alert)
                        print("Error saving file: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    // --- 🛑 END OF NEW FUNCTION 🛑 ---
}

// --- 🛑 THIS IS THE FIX 🛑 ---
// We add a '!' to the end to force-unwrap the optional UTType.
extension UTType {
    public static let markdown = UTType("net.daringfireball.markdown")!
}
