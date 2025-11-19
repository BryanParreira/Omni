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
    
    @AppStorage("hasCompletedSetup") var hasCompletedSetup: Bool = false
    
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
        setupStatusBar() // This now adds the menu options
        
        hotkeyManager?.registerAllHotkeys()
    }
    
    // --- UPDATED SECTION STARTS HERE ---
    
    private func setupStatusBar() {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            
            // 1. Set the Icon
            if let button = statusItem?.button {
                button.image = NSImage(systemSymbolName: "brain.head.profile",
                                       accessibilityDescription: "Omni")
            }
            
            // 2. Create the Menu
            let menu = NSMenu()
            
            // --- UPDATED: "Open Omni" with Option + Space ---
            // We use a space " " as the key
            let openItem = NSMenuItem(title: "Open Omni", action: #selector(togglePanel), keyEquivalent: " ")
            // We set the modifier to strictly just .option (no command)
            openItem.keyEquivalentModifierMask = [.option]
            menu.addItem(openItem)
            
            menu.addItem(NSMenuItem.separator()) // Divider line
            
            // Option: Check for Updates
            menu.addItem(withTitle: "Check for Updates...", action: #selector(openUpdates), keyEquivalent: "")
            
            menu.addItem(NSMenuItem.separator()) // Divider line
            
            // Option: Quit (Cmd + Q)
            menu.addItem(withTitle: "Quit Omni", action: #selector(quitApp), keyEquivalent: "q")
            
            // 3. Attach the menu to the status item
            statusItem?.menu = menu
        }
    
    // Action for "Check for Updates"
    @objc func openUpdates() {
        // REPLACE 'YOUR_USERNAME' WITH YOUR ACTUAL GITHUB USERNAME BELOW:
        if let url = URL(string: "https://github.com/bryanparreira/omni/releases") {
            NSWorkspace.shared.open(url)
        }
    }
    
    // Action for "Quit Omni"
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    // --- UPDATED SECTION ENDS HERE ---
    
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
    
    /// Public function to allow the SetupView to close its own window.
    func closeSetupWindow() {
        setupWindow?.close()
        setupWindow = nil
    }
    
    // Prevents app from quitting when setup window is closed
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        let hasCompletedSetup = UserDefaults.standard.bool(forKey: "hasCompletedSetup")
        return !hasCompletedSetup
    }
}
