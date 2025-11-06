import SwiftUI
import SwiftData
import EventKit // Import EventKit

struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Environment(CalendarService.self) private var calendarService
    
    @Query(sort: \ChatSession.startDate, order: .reverse)
    private var chatSessions: [ChatSession]
    
    @Binding var selectedSession: ChatSession?
    
    // --- 1. NEW STATE VARIABLE ---
    // We need to know if we've checked permission yet
    @State private var hasCheckedPermission = false
    
    var body: some View {
        VStack(spacing: 0) {
            // "New Chat" button
            Button(action: createNewChat) {
                Label("New Chat", systemImage: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "EAEAEA"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding()
            
            // Divider
            Rectangle()
                .fill(Color(hex: "2A2A2A"))
                .frame(height: 1)
            
            // Add the new calendar section
            calendarSection()
                .padding(.vertical, 8)
            
            // Divider
            Rectangle()
                .fill(Color(hex: "2A2A2A"))
                .frame(height: 1)
            
            // List of all your past chats
            List(chatSessions, selection: $selectedSession) { session in
                Text(session.title)
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .tag(session)
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
        }
        .background(Color(hex: "1E1E1E"))
        .onAppear {
            // --- 2. MODIFIED onAppear ---
            // Just check the status. This is safe and won't crash.
            Task {
                await calendarService.fetchUpcomingEvents()
                hasCheckedPermission = true
            }
        }
    }
    
    /// Creates the UI for the "Today's Events" section
    @ViewBuilder
    private func calendarSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TODAY'S EVENTS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "AAAAAA"))
                .padding(.horizontal)
            
            // --- 3. SIMPLIFIED LOGIC ---
            if !hasCheckedPermission {
                // Show nothing while we're checking
                EmptyView()
                
            } else if calendarService.isAccessDenied {
                // Case 1: User has denied permission
                VStack(alignment: .leading, spacing: 4) {
                    Text("Calendar is not connected.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "EAEAEA"))
                    
                    // This button now opens settings
                    Button("Grant Access") {
                        calendarService.openPrivacySettings()
                    }
                    .font(.system(size: 11))
                    .buttonStyle(.plain)
                    .foregroundColor(Color(hex: "FF8E53"))
                }
                .padding(.horizontal)
                
            } else if calendarService.upcomingEvents.isEmpty {
                // Case 2: Permission not yet granted, OR granted and no events
                
                // We show this "Grant Access" button if status is "notDetermined"
                Button {
                    Task { await calendarService.requestAccess() }
                } label: {
                    Text("Connect Calendar")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "888888"))
                }
                .buttonStyle(.plain)
                .padding(.horizontal)

            } else {
                // Case 3: Show the upcoming events (max 3)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(calendarService.upcomingEvents.prefix(3), id: \.eventIdentifier) { event in
                        eventRow(event)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    /// Creates a single row for an event
    private func eventRow(_ event: EKEvent) -> some View {
        // ... (this function is unchanged) ...
        HStack(spacing: 6) {
            Circle()
                .fill(Color(cgColor: event.calendar.cgColor))
                .frame(width: 6, height: 6)
            
            Text(event.startDate, style: .time)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "EAEAEA"))
            
            Text(event.title)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "AAAAAA"))
                .lineLimit(1)
                .truncationMode(.tail)
            
            Spacer()
        }
    }
    
    private func createNewChat() {
        // ... (this function is unchanged) ...
        let newSession = ChatSession(title: "New Chat")
        modelContext.insert(newSession)
        
        let welcomeMessage = ChatMessage(
            content: "Hi! I'm Omni. Ask me a question!",
            isUser: false,
            sources: nil
        )
        newSession.messages.append(welcomeMessage)
        
        try? modelContext.save()
        
        selectedSession = newSession
    }
}
