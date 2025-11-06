import SwiftUI
import AppKit
import SwiftData

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var panelController: OmniPanelController?
    var statusItem: NSStatusItem?
    var hotkeyManager: HotkeyManager?
    
    var fileIndexer: FileIndexer?
    
    let modelContainer: ModelContainer
    
    override init() {
        do {
            modelContainer = try ModelContainer(for: ChatSession.self, ChatMessage.self, IndexedFile.self, FileChunk.self)
            
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
        super.init()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock
        NSApp.setActivationPolicy(.accessory)
        
        fileIndexer = FileIndexer(modelContainer: modelContainer)
        
        panelController = OmniPanelController(modelContainer: modelContainer,
                                              fileIndexer: fileIndexer!)
        
        hotkeyManager = HotkeyManager(panelController: panelController)
        
        // Setup status bar
        setupStatusBar()
        
        // Register hotkey
        hotkeyManager?.registerHotkey()
        
        // Show panel
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.panelController?.show()
        }
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            
            // --- THIS IS THE CHANGE ---
            // I've swapped the icon to "brain.head.profile"
            button.image = NSImage(systemSymbolName: "brain",
                                     accessibilityDescription: "Omni")
            // --- END OF CHANGE ---
            
            button.action = #selector(togglePanel)
            button.target = self
        }
    }
    
    @objc func togglePanel() {
        panelController?.toggle()
    }
}
