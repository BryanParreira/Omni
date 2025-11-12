import Foundation
import ApplicationServices // <-- ADD THIS IMPORT

class PermissionsHelper {

    // ... your other existing functions (e.g., for Keychain) ...

    // MARK: - Accessibility Permissions -
    // ADD THE TWO FUNCTIONS BELOW

    /**
     Checks if the user has already granted Accessibility permission.
     - Returns: `true` if permission is granted, `false` otherwise.
     */
    static func checkAccessibilityPermission() -> Bool {
        // This checks the status *without* showing a prompt.
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /**
     Requests Accessibility permission from the user.
     This will show the system pop-up *if* permission hasn't been asked for.
     You should call this from a button in your SettingsView.
     */
    static func requestAccessibilityPermission() {
        // Setting the prompt option to true will show the system pop-up.
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
