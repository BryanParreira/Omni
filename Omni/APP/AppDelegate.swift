import SwiftUI
import AppKit
import SwiftData

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var panelController: OmniPanelController?
    var statusItem: NSStatusItem?
    var hotkeyManager: HotkeyManager?
    
    // 1. The AppDelegate creates and owns the database
    let modelContainer: ModelContainer
    
    override init() {
        do {
            modelContainer = try ModelContainer(for: ChatSession.self, ChatMessage.self)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
        super.init()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock
        NSApp.setActivationPolicy(.accessory)
        
        // --- PERMISSION CHECKS ---
        // This will check for Accessibility permission on app launch.
        PermissionsHelper.checkAndRequestAccessibility()
        
        // This will check for Screen Recording permission (for OCR).
        PermissionsHelper.checkAndRequestScreenCapture()
        // --- END OF ADDITIONS ---
        
        // 2. We pass the database container to the panel controller
        //    (This fixes your "Extra argument 'viewModel'" error)
        panelController = OmniPanelController(modelContainer: modelContainer)
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
            
            button.image = NSImage(systemSymbolName: "magnifyingglass.circle.fill",
                                     accessibilityDescription: "Omni")
            
            button.action = #selector(togglePanel)
            button.target = self
        }
    }
    
    @objc func togglePanel() {
        panelController?.toggle()
    }
}
