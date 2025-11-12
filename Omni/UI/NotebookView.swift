import SwiftUI
import UniformTypeIdentifiers

struct NotebookView: View {
    @Binding var noteContent: String
    @Binding var isShowing: Bool
    
    @State private var didCopy = false
    @State private var isSaveHovered = false
    @State private var isCopyHovered = false
    @State private var isCloseHovered = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Clean header
            HStack(spacing: 12) {
                // Simple icon
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color(hex: "FF6B6B").opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "FF6B6B"))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Notebook")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("\(wordCount) words · \(characterCount) chars")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "777777"))
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 8) {
                    // Copy button
                    Button(action: copyToClipboard) {
                        HStack(spacing: 6) {
                            Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 12, weight: .medium))
                            Text(didCopy ? "Copied" : "Copy")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(didCopy ? .green : Color(hex: "EAEAEA"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isCopyHovered ? Color(hex: "2A2A2A") : Color(hex: "252525"))
                        )
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.15), value: didCopy)
                    .onHover { hovering in
                        isCopyHovered = hovering
                    }

                    // Save button
                    Button(action: saveNote) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.doc")
                                .font(.system(size: 12, weight: .medium))
                            Text("Save")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Group {
                                if isSaveHovered {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "FF6B6B").opacity(0.9), Color(hex: "FF8E53").opacity(0.9)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                } else {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                }
                            }
                        )
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isSaveHovered = hovering
                        }
                    }

                    // Close button
                    Button(action: { isShowing = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(isCloseHovered ? Color(hex: "AAAAAA") : Color(hex: "666666"))
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(isCloseHovered ? Color(hex: "2A2A2A") : Color(hex: "252525"))
                            )
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.escape, modifiers: [])
                    .onHover { hovering in
                        isCloseHovered = hovering
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(hex: "1A1A1A"))
            
            Rectangle()
                .fill(Color(hex: "2A2A2A"))
                .frame(height: 1)

            // Text editor
            ZStack(alignment: .topLeading) {
                TextEditor(text: $noteContent)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "EAEAEA"))
                    .scrollContentBackground(.hidden)
                    .padding(20)
                
                // Placeholder
                if noteContent.isEmpty {
                    Text("Your generated notebook will appear here...")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "666666"))
                        .padding(.horizontal, 25)
                        .padding(.vertical, 28)
                        .allowsHitTesting(false)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "1A1A1A"))
            
            // Clean footer
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "666666"))
                    Text("Fully editable")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "777777"))
                }
                
                Spacer()
                
                HStack(spacing: 14) {
                    KeyboardShortcut(key: "⌘S", label: "Save")
                    KeyboardShortcut(key: "⌘C", label: "Copy")
                    KeyboardShortcut(key: "ESC", label: "Close")
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(hex: "1E1E1E"))
            .overlay(
                Rectangle()
                    .fill(Color(hex: "2A2A2A"))
                    .frame(height: 1),
                alignment: .top
            )
        }
        .frame(minWidth: 650, minHeight: 700)
        .background(Color(hex: "1A1A1A"))
    }
    
    // MARK: - Computed Properties
    
    private var wordCount: Int {
        noteContent.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }
    
    private var characterCount: Int {
        noteContent.count
    }
    
    // MARK: - Helper Functions
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(noteContent, forType: .string)
        
        withAnimation(.easeOut(duration: 0.2)) {
            didCopy = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeOut(duration: 0.2)) {
                didCopy = false
            }
        }
    }
    
    private func saveNote() {
        let savePanel = NSSavePanel()
        savePanel.title = "Save Notebook"
        savePanel.nameFieldStringValue = "Generated Note.md"
        savePanel.allowedContentTypes = [.text, .init(filenameExtension: "md")!]
        savePanel.canCreateDirectories = true
        
        guard let window = NSApp.keyWindow else {
            print("Error: Could not find the key window.")
            return
        }
        
        savePanel.beginSheetModal(for: window) { response in
            guard response == .OK, let url = savePanel.url else { return }
            
            do {
                guard url.startAccessingSecurityScopedResource() else {
                    print("Couldn't access security scoped resource")
                    return
                }
                defer { url.stopAccessingSecurityScopedResource() }
                
                try self.noteContent.write(to: url, atomically: true, encoding: .utf8)
                print("Note saved successfully to \(url.path)")
            } catch {
                print("Error saving note: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Keyboard Shortcut Component

struct KeyboardShortcut: View {
    let key: String
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(Color(hex: "666666"))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color(hex: "252525"))
                .cornerRadius(3)
            
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "777777"))
        }
    }
}

extension UTType {
    public static let markdown = UTType("net.daringfireball.markdown")!
}
