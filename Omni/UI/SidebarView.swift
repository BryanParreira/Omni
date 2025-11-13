import SwiftUI
import SwiftData

struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \ChatSession.startDate, order: .reverse)
    private var chatSessions: [ChatSession]
    
    @Binding var selectedSession: ChatSession?
    
    @State private var renamingSession: ChatSession? = nil
    @State private var renameText: String = ""
    @FocusState private var isRenameFieldFocused: Bool
    @State private var isShowingSettings: Bool = false
    @State private var hoveredSession: ChatSession? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Clean header with app branding
            HStack(spacing: 10) {
                // Simple, elegant icon
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text("Omni")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "EAEAEA"))
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color(hex: "1E1E1E"))
            
            // New Chat button - clean and simple
            Button(action: createNewChat) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                    Text("New Chat")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(Color(hex: "EAEAEA"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "2A2A2A"))
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            // Subtle divider
            Rectangle()
                .fill(Color(hex: "2A2A2A"))
                .frame(height: 1)
            
            // Chat list - clean and minimal
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(chatSessions) { session in
                        ChatSessionRow(
                            session: session,
                            isSelected: selectedSession == session,
                            isRenaming: renamingSession == session,
                            renameText: $renameText,
                            isRenameFieldFocused: $isRenameFieldFocused,
                            isHovered: hoveredSession == session,
                            onSelect: { selectedSession = session },
                            onRename: { startRename(session: session) },
                            onDelete: { deleteSession(session) },
                            onSubmitRename: { submitRename(session: session) }
                        )
                        .onHover { hovering in
                            hoveredSession = hovering ? session : nil
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .background(Color(hex: "1E1E1E"))
            
            Spacer()
            
            // Settings at bottom - clean separator
            Rectangle()
                .fill(Color(hex: "2A2A2A"))
                .frame(height: 1)
            
            Button(action: { isShowingSettings = true }) {
                HStack(spacing: 10) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14))
                    Text("Settings")
                        .font(.system(size: 14, weight: .medium))
                    Spacer()
                }
                .foregroundColor(Color(hex: "AAAAAA"))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .background(Color(hex: "1E1E1E"))
        }
        .background(Color(hex: "1E1E1E"))
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
    }
    
    // MARK: - Private Methods
    
    private func createNewChat() {
        let newSession = ChatSession(title: "New Chat")
        modelContext.insert(newSession)
        
        let welcomeMessage = ChatMessage(
            content: "Hi! I'm Omni. Ask me a question!",
            isUser: false,
            sources: nil
        )
        newSession.messages.append(welcomeMessage)
        
        saveChanges() // Use new save function
        selectedSession = newSession
    }
    
    private func deleteSession(_ session: ChatSession) {
        // --- 1. Improved Delete Behavior ---
        // Check if the deleted session is the selected one
        if selectedSession == session {
            // Get the current list of sessions (respecting the query's sort order)
            let sessions = self.chatSessions
            if let currentIndex = sessions.firstIndex(of: session) {
                if sessions.count == 1 {
                    // It was the last session
                    selectedSession = nil
                } else if currentIndex == 0 {
                    // It was the first item, select the next one (at index 1)
                    selectedSession = sessions[1]
                } else {
                    // It was not the first, select the previous one
                    selectedSession = sessions[currentIndex - 1]
                }
            } else {
                selectedSession = nil // Fallback
            }
        }
        
        // Perform the deletion
        modelContext.delete(session)
        saveChanges() // Use new save function
    }
    
    private func startRename(session: ChatSession) {
        renamingSession = session
        renameText = session.title
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            isRenameFieldFocused = true
        }
    }
    
    private func submitRename(session: ChatSession) {
        guard renamingSession == session else { return }
        
        if !renameText.isEmpty {
            session.title = renameText
            saveChanges() // Use new save function
        }
        
        renamingSession = nil
        renameText = ""
    }
    
    // --- 2. Robust Error Handling ---
    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            // This is a great place to log the error
            print("Error saving model context: \(error.localizedDescription)")
            // You could also show an alert to the user here
        }
    }
}

// MARK: - Chat Session Row

struct ChatSessionRow: View {
    let session: ChatSession
    let isSelected: Bool
    let isRenaming: Bool
    @Binding var renameText: String
    var isRenameFieldFocused: FocusState<Bool>.Binding
    let isHovered: Bool
    let onSelect: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void
    let onSubmitRename: () -> Void
    
    var body: some View {
        Group {
            if isRenaming {
                // Rename field with subtle accent
                HStack(spacing: 8) {
                    Image(systemName: "pencil")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "FF6B6B"))
                    
                    TextField("Chat name", text: $renameText)
                        .font(.system(size: 13))
                        .textFieldStyle(.plain)
                        .foregroundColor(Color(hex: "EAEAEA"))
                        .focused(isRenameFieldFocused)
                        .onSubmit(onSubmitRename)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "252525"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(hex: "FF6B6B").opacity(0.5), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 8)
            } else {
                // Regular chat item
                Button(action: onSelect) {
                    HStack(spacing: 10) {
                        Image(systemName: session.messages.isEmpty ? "bubble.left" : "bubble.left.fill")
                            .font(.system(size: 13))
                            .foregroundColor(
                                isSelected ? Color(hex: "FF6B6B") : Color(hex: "666666")
                            )
                        
                        Text(session.title)
                            .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                            .foregroundColor(
                                isSelected ? Color(hex: "EAEAEA") : Color(hex: "AAAAAA")
                            )
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // --- 3. Fix Row Layout "Jump" ---
                        // The Menu is now always in the layout, but hidden with opacity
                        Menu {
                            Button(action: onRename) {
                                Label("Rename", systemImage: "pencil")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive, action: onDelete) {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "666666"))
                                .frame(width: 20, height: 20)
                        }
                        .menuIndicator(.hidden)
                        .menuStyle(.borderlessButton)
                        .opacity(isHovered ? 1.0 : 0.0) // Use opacity
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                isSelected
                                    ? Color(hex: "252525")
                                    : (isHovered ? Color(hex: "232323") : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(
                                        isSelected ? Color(hex: "FF6B6B").opacity(0.3) : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                .contextMenu {
                    Button(action: onRename) {
                        Label("Rename", systemImage: "pencil")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .animation(.easeInOut(duration: 0.15), value: isHovered) // This animates hover bg and opacity
    }
} 
