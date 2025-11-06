import SwiftUI
import AppKit
import SwiftData

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var panelController: OmniPanelController?
    var statusItem: NSStatusItem?
    var hotkeyManager: HotkeyManager?
    
    var calendarService = CalendarService()
    
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
        
        // --- THIS IS THE FIX ---
        // Check the calendar status *before* building the UI
        calendarService.checkInitialStatus()
        // --- END OF FIX ---
        
        panelController = OmniPanelController(modelContainer: modelContainer,
                                              calendarService: calendarService)
        
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
