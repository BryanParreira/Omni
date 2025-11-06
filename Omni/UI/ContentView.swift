import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    // --- 1. "Catch" the FileIndexer from the environment ---
    @Environment(FileIndexer.self) private var fileIndexer
    
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
                    
                    // --- 2. Pass the fileIndexer into the viewModel ---
                    ChatView(viewModel: ContentViewModel(
                        modelContext: modelContext,
                        session: session,
                        fileIndexer: fileIndexer // <-- Add this argument
                    ))
                    .id(session.id)
                    
                } else {
                    
                    // --- THIS IS THE IMPROVED UI ---
                    VStack(spacing: 16) {
                        // ... (your existing empty state UI) ...
                        Image(systemName: "magnifyingglass.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(LinearGradient(colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        
                        VStack(spacing: 4) {
                            Text("Welcome to Omni")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color(hex: "EAEAEA"))
                            
                            Text("Select a chat or start a new one to begin.")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "AAAAAA"))
                        }
                        
                        StyledButton(
                            title: "Create New Chat",
                            systemImage: "plus",
                            action: createFirstChat
                        )
                        .padding(.top, 8)
                        
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(hex: "1A1A1A"))
                    // --- END OF IMPROVED UI ---
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
