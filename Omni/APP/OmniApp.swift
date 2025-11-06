import SwiftUI
import SwiftData

@main
struct OmniApp: App {
    // This connects your custom AppDelegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // We do NOT have a WindowGroup here.
        // Your AppDelegate is in full control of the chat panel.
        
        Settings {
            // This is for the *separate* settings window (Cmd + ,)
            // We will make our gear button open this instead.
            SettingsView()
        }
    }
}
