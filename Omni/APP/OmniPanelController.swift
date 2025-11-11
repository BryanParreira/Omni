import SwiftUI
import AppKit
import SwiftData

@MainActor
class OmniPanelController: NSObject {
    
    private var panel: OmniPanel!
    private var hostingView: NSHostingView<AnyView>?
    
    private var fileIndexer: FileIndexer
    private var modelContainer: ModelContainer
    
    init(modelContainer: ModelContainer, fileIndexer: FileIndexer) {
        self.fileIndexer = fileIndexer
        self.modelContainer = modelContainer
        super.init()

        let contentView = ContentView()

        let hostingView = NSHostingView(
            rootView: AnyView(
                contentView
                    .modelContainer(modelContainer)
                    .environment(fileIndexer)
            )
        )
        hostingView.frame = NSRect(x: 0, y: 0, width: 700, height: 600)
        
        panel = OmniPanel(contentView: hostingView)
        self.hostingView = hostingView
    }
    
    func show() {
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func toggle() {
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            show()
        }
    }
    
    // Handle captured text from hotkey
    func handleCapturedText(_ text: String) {
        // Show the panel
        show()
        
        // Create a new chat session with the captured text
        Task { @MainActor in
            let context = modelContainer.mainContext
            
            // Create new session
            let newSession = ChatSession(title: String(text.prefix(40)))
            context.insert(newSession)
            
            // Save text as a temporary file
            let tempURL = saveTextAsTempFile(text: text, fileName: "captured_text.txt")
            
            if let tempURL = tempURL {
                // Add the file to the session
                newSession.attachedFileURLs = [tempURL]
                
                // Index the file
                _ = await fileIndexer.indexFiles(at: [tempURL])
            }
            
            // Save the context
            try? context.save()
            
            print("✅ Created new chat with captured text")
            
            // Post notification to select this new session
            NotificationCenter.default.post(
                name: NSNotification.Name("SelectChatSession"),
                object: nil,
                userInfo: ["sessionID": newSession.id]
            )
        }
    }
    
    // Helper to save text as temp file
    private func saveTextAsTempFile(text: String, fileName: String) -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("❌ Error saving temp file: \(error)")
            return nil
        }
    }
}
