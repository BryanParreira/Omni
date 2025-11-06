import SwiftUI
import SwiftData
import EventKit // Import EventKit

struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(CalendarService.self) private var calendarService
    
    @Query(sort: \ChatSession.startDate, order: .reverse)
    private var chatSessions: [ChatSession]
    
    @Binding var selectedSession: ChatSession?
    
    // --- 1. NEW STATE VARIABLES FOR RENAMING ---
    @State private var renamingSession: ChatSession? = nil
    @State private var renameText: String = ""
    @FocusState private var isRenameFieldFocused: Bool
    
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
                
                // --- 2. NEW RENAME LOGIC ---
                // If this session is the one being renamed, show a TextField
                if renamingSession == session {
                    TextField("New name", text: $renameText)
                        .font(.system(size: 13))
                        .textFieldStyle(.plain)
                        .focused($isRenameFieldFocused)
                        .onSubmit { submitRename(session: session) } // Save on Enter
                        .onDisappear { submitRename(session: session) } // Save on click-away
                        .tag(session) // Keep tag for selection
                } else {
                    // Otherwise, show the normal Text
                    Text(session.title)
                        .font(.system(size: 13))
                        .lineLimit(1)
                        .tag(session)
                        .contextMenu {
                            // --- 3. NEW RENAME BUTTON ---
                            Button {
                                startRename(session: session)
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            
                            // Divider
                            Divider()
                            
                            // Existing Delete Button
                            Button(role: .destructive) {
                                deleteSession(session)
                            } label: {
                                Label("Delete Chat", systemImage: "trash")
                            }
                        }
                }
                // --- END OF NEW LOGIC ---
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
        }
        .background(Color(hex: "1E1E1E"))
    }
    
    /// Creates the UI for the "Today's Events" section
    @ViewBuilder
    private func calendarSection() -> some View {
        // ... (This function is unchanged) ...
        VStack(alignment: .leading, spacing: 8) {
            Text("TODAY'S EVENTS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "AAAAAA"))
                .padding(.horizontal)
            
            if calendarService.isAccessDenied {
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
                Button {
                    Task {
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
        // ... (This function is unchanged) ...
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
        // ... (This function is unchanged) ...
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
    
    private func deleteSession(_ session: ChatSession) {
        // ... (This function is unchanged) ...
        if selectedSession == session {
            selectedSession = nil
        }
        modelContext.delete(session)
        try? modelContext.save()
    }
    
    // --- 4. NEW HELPER FUNCTIONS FOR RENAMING ---
    
    /// Sets the state to start renaming a chat
    private func startRename(session: ChatSession) {
        renamingSession = session
        renameText = session.title
        
        // Delay ensures the TextField exists before we try to focus it
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            isRenameFieldFocused = true
        }
    }
    
    /// Saves the new name and exits renaming mode
    private func submitRename(session: ChatSession) {
        // We only want to run this *once*
        guard renamingSession == session else { return }
        
        // Don't save an empty name
        if !renameText.isEmpty {
            session.title = renameText
            try? modelContext.save()
        }
        
        // Reset the state
        renamingSession = nil
        renameText = ""
    }
}
