import SwiftUI
import AppKit
import SwiftData

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // --- Core Components ---
    var panelController: OmniPanelController?
    var statusItem: NSStatusItem?
    var hotkeyManager: HotkeyManager?
    var fileIndexer: FileIndexer?
    
    // --- Setup Window Reference ---
    private var setupWindow: NSWindow?
    
    // --- Database Container ---
    let modelContainer: ModelContainer
    
    // --- Setup State ---
    // We check this directly from UserDefaults to ensure it persists across launches
    @AppStorage("hasCompletedSetup") var hasCompletedSetup: Bool = false
    
    override init() {
        do {
            // Initialize the database
            modelContainer = try ModelContainer(for: ChatSession.self, ChatMessage.self, IndexedFile.self, FileChunk.self, GlobalSourceFile.self)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
        super.init()
    }
    
    // MARK: - App Lifecycle
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        // 1. Initialize core components (Indexer & Panel)
        fileIndexer = FileIndexer(modelContainer: modelContainer)
        panelController = OmniPanelController(modelContainer: modelContainer,
                                              fileIndexer: fileIndexer!)
        
        // 2. CRITICAL: Check if Setup is done
        // We read directly from UserDefaults to be absolutely sure
        let setupDone = UserDefaults.standard.bool(forKey: "hasCompletedSetup")
        
        if !setupDone {
            print("First launch detected. Starting Setup Wizard...")
            launchSetupWizard()
        } else {
            print("Setup already complete. Starting Menu Bar App...")
            launchMenuBarApp()
            
            // Hide the app icon from the Dock since we are in "Menu Bar Mode"
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    // MARK: - Launch Modes
    
    /// Mode A: The Setup Wizard (First Run)
    private func launchSetupWizard() {
        // Show app in Dock so they can see it
        NSApp.setActivationPolicy(.regular)
        
        // Initialize the Setup View
        let setupView = SetupView()
            .modelContainer(modelContainer)
            .environment(fileIndexer!)
        
        // Create the Window
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
        
        // Hide window buttons for a cleaner look
        setupWindow?.titlebarAppearsTransparent = true
        setupWindow?.standardWindowButton(.closeButton)?.isHidden = true
        setupWindow?.standardWindowButton(.miniaturizeButton)?.isHidden = true
        setupWindow?.standardWindowButton(.zoomButton)?.isHidden = true
        
        // Show the window and force it to the front
        setupWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    /// Mode B: The Menu Bar App (Normal Use)
    func launchMenuBarApp() {
        hotkeyManager = HotkeyManager(panelController: panelController)
        setupStatusBar()
        hotkeyManager?.registerAllHotkeys()
    }
    
    // MARK: - Status Bar Configuration
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        // 1. Set the Icon
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "brain.head.profile",
                                   accessibilityDescription: "Omni")
        }
        
        // 2. Create the Menu
        let menu = NSMenu()
        
        // Option 1: Open Omni (Option + Space)
        // We use a space " " as the key and .option as the modifier
        let openItem = NSMenuItem(title: "Open Omni", action: #selector(togglePanel), keyEquivalent: " ")
        openItem.keyEquivalentModifierMask = [.option]
        menu.addItem(openItem)
        
        menu.addItem(NSMenuItem.separator()) // Divider line
        
        // Option 2: Check for Updates
        menu.addItem(withTitle: "Check for Updates...", action: #selector(openUpdates), keyEquivalent: "")
        
        menu.addItem(NSMenuItem.separator()) // Divider line
        
        // Option 3: Quit (Cmd + Q)
        menu.addItem(withTitle: "Quit Omni", action: #selector(quitApp), keyEquivalent: "q")
        
        // 3. Attach the menu to the status item
        statusItem?.menu = menu
    }
    
    // MARK: - Actions
    
    @objc func togglePanel() {
        panelController?.toggle()
    }
    
    @objc func openUpdates() {
        // REPLACE 'YOUR_USERNAME' WITH YOUR ACTUAL GITHUB USERNAME
        if let url = URL(string: "https://github.com/bryanparreira/omni/releases") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Setup Completion Handlers
    
    /// Called by SetupView when the user clicks "Get Started"
    func setupDidComplete() {
        // Close the setup window
        closeSetupWindow()
        
        // Launch the main app
        launchMenuBarApp()
        panelController?.show()
        
        // Transition to "Accessory" mode (hide from Dock) after a split second
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    /// Helper to close the window
    func closeSetupWindow() {
        setupWindow?.close()
        setupWindow = nil
    }
    
    // MARK: - Termination Logic
    
    /// Decides if the app should quit when the last window (Setup) is closed
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        let setupDone = UserDefaults.standard.bool(forKey: "hasCompletedSetup")
        
        if !setupDone {
            // If setup is NOT done and they close the window, quit the app.
            // This forces them to restart the setup next time they open it.
            return true
        } else {
            // If setup IS done, keep running (because we live in the menu bar now).
            return false
        }
    }
}
