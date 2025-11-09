import SwiftUI
import SwiftData

@main
struct OmniApp: App {
    
    // This tells the app to use your AppDelegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        
        // This scene tells macOS the app has settings
        // and (most importantly) prevents a default, blank
        // window from opening on launch.
        Settings {
            SettingsView()
        }
    }
}
