import SwiftUI
import SwiftData

@main
struct OmniApp: App {
    
    // This tells the app to use your AppDelegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // --- 1. ADD "DUMMY" STATE ---
    // This state is *only* for the (Cmd+,) Settings window.
    @State private var dummyNoteContent: String = ""
    @State private var dummyIsShowingNotebook: Bool = false
    
    var body: some Scene {
        
        // 1. THE MENU BAR ICON (Top right of screen)
        // We use "sparkles" as the icon (standard for AI), but you can change it.
        MenuBarExtra("Omni", systemImage: "sparkles") {
            
            // Button to bring the app to the front
            Button("Open Omni") {
                NSApp.activate(ignoringOtherApps: true)
                // If the window was minimized or hidden, this helps bring it back
                if let window = NSApp.windows.first {
                    window.makeKeyAndOrderFront(nil)
                }
            }
            
            Divider()
            
            // Button to open your GitHub releases page
            Button("Check for Updates...") {
                // REPLACE THIS LINK with your actual GitHub Releases URL
                if let url = URL(string: "https://github.com/bryanparreira/omni/releases") {
                    NSWorkspace.shared.open(url)
                }
            }
            
            Button("About Omni") {
                NSApp.orderFrontStandardAboutPanel(nil)
            }
            
            Divider()
            
            // The Quit Button
            Button("Quit Omni") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q") // Allows Cmd+Q when menu is open
        }
        // This modifier ensures the icon appears in the status bar
        .menuBarExtraStyle(.menu)

        
        // 2. THE SETTINGS WINDOW
        Settings {
            SettingsView(
                noteContent: $dummyNoteContent,
                isShowingNotebook: $dummyIsShowingNotebook
            )
        }
    }
}
