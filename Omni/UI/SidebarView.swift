import SwiftUI
import SwiftData

struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \ChatSession.startDate, order: .reverse)
    private var chatSessions: [ChatSession]
    
    @Binding var selectedSession: ChatSession?
    @Binding var noteContent: String
    @Binding var isShowingNotebook: Bool
    
    @State private var renamingSession: ChatSession? = nil
    @State private var renameText: String = ""
    @FocusState private var isRenameFieldFocused: Bool
    @State private var isShowingSettings: Bool = false
    @State private var hoveredSession: ChatSession? = nil
    @State private var newChatButtonHovered = false
    @State private var settingsButtonHovered = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Professional header
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    // Minimal monochrome icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "252525"))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: "AAAAAA"))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Omni")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(hex: "EAEAEA"))
                        
                        Text("AI Assistant")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Color(hex: "666666"))
                    }
                    
                    Spacer()
                }
                
                // Minimal New Chat button
                Button(action: createNewChat) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .medium))
                        Text("New Chat")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "CCCCCC"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(newChatButtonHovered ? Color(hex: "252525") : Color(hex: "222222"))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "2A2A2A"), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.easeOut(duration: 0.15)) {
                        newChatButtonHovered = hovering
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 16)
            .background(Color(hex: "1A1A1A"))
            
            // Elegant divider with gradient
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "FF6B6B").opacity(0.2),
                            Color(hex: "2A2A2A"),
                            Color(hex: "FF8E53").opacity(0.2)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
            
            // Chat list with refined styling
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 4) {
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
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
            .background(Color(hex: "1A1A1A"))
            
            Spacer()
            
            // Premium settings button
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color(hex: "2A2A2A"))
                    .frame(height: 1)
                
                Button(action: { isShowingSettings = true }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    settingsButtonHovered
                                        ? Color(hex: "FF6B6B").opacity(0.15)
                                        : Color(hex: "252525")
                                )
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(
                                    settingsButtonHovered
                                        ? Color(hex: "FF6B6B")
                                        : Color(hex: "888888")
                                )
                        }
                        
                        Text("Settings")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(
                                settingsButtonHovered
                                    ? Color(hex: "EAEAEA")
                                    : Color(hex: "AAAAAA")
                            )
                        
                        Spacer()
                        
                        if settingsButtonHovered {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(hex: "666666"))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(hex: "1A1A1A"))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.easeOut(duration: 0.2)) {
                        settingsButtonHovered = hovering
                    }
                }
            }
        }
        .background(Color(hex: "1A1A1A"))
        .sheet(isPresented: $isShowingSettings) {
            SettingsView(
                noteContent: $noteContent,
                isShowingNotebook: $isShowingNotebook
            )
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
        
        saveChanges()
        selectedSession = newSession
    }
    
    private func deleteSession(_ session: ChatSession) {
        if selectedSession == session {
            let sessions = self.chatSessions
            if let currentIndex = sessions.firstIndex(of: session) {
                if sessions.count == 1 {
                    selectedSession = nil
                } else if currentIndex == 0 {
                    selectedSession = sessions[1]
                } else {
                    selectedSession = sessions[currentIndex - 1]
                }
            } else {
                selectedSession = nil
            }
        }
        
        modelContext.delete(session)
        saveChanges()
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
            saveChanges()
        }
        
        renamingSession = nil
        renameText = ""
    }
    
    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving model context: \(error.localizedDescription)")
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
    
    @State private var menuButtonHovered = false
    
    var body: some View {
        Group {
            if isRenaming {
                // Premium rename field
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "FF6B6B").opacity(0.15))
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "FF6B6B"))
                    }
                    
                    TextField("Chat name", text: $renameText)
                        .font(.system(size: 13, weight: .medium))
                        .textFieldStyle(.plain)
                        .foregroundColor(Color(hex: "EAEAEA"))
                        .focused(isRenameFieldFocused)
                        .onSubmit(onSubmitRename)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "222222"))
                        
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1.5
                            )
                    }
                )
            } else {
                // Premium chat item
                Button(action: onSelect) {
                    HStack(spacing: 12) {
                        // Smaller icon
                        ZStack {
                            Circle()
                                .fill(
                                    isSelected
                                        ? LinearGradient(
                                            colors: [Color(hex: "FF6B6B").opacity(0.2), Color(hex: "FF8E53").opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        : LinearGradient(
                                            colors: [Color(hex: "252525"), Color(hex: "252525")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                )
                                .frame(width: 28, height: 28)
                            
                            Image(systemName: session.messages.isEmpty ? "message" : "message.fill")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(
                                    isSelected ? Color(hex: "FF6B6B") : Color(hex: "777777")
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.title)
                                .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                                .foregroundColor(
                                    isSelected ? Color(hex: "FFFFFF") : Color(hex: "BBBBBB")
                                )
                                .lineLimit(1)
                            
                            if isSelected || isHovered {
                                Text(session.lastMessagePreview)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: "666666"))
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer(minLength: 4)
                        
                        // Menu button
                        Menu {
                            Button(action: onRename) {
                                Label("Rename", systemImage: "pencil")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive, action: onDelete) {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(menuButtonHovered ? Color(hex: "2A2A2A") : Color.clear)
                                    .frame(width: 24, height: 24)
                                
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color(hex: "777777"))
                            }
                        }
                        .menuIndicator(.hidden)
                        .menuStyle(.borderlessButton)
                        .opacity((isHovered || isSelected) ? 1.0 : 0.0)
                        .onHover { hovering in
                            menuButtonHovered = hovering
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    isSelected
                                        ? Color(hex: "252525")
                                        : (isHovered ? Color(hex: "222222") : Color.clear)
                                )
                            
                            if isSelected {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color(hex: "FF6B6B").opacity(0.5),
                                                Color(hex: "FF8E53").opacity(0.5)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                        }
                    )
                    .shadow(
                        color: isSelected ? Color(hex: "FF6B6B").opacity(0.15) : Color.clear,
                        radius: 8,
                        x: 0,
                        y: 2
                    )
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
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
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .animation(.easeOut(duration: 0.15), value: isHovered)
    }
}

// MARK: - ChatSession Extension
extension ChatSession {
    var lastMessagePreview: String {
        if let lastMessage = messages.last {
            return lastMessage.content.prefix(40) + (lastMessage.content.count > 40 ? "..." : "")
        }
        return "No messages yet"
    }
}
