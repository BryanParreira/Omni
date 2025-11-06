import SwiftUI
import AppKit
import SwiftData

@MainActor
class OmniPanelController: NSObject {
    
    private var panel: OmniPanel!
    private var hostingView: NSHostingView<AnyView>?
    
    // --- REMOVED ---
    // private var calendarService: CalendarService
    // --- END REMOVED ---
    
    private var fileIndexer: FileIndexer
    
    // --- UPDATED INIT ---
    // Init now only accepts the services we are keeping
    init(modelContainer: ModelContainer, fileIndexer: FileIndexer) {
        self.fileIndexer = fileIndexer // Store it
        super.init()

        // Create the ContentView
        let contentView = ContentView()

        // Create the hosting view and inject the remaining services
        let hostingView = NSHostingView(
            rootView: AnyView(
                contentView
                    .modelContainer(modelContainer)
                    // --- REMOVED ---
                    // .environment(calendarService)
                    // --- END REMOVED ---
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
