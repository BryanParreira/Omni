import SwiftUI
import SwiftData

@main
struct OmniApp: App {
    
    // This tells the app to use your AppDelegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        
        // --- THIS IS THE FIX ---
        // We define the Settings scene, which tells the app
        // not to open a main window by default.
        // This will make the blank "Omni" window disappear forever.
        Settings {
            SettingsView()
        }
        // --- END OF FIX ---
    }
}
