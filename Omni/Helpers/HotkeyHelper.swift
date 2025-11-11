import Foundation
import AppKit

class HotkeyHelper {
    static let shared = HotkeyHelper()
    
    private init() {}
    
    /// Captures the currently selected text from the frontmost application
    func captureSelectedText() -> String? {
        // Save the current pasteboard contents
        let pasteboard = NSPasteboard.general
        let originalContents = pasteboard.string(forType: .string)
        
        // Simulate Cmd+C to copy selected text
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Press Cmd+C
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true) // C key
        cmdDown?.flags = .maskCommand
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        cmdUp?.flags = .maskCommand
        
        cmdDown?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
        
        // Wait a moment for the copy to complete
        usleep(100000) // 100ms
        
        // Get the copied text
        let copiedText = pasteboard.string(forType: .string)
        
        // Restore original pasteboard contents if different
        if copiedText != originalContents {
            if let original = originalContents {
                pasteboard.clearContents()
                pasteboard.setString(original, forType: .string)
            }
        }
        
        return copiedText
    }
}
