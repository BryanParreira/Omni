import SwiftUI
import SwiftData
// --- REMOVED: import EventKit ---

struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    
    // --- REMOVED ---
    // @Environment(CalendarService.self) private var calendarService
    // --- END REMOVED ---
    
    @Query(sort: \ChatSession.startDate, order: .reverse)
    private var chatSessions: [ChatSession]
    
    @Binding var selectedSession: ChatSession?
    
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
            
            // --- REMOVED ---
            // The entire "Calendar section" and its Divider are gone
            // --- END REMOVED ---
            
            // List of chats
            List(chatSessions, selection: $selectedSession) { session in
                
                if renamingSession == session {
                    TextField("New name", text: $renameText)
                        .font(.system(size: 13))
                        .textFieldStyle(.plain)
                        .focused($isRenameFieldFocused)
                        .onSubmit { submitRename(session: session) }
                        .onDisappear { submitRename(session: session) }
                        .tag(session)
                } else {
                    Text(session.title)
                        .font(.system(size: 13))
                        .lineLimit(1)
                        .tag(session)
                        .contextMenu {
                            Button {
                                startRename(session: session)
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                deleteSession(session)
                            } label: {
                                Label("Delete Chat", systemImage: "trash")
                            }
                        }
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            
            // --- 🛑 NEW SETTINGS BUTTON 🛑 ---
            Spacer() // Pushes the button to the bottom
            
            Rectangle()
                .fill(Color(hex: "2A2A2A"))
                .frame(height: 1)
            
            NavigationLink(destination: SettingsView()) {
                Label("Settings", systemImage: "gear")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "EAEAEA"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding()
            // --- 🛑 END OF NEW BUTTON 🛑 ---
        }
        .background(Color(hex: "1E1E1E"))
    }
    
    // --- REMOVED ---
    // The 'calendarSection()' and 'eventRow()' functions are gone
    // --- END REMOVED ---
    
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
    
    private func startRename(session: ChatSession) {
        // ... (This function is unchanged) ...
        renamingSession = session
        renameText = session.title
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            isRenameFieldFocused = true
        }
    }
    
    private func submitRename(session: ChatSession) {
        // ... (This function is unchanged) ...
        guard renamingSession == session else { return }
        
        if !renameText.isEmpty {
            session.title = renameText
            try? modelContext.save()
        }
        
        renamingSession = nil
        renameText = ""
    }
}
