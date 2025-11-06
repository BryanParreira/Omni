import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    // REVERTED: No @Environment(FileIndexer.self)
    
    @Query(sort: \ChatSession.startDate, order: .reverse)
    private var allSessions: [ChatSession]
    
    @State private var selectedSession: ChatSession?
    
    var body: some View {
        NavigationSplitView {
            // --- SIDEBAR ---
            SidebarView(selectedSession: $selectedSession)
                .frame(minWidth: 180, idealWidth: 200, maxWidth: 300)
        } detail: {
            // --- DETAIL (CHAT) ---
            
            NavigationStack {
                if let session = selectedSession {
                    
                    // REVERTED: No fileIndexer argument
                    ChatView(viewModel: ContentViewModel(
                        modelContext: modelContext,
                        session: session
                    ))
                    .id(session.id)
                    
                } else {
                    // Show this if no chat is selected
                    VStack {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(LinearGradient(colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        Text("Select a chat or start a new one")
                            .font(.title2)
                            .foregroundColor(Color(hex: "AAAAAA"))
                        
                        Button("Create New Chat", action: createFirstChat)
                            .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(hex: "1A1A1A"))
                }
            }
        }
        .onAppear {
            // When the app launches, select the most recent chat
            if selectedSession == nil {
                selectedSession = allSessions.first
            }
        }
    }
    
    // This is a helper function for the "empty state"
    private func createFirstChat() {
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
