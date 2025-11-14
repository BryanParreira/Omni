import SwiftUI
import SwiftData

@main
struct OmniApp: App {
    
    // This tells the app to use your AppDelegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // --- 1. ADD "DUMMY" STATE ---
    // This state is *only* for the (Cmd+,) Settings window,
    // which is separate from your main app's ContentView.
    @State private var dummyNoteContent: String = ""
    @State private var dummyIsShowingNotebook: Bool = false
    
    var body: some Scene {
        
        // This scene tells macOS the app has settings
        // and (most importantly) prevents a default, blank
        // window from opening on launch.
        Settings {
            // --- 2. PASS THE DUMMY BINDINGS ---
            // This fixes the compile error.
            SettingsView(
                noteContent: $dummyNoteContent,
                isShowingNotebook: $dummyIsShowingNotebook
            )
        }
    }
}
