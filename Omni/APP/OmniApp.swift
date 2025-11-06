import SwiftUI
import SwiftData

@main
struct OmniApp: App {
    
    // 1. This tells the app to use your AppDelegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // 2. This is the fix: We replace the 'WindowGroup'
    //    with a 'Settings' scene. This stops the app
    //    from opening a blank window on launch.
    var body: some Scene {
        Settings {
            // We can put your settings view here later if you want
            // For now, it's just a placeholder.
        }
    }
}
