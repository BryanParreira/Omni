import Foundation
import EventKit // Apple's Calendar framework
import SwiftUI

@MainActor
@Observable
class CalendarService {
    
    private let eventStore = EKEventStore()
    
    var upcomingEvents: [EKEvent] = []
    var isAccessDenied: Bool = false
    
    /// Requests access to the user's calendar.
    func requestAccess() async -> Bool {
        do {
            // --- FIX: Use new macOS 14 API ---
            // 'requestAccess(to:)' is deprecated.
            // We'll convert the new completion-handler API to async.
            let granted = try await eventStore.requestFullAccessToEvents()
            // --- END OF FIX ---
            
            if granted {
                // Access granted! Fetch events.
                await fetchUpcomingEvents()
                self.isAccessDenied = false
            } else {
                // Access was denied.
                self.isAccessDenied = true
            }
            return granted
        } catch {
            print("Failed to request calendar access: \(error)")
            self.isAccessDenied = true
            return false
        }
    }
    
    /// Fetches today's upcoming events from the calendar.
    func fetchUpcomingEvents() async {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        // --- FIX: Use new macOS 14 API ---
        // '.authorized' is deprecated. We now check for '.fullAccess'.
        guard status == .fullAccess else {
        // --- END OF FIX ---
            if status == .notDetermined {
                // We've never asked, so just show the button.
            } else if status == .denied || status == .restricted {
                // User has previously denied access
                self.isAccessDenied = true
            }
            return // Don't proceed if not authorized
        }
        
        // We are authorized, let's fetch events.
        self.isAccessDenied = false
        
        // Create a date range for "today"
        let calendar = Calendar.current
        let today = Date()
        let startOfToday = calendar.startOfDay(for: today)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        
        // Create a predicate to search for events
        let predicate = eventStore.predicateForEvents(
            withStart: startOfToday,
            end: endOfToday,
            calendars: nil // nil = all calendars
        )
        
        // Fetch the events
        let events = eventStore.events(matching: predicate)
        
        // Filter out all-day events and ones that have already passed
        self.upcomingEvents = events.filter {
            !$0.isAllDay && $0.endDate > Date()
        }
        .sorted(by: { $0.startDate < $1.startDate }) // Sort by start time
    }
    
    /// Opens the Calendar app for the user
    func openCalendar() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Calendar.app"))
    }

    /// Opens System Settings to the "Privacy & Security" pane
    func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
            NSWorkspace.shared.open(url)
        }
    }
}
