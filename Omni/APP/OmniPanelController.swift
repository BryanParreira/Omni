import SwiftUI
import AppKit
import SwiftData

@MainActor
class OmniPanelController: NSObject {
    
    private var panel: OmniPanel!
    private var hostingView: NSHostingView<AnyView>?
    
    private var fileIndexer: FileIndexer
    
    init(modelContainer: ModelContainer, fileIndexer: FileIndexer) {
        self.fileIndexer = fileIndexer
        super.init()

        let contentView = ContentView()

        let hostingView = NSHostingView(
            rootView: AnyView(
                contentView
                    .modelContainer(modelContainer)
                    .environment(fileIndexer)
            )
        )
        hostingView.frame = NSRect(x: 0, y: 0, width: 700, height: 600)
        
        panel = OmniPanel(contentView: hostingView)
        self.hostingView = hostingView
    }
    
    func show() {
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // --- THIS IS THE FIX ---
        // We REMOVE the .setActivationPolicy call from here.
        // The AppDelegate will handle this.
        // --- END OF FIX ---
    }

    func toggle() {
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            show()
        }
    }
}
