import Foundation
import AppKit
// import ScreenCaptureKit // <-- REMOVED

/// This helper struct manages and requests system-level permissions.
struct PermissionsHelper {
    
    // --- ACCESSIBILITY ---
    
    /**
     Checks if the app has already been granted Accessibility permissions.
     - Returns: `true` if permission is granted, `false` otherwise.
     */
    static func isAccessibilityGranted() -> Bool {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
        let options: [CFString: Any] = [promptKey: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    /**
     Checks for Accessibility permissions. If not granted, it will
     trigger the system prompt for the user.
     */
    static func checkAndRequestAccessibility() {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
        let options: [CFString: Any] = [promptKey: true]
        let _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    /**
     An alert to show the user if they try to use a feature
     without having granted the Accessibility permission.
     */
    static func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "Enable Accessibility for Omni"
        alert.informativeText = "Omni needs Accessibility permissions to read text from your screen. This permission is required to capture your current context.\n\nPlease go to System Settings > Privacy & Security > Accessibility and enable Omni."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "OK")
        
        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    // --- SCREEN CAPTURE (New section) ---
    // --- 🛑 REMOVED unused Screen Capture section 🛑 ---
}
