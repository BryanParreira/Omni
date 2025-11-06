import SwiftUI
import SwiftData

@main
struct OmniApp: App {
    
    // This tells the app to use your AppDelegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        
        // --- THIS IS THE FIX ---
        // We remove the 'Settings' scene.
        // This stops the app from trying to open a new window.
        // We need a placeholder, so we use an empty scene.
        WindowGroup(id: "placeholder") {
            // This window will never be shown because our
            // app is a menu bar app (.accessory).
        }
        // --- END OF FIX ---
    }
}
