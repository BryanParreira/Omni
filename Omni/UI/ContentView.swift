import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    // "Catch" the FileIndexer from the environment
    @Environment(FileIndexer.self) private var fileIndexer
    
    // --- REMOVED ---
    // @AppStorage("selectedAppearance") private var selectedAppearance: Appearance = .system
    // --- END REMOVED ---
    
    @Query(sort: \ChatSession.startDate, order: .reverse)
    private var allSessions: [ChatSession]
    
    @State private var selectedSession: ChatSession?
    
    var body: some View {
        NavigationSplitView {
            // --- SIDEBAR ---
            SidebarView(selectedSession: $selectedSession)
                // --- 🛑 THIS IS THE FIX 🛑 ---
                // We set a single, fixed width to prevent resizing.
                .frame(width: 200)
                // --- 🛑 END OF FIX 🛑 ---
        } detail: {
            // --- DETAIL (CHAT) ---
            
            NavigationStack {
                if let session = selectedSession {
                    
                    // Pass the fileIndexer into the viewModel
                    ChatView(viewModel: ContentViewModel(
                        modelContext: modelContext,
                        session: session,
                        fileIndexer: fileIndexer
                    ))
                    .id(session.id)
                    
                } else {
                    
                    // --- THIS IS THE IMPROVED UI ---
                    VStack(spacing: 16) {
                        
                        // We replaced "magnifyingglass.circle.fill" with "brain"
                        Image(systemName: "brain")
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
        // --- REMOVED ---
        // .preferredColorScheme(selectedAppearance.colorScheme)
        // --- END REMOVED ---
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
