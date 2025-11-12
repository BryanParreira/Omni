import SwiftUI
import AppKit
import SwiftData

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var panelController: OmniPanelController?
    var statusItem: NSStatusItem?
    var hotkeyManager: HotkeyManager?
    var fileIndexer: FileIndexer?
    
    private var setupWindow: NSWindow?
    
    let modelContainer: ModelContainer
    
    var hasCompletedSetup: Bool = false
    
    override init() {
        do {
            modelContainer = try ModelContainer(for: ChatSession.self, ChatMessage.self, IndexedFile.self, FileChunk.self, GlobalSourceFile.self)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
        super.init()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        // 1. Initialize core components
        fileIndexer = FileIndexer(modelContainer: modelContainer)
        panelController = OmniPanelController(modelContainer: modelContainer,
                                                fileIndexer: fileIndexer!)
        
        if !hasCompletedSetup {
            launchSetupWizard()
        } else {
            launchMenuBarApp()
            NSApp.setActivationPolicy(.accessory)
        }
        
        // --- REMOVED ---
        // We removed `requestAccessibilityPermissions()` from here.
        // SetupView now handles this in a much better way.
    }
    
    /// This function shows the SetupView in its own window.
    private func launchSetupWizard() {
        NSApp.setActivationPolicy(.regular) // Show app in Dock
        
        let setupView = SetupView()
            .modelContainer(modelContainer)
            .environment(fileIndexer!)
        
        setupWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 750),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        setupWindow?.isReleasedWhenClosed = false
        setupWindow?.center()
        setupWindow?.contentView = NSHostingView(rootView: setupView)
        setupWindow?.title = "Welcome to Omni"
        
        setupWindow?.titlebarAppearsTransparent = true
        setupWindow?.standardWindowButton(.closeButton)?.isHidden = true
        setupWindow?.standardWindowButton(.miniaturizeButton)?.isHidden = true
        setupWindow?.standardWindowButton(.zoomButton)?.isHidden = true
        
        setupWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    /// This is your original launch logic, now in its own function.
    func launchMenuBarApp() {
        hotkeyManager = HotkeyManager(panelController: panelController)
        setupStatusBar()
        
        // This one line replaces the two old ones and fixes the bug
        hotkeyManager?.registerAllHotkeys()
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "brain.head.profile",
                                     accessibilityDescription: "Omni")
            button.action = #selector(togglePanel)
            button.target = self
        }
    }
    
    @objc func togglePanel() {
        panelController?.toggle()
    }
    
    /// This function is called by the 'Finish Setup' button
    func setupDidComplete() {
        setupWindow?.close() // This already closes the window
        setupWindow = nil
        launchMenuBarApp()
        
        panelController?.show()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    // --- ADD THIS FUNCTION ---
    /// Public function to allow the SetupView to close its own window.
    func closeSetupWindow() {
        setupWindow?.close()
        setupWindow = nil
    }
    // --- END ADDITION ---
    
    // Prevents app from quitting when setup window is closed
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        let hasCompletedSetup = UserDefaults.standard.bool(forKey: "hasCompletedSetup")
        return !hasCompletedSetup
    }
    
    // --- REMOVED ---
    // The `requestAccessibilityPermissions()` function was here,
    // but it is no longer needed as SetupView handles it.
}
