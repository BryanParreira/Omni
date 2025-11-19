import SwiftUI
import SwiftData

@main
struct OmniApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Dummy state for Settings
    @State private var dummyNoteContent: String = ""
    @State private var dummyIsShowingNotebook: Bool = false
    
    var body: some Scene {
        
        // We ONLY keep the Settings window here.
        // The Menu Bar icon is being handled by your AppDelegate.
        Settings {
            SettingsView(
                noteContent: $dummyNoteContent,
                isShowingNotebook: $dummyIsShowingNotebook
            )
        }
    }
}
