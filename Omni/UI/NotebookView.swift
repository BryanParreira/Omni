import SwiftUI
import UniformTypeIdentifiers

struct NotebookView: View {
    @Binding var noteContent: String
    @Binding var isShowing: Bool
    
    @State private var didCopy = false
    @State private var isSaveHovered = false
    @State private var isCopyHovered = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Enhanced Header
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    // Icon with gradient background
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "FF6B6B").opacity(0.2), Color(hex: "FF8E53").opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 42, height: 42)
                        
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Generated Notebook")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(hex: "EAEAEA"))
                        
                        HStack(spacing: 6) {
                            Image(systemName: "doc.plaintext")
                                .font(.system(size: 10))
                            Text("\(wordCount) words · \(characterCount) characters")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(Color(hex: "8A8A8A"))
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    HStack(spacing: 10) {
                        // Copy Button
                        Button(action: copyToClipboard) {
                            HStack(spacing: 6) {
                                Image(systemName: didCopy ? "checkmark.circle.fill" : "doc.on.doc.fill")
                                    .font(.system(size: 13))
                                Text(didCopy ? "Copied!" : "Copy")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(didCopy ? .green : Color(hex: "EAEAEA"))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color(hex: "2A2A2A"))
                            .cornerRadius(8)
                            .brightness(isCopyHovered ? 0.1 : 0)
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.2), value: didCopy)
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isCopyHovered = hovering
                            }
                        }

                        // Save Button
                        Button(action: saveNote) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.down.doc.fill")
                                    .font(.system(size: 13))
                                Text("Save")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(8)
                            .shadow(color: Color(hex: "FF6B6B").opacity(0.3), radius: 8, x: 0, y: 4)
                            .brightness(isSaveHovered ? 0.1 : 0)
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isSaveHovered = hovering
                            }
                        }

                        // Close Button
                        Button(action: { isShowing = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: "666666"))
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut(.escape, modifiers: [])
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(
                LinearGradient(
                    colors: [Color(hex: "242424"), Color(hex: "1E1E1E")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "FF6B6B").opacity(0.3), Color(hex: "FF8E53").opacity(0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // Text Editor with improved styling
            ZStack(alignment: .topLeading) {
                TextEditor(text: $noteContent)
                    .font(.system(size: 14, design: .default))
                    .foregroundColor(Color(hex: "EAEAEA"))
                    .scrollContentBackground(.hidden)
                    .padding(20)
                
                // Placeholder when empty
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
            
            // Footer with helpful info
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "666666"))
                    Text("This notebook is fully editable")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "8A8A8A"))
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Text("⌘S")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(Color(hex: "666666"))
                        Text("Save")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "8A8A8A"))
                    }
                    
                    HStack(spacing: 4) {
                        Text("⌘C")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(Color(hex: "666666"))
                        Text("Copy")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "8A8A8A"))
                    }
                    
                    HStack(spacing: 4) {
                        Text("ESC")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(Color(hex: "666666"))
                        Text("Close")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "8A8A8A"))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(hex: "1E1E1E"))
            .overlay(
                Rectangle()
                    .fill(Color(hex: "2F2F2F"))
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
        
        withAnimation(.spring(response: 0.3)) {
            didCopy = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.spring(response: 0.3)) {
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

extension UTType {
    public static let markdown = UTType("net.daringfireball.markdown")!
}
