import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct ImageSourcePicker: View {
    @Binding var isPresented: Bool
    let onImageSelected: (URL) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Image Source")
                .font(.headline)
                .foregroundColor(Color(hex: "EAEAEA"))
            
            Text("Select an image to extract text from")
                .font(.subheadline)
                .foregroundColor(Color(hex: "AAAAAA"))
            
            HStack(spacing: 15) {
                Button(action: selectFromFiles) {
                    VStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 40))
                            .foregroundColor(Color(hex: "FF6B6B"))
                        Text("Choose Image")
                            .font(.caption)
                            .foregroundColor(Color(hex: "EAEAEA"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "242424"))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                
                Button(action: pasteFromClipboard) {
                    VStack {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 40))
                            .foregroundColor(Color(hex: "FF8E53"))
                        Text("Paste Image")
                            .font(.caption)
                            .foregroundColor(Color(hex: "EAEAEA"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "242424"))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
            
            Button("Cancel") {
                isPresented = false
            }
            .foregroundColor(Color(hex: "AAAAAA"))
        }
        .padding()
        .frame(width: 400)
        .background(Color(hex: "1A1A1A"))
    }
    
    private func selectFromFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .gif, .bmp, .heic]
        panel.message = "Select an image to extract text from"
        
        if panel.runModal() == .OK, let url = panel.url {
            onImageSelected(url)
            isPresented = false
        }
    }
    
    private func pasteFromClipboard() {
        let pasteboard = NSPasteboard.general
        
        // Check for image data in clipboard
        if let imageData = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff) {
            // Save to temporary file
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("png")
            
            do {
                try imageData.write(to: tempURL)
                onImageSelected(tempURL)
                isPresented = false
            } catch {
                print("Failed to save clipboard image: \(error)")
            }
        }
    }
}
