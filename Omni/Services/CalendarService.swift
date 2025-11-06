import Foundation
import EventKit
import SwiftUI

@MainActor
@Observable
class CalendarService {
    
    private let eventStore = EKEventStore()
    
    // UI-driving properties
    var upcomingEvents: [EKEvent] = []
    
    // --- THIS IS THE FIX ---
    // We re-add 'isAccessDenied' so the app can know the status on launch
    var isAccessDenied: Bool = false
    
    var currentStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }
    
    // --- NEW FUNCTION ---
    // This is safe to call on app launch. It doesn't
    // trigger any pop-ups, it just checks the current state.
    func checkInitialStatus() {
        switch currentStatus {
        case .denied, .restricted:
            self.isAccessDenied = true
        case .fullAccess:
            self.isAccessDenied = false
            Task { await fetchUpcomingEvents() }
        case .notDetermined, .writeOnly:
            self.isAccessDenied = false
        @unknown default:
            self.isAccessDenied = false
        }
    }
    
    /// Requests access to the user's calendar.
    func requestAccess() async {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            
            if granted {
                self.isAccessDenied = false
                await fetchUpcomingEvents()
            } else {
                self.isAccessDenied = true
            }
        } catch {
            print("Failed to request calendar access: \(error)")
            self.isAccessDenied = true
        }
    }
    
    /// Fetches today's upcoming events from the calendar.
    func fetchUpcomingEvents() async {
        guard currentStatus == .fullAccess else {
            print("Cannot fetch, access not granted.")
            return
        }
        
        let calendar = Calendar.current
        let today = Date()
        let startOfToday = calendar.startOfDay(for: today)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        
        let predicate = eventStore.predicateForEvents(
            withStart: startOfToday,
            end: endOfToday,
            calendars: nil
        )
        
        let events = eventStore.events(matching: predicate)
        
        self.upcomingEvents = events.filter {
            !$0.isAllDay && $0.endDate > Date()
        }
        .sorted(by: { $0.startDate < $1.startDate })
    }

    /// Opens System Settings to the "Privacy & Security" pane
    func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
            NSWorkspace.shared.open(url)
        }
    }
}
