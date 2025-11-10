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
    
    // This reads the *actual* value from UserDefaults.
    @AppStorage("hasCompletedSetup") var hasCompletedSetup: Bool = false
    
    override init() {
        do {
            modelContainer = try ModelContainer(for: ChatSession.self, ChatMessage.self, IndexedFile.self, FileChunk.self)
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
        
        // 2. Check the *real* setup status
        if !hasCompletedSetup {
            // This will run if setup is NOT complete
            launchSetupWizard()
        } else {
            // This will run if setup IS complete
            launchMenuBarApp()
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    /// This function shows the SetupView in its own window.
    private func launchSetupWizard() {
        NSApp.setActivationPolicy(.regular) // Show app in Dock
        
        let setupView = SetupView()
            .modelContainer(modelContainer)
            .environment(fileIndexer!)
        
        setupWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 750), // Use new size
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
        hotkeyManager?.registerHotkey()
        
        // panelController?.show() // Removed: Don't show panel on launch
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
        setupWindow?.close()
        setupWindow = nil
        launchMenuBarApp()
        
        panelController?.show()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    // Prevents app from quitting when setup window is closed
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // We use the *real* value here
        let hasCompletedSetup = UserDefaults.standard.bool(forKey: "hasCompletedSetup")
        return !hasCompletedSetup
    }
}
