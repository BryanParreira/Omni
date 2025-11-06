import SwiftUI
import SwiftData
import EventKit // Import EventKit

struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(CalendarService.self) private var calendarService
    
    @Query(sort: \ChatSession.startDate, order: .reverse)
    private var chatSessions: [ChatSession]
    
    @Binding var selectedSession: ChatSession?
    
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
            
            // Calendar section
            calendarSection()
                .padding(.vertical, 8)
            
            // Divider
            Rectangle()
                .fill(Color(hex: "2A2A2A"))
                .frame(height: 1)
            
            // List of chats
            List(chatSessions, selection: $selectedSession) { session in
                Text(session.title)
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .tag(session)
                    // --- NEW FEATURE ---
                    // Add a right-click context menu
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteSession(session)
                        } label: {
                            Label("Delete Chat", systemImage: "trash")
                        }
                    }
                    // --- END OF FEATURE ---
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
        }
        .background(Color(hex: "1E1E1E"))
        // We're done with onAppear, the logic is in the AppDelegate now
    }
    
    /// Creates the UI for the "Today's Events" section
    @ViewBuilder
    private func calendarSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TODAY'S EVENTS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "AAAAAA"))
                .padding(.horizontal)
            
            // This logic now works on launch because
            // 'isAccessDenied' is set by the AppDelegate
            if calendarService.isAccessDenied {
                // Case 1: User has denied permission
                VStack(alignment: .leading, spacing: 4) {
                    Text("Calendar is not connected.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "EAEAEA"))
                    
                    Button("Grant Access") {
                        calendarService.openPrivacySettings()
                    }
                    .font(.system(size: 11))
                    .buttonStyle(.plain)
                    .foregroundColor(Color(hex: "FF8E53"))
                }
                .padding(.horizontal)

            } else if calendarService.currentStatus == .notDetermined {
                // Case 2: We haven't asked yet.
                Button {
                    Task {
                        // Add the delay back to prevent layout crash
                        try? await Task.sleep(nanoseconds: 100_000_000)
                        await calendarService.requestAccess()
                    }
                } label: {
                    Text("Connect Calendar")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "888888"))
                }
                .buttonStyle(.plain)
                .padding(.horizontal)

            } else if calendarService.upcomingEvents.isEmpty {
                // Case 3: Permission given, but no events
                HStack {
                    Text("No upcoming events today.")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "888888"))
                    Spacer()
                    Button(action: {
                        Task { await calendarService.fetchUpcomingEvents() }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                
            } else {
                // Case 4: Show the upcoming events
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
    
    // --- NEW FUNCTION ---
    private func deleteSession(_ session: ChatSession) {
        // If the user deletes the chat they're looking at,
        // we need to deselect it.
        if selectedSession == session {
            selectedSession = nil
        }
        modelContext.delete(session)
        try? modelContext.save()
    }
    // --- END NEW FUNCTION ---
}
