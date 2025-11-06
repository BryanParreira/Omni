import SwiftUI
import AppKit
import SwiftData

@MainActor
class OmniPanelController: NSObject {
    
    private var panel: OmniPanel!
    private var hostingView: NSHostingView<AnyView>?
    
    // 1. The init now just needs the database container
    init(modelContainer: ModelContainer) {
        super.init()

        // 2. Create the ContentView
        let contentView = ContentView()

        // 3. Create the hosting view and inject the database
        //    We are NO LONGER wrapping it in a NavigationStack here.
        let hostingView = NSHostingView(rootView: AnyView(contentView.modelContainer(modelContainer)))
        hostingView.frame = NSRect(x: 0, y: 0, width: 700, height: 600)
        
        panel = OmniPanel(contentView: hostingView)
        self.hostingView = hostingView
    }
    
    func show() {
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // We let the ChatView's .onAppear handle focus
    }

    func toggle() {
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            show()
        }
    }
}
