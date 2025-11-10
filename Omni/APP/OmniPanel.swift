import AppKit
import SwiftUI

class OmniPanel: NSPanel {
    
    init(contentView: NSView) {
        
        super.init(
            contentRect: contentView.bounds,
            styleMask: [.nonactivatingPanel, .closable, .titled, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // Set the panel's properties
        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = .canJoinAllSpaces
        self.titlebarAppearsTransparent = true // This makes the traffic lights float
        self.isMovableByWindowBackground = true
        self.isReleasedWhenClosed = false
        self.center()
        
        // Set the content view
        self.contentView = contentView
    }
}
