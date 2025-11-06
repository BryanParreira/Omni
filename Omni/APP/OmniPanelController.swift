import SwiftUI
import AppKit
import SwiftData

@MainActor
class OmniPanelController: NSObject {
    
    private var panel: OmniPanel!
    private var hostingView: NSHostingView<AnyView>?
    
    // --- 1. NEW PROPERTY ---
    private var calendarService: CalendarService
    
    // --- 2. MODIFIED INIT ---
    // Init now accepts the CalendarService
    init(modelContainer: ModelContainer, calendarService: CalendarService) {
        self.calendarService = calendarService // Store it
        super.init()

        // 3. Create the ContentView
        let contentView = ContentView()

        // 4. Create the hosting view and inject *both* the database
        //    and the new calendar service into the environment.
        let hostingView = NSHostingView(
            rootView: AnyView(
                contentView
                    .modelContainer(modelContainer)
                    .environment(calendarService) // <-- ADD THIS
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
