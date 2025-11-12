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
        
        // --- IMPROVEMENT 1 ---
        // Instead of a specific list, we can just allow all image types.
        // This is simpler and more future-proof.
        panel.allowedContentTypes = [.image]
        
        panel.message = "Select an image to extract text from"
        
        if panel.runModal() == .OK, let url = panel.url {
            onImageSelected(url)
            isPresented = false
        }
    }
    
    private func pasteFromClipboard() {
        let pasteboard = NSPasteboard.general
        
        // --- IMPROVEMENT 2 ---
        // This is a more robust way to handle pasted images.
        // Instead of checking only for PNG or TIFF data, this:
        // 1. Asks the pasteboard for *any* image it has (JPEG, PNG, etc.)
        // 2. Gets the actual NSImage object.
        // 3. Converts that image to PNG data to save to a temporary file.
        // This correctly handles screenshots, copied JPEGs from web, etc.
        
        // 1. Check if the clipboard can provide an NSImage
        
        // --- THIS IS THE FIX ---
        // The argument label is 'withDataConformingToTypes', not 'withDataConformingTo'
        guard pasteboard.canReadItem(withDataConformingToTypes: NSImage.imageTypes) else {
            print("No image data on clipboard that NSImage can read.")
            return
        }
        
        // 2. Read the NSImage object from the pasteboard
        guard let nsImage = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage else {
            print("Failed to read NSImage from clipboard.")
            return
        }
        
        // 3. Get the TIFF representation (a common intermediate format)
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            print("Failed to get TIFF representation of clipboard image.")
            return
        }
        
        // 4. Convert the bitmap to PNG data
        guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
            print("Failed to convert clipboard image to PNG data.")
            return
        }
        
        // 5. Save the PNG data to a temporary URL
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
        
        do {
            try pngData.write(to: tempURL)
            onImageSelected(tempURL)
            isPresented = false
        } catch {
            print("Failed to save clipboard image: \(error)")
        }
    }
}
