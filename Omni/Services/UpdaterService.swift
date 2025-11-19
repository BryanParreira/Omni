import Foundation
import Sparkle

// This class bridges the Sparkle AppKit logic to your SwiftUI app
class UpdaterService: ObservableObject {
    static let shared = UpdaterService()
    
    private let updaterController: SPUStandardUpdaterController
    
    init() {
        // This controller manages the "Check for Updates" window and logic
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }
    
    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
    
    // If you want to show "v1.0" in your settings
    var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}
