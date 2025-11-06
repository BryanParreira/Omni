import SwiftUI
import SwiftData

struct SidebarView: View {
    // This gives this view access to the database
    @Environment(\.modelContext) private var modelContext
    
    // This fetches all saved ChatSession, ordered by date
    @Query(sort: \ChatSession.startDate, order: .reverse)
    private var chatSessions: [ChatSession]
    
    // This is the "selection" that we will pass back to the main ContentView
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
            
            // List of all your past chats
            List(chatSessions, selection: $selectedSession) { session in
                Text(session.title)
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .tag(session) // This is important for selection
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden) // Makes the background our dark color
        }
        .background(Color(hex: "1E1E1E"))
    }
    
    private func createNewChat() {
        // Create a new session
        let newSession = ChatSession(title: "New Chat")
        modelContext.insert(newSession)
        
        // Create the welcome message for it
        let welcomeMessage = ChatMessage(
            content: "Hi! I'm Omni. Ask me a question!",
            isUser: false,
            sources: nil
        )
        newSession.messages.append(welcomeMessage)
        
        // Save to the database
        try? modelContext.save()
        
        // Select this new chat
        selectedSession = newSession
    }
}
