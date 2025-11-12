import SwiftUI
import UniformTypeIdentifiers

struct ChatView: View {
    @StateObject var viewModel: ContentViewModel
    @StateObject private var libraryManager = LibraryManager.shared
    
    @FocusState private var isInputFocused: Bool
    
    @State private var isDropTarget = false
    @State private var isAnimatingDots = false
    @State private var attachButtonHovered = false
    @State private var brainButtonHovered = false
    @State private var sendButtonHovered = false
    @State private var showScrollToBottom = false
    
    var session: ChatSession {
        viewModel.currentSession
    }
    
    var sortedMessages: [ChatMessage] {
        session.messages.sorted(by: { $0.timestamp < $1.timestamp })
    }

    private var shouldShowFilePills: Bool {
        let hasAttachedFiles = !viewModel.currentSession.attachedFileURLs.isEmpty
        let hasMessagesWithSources = sortedMessages.contains(where: { $0.sources != nil && !$0.sources!.isEmpty })
        return hasAttachedFiles && !hasMessagesWithSources
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Clean background
            Color(hex: "1A1A1A").ignoresSafeArea()
            
            VStack(spacing: 0) {
                chatArea
                filePillsArea
                libraryIndicatorArea
                inputArea
            }
            
            if isDropTarget {
                dropOverlay()
            }
        }
        .environmentObject(viewModel)
        .navigationTitle(session.title)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: { viewModel.generateNotebook() }) {
                    Image(systemName: viewModel.isGeneratingNotebook ? "hourglass" : "doc.text.fill")
                }
                .help("Generate Notebook from Chat")
                .disabled(viewModel.isGeneratingNotebook)
            }
        }
        .sheet(isPresented: $viewModel.isShowingNotebook) {
            NotebookView(
                noteContent: $viewModel.notebookContent,
                isShowing: $viewModel.isShowingNotebook
            )
        }
        .onDrop(of: [UTType.fileURL], isTargeted: $isDropTarget) { providers in
            let group = DispatchGroup()
            var collectedURLs: [URL] = []

            for provider in providers {
                group.enter()
                
                _ = provider.loadObject(ofClass: URL.self) { url, error in
                    defer { group.leave() }
                    
                    if let url = url {
                        if url.startAccessingSecurityScopedResource() {
                            collectedURLs.append(url)
                        }
                    } else if let error = error {
                        print("Failed to load dropped file: \(error.localizedDescription)")
                    }
                }
            }

            group.notify(queue: .main) {
                if !collectedURLs.isEmpty {
                    viewModel.addAttachedFiles(urls: collectedURLs)
                }
            }
            
            return true
        }
        .onChange(of: viewModel.shouldFocusInput) { _, shouldFocus in
            if shouldFocus { isInputFocused = true }
        }
        .onAppear {
            viewModel.focusInput()
        }
    }
    
    // MARK: - View Builders
    
    @ViewBuilder
    private var chatArea: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    // Empty state
                    if sortedMessages.isEmpty && !viewModel.isLoading {
                        emptyStateView
                            .padding(.top, 60)
                    }
                    
                    // Messages
                    ForEach(sortedMessages) { message in
                        MessageBubbleView(message: message)
                            .id(message.id)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                    }
                    
                    // Loading indicator
                    if viewModel.isLoading {
                        HStack {
                            loadingIndicator
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        
                        Spacer(minLength: 80)
                    }
                }
            }
            .contextMenu {
                Button(role: .destructive, action: {
                    viewModel.clearChat()
                }) {
                    Label("Clear Chat", systemImage: "trash")
                }
            }
            .onChange(of: session.messages.count) { _, _ in
                if let lastMessage = sortedMessages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: session.id) {
                if let lastMessage = sortedMessages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FF6B6B").opacity(0.15), Color(hex: "FF8E53").opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text("How can I help you today?")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: "EAEAEA"))
                
                Text("Ask me anything or upload files to get started")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "888888"))
            }
        }
    }
    
    @ViewBuilder
    private var loadingIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color(hex: "FF6B6B"))
                    .frame(width: 6, height: 6)
                    .scaleEffect(isAnimatingDots ? 1.0 : 0.5)
                    .opacity(isAnimatingDots ? 1.0 : 0.3)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: isAnimatingDots
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "252525"))
        )
        .onAppear { isAnimatingDots = true }
        .onDisappear { isAnimatingDots = false }
    }
    
    @ViewBuilder
    private var filePillsArea: some View {
        if shouldShowFilePills {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.currentSession.attachedFileURLs, id: \.self) { url in
                        EnhancedFilePill(url: url) {
                            viewModel.removeAttachment(url: url)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            .background(Color(hex: "1E1E1E"))
            .overlay(
                Rectangle()
                    .fill(Color(hex: "2A2A2A"))
                    .frame(height: 1),
                alignment: .top
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    @ViewBuilder
    private var libraryIndicatorArea: some View {
        if viewModel.useGlobalLibrary, let activeProject = libraryManager.activeProject {
            HStack(spacing: 10) {
                Image(systemName: "brain.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "FF6B6B"))
                
                Text("Using:")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "999999"))
                
                HStack(spacing: 5) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 10))
                    Text(activeProject.name)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(Color(hex: "FF6B6B"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "FF6B6B").opacity(0.12))
                .cornerRadius(5)
                
                Text("\(activeProject.files.count) files")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "777777"))
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        viewModel.useGlobalLibrary = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "666666"))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(hex: "FF6B6B").opacity(0.08))
            .overlay(
                Rectangle()
                    .fill(Color(hex: "FF6B6B").opacity(0.3))
                    .frame(height: 1),
                alignment: .top
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
        } else if viewModel.useGlobalLibrary && libraryManager.activeProject == nil {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
                
                Text("No active project. Enable one in Library settings.")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "999999"))
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        viewModel.useGlobalLibrary = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "666666"))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.orange.opacity(0.08))
            .overlay(
                Rectangle()
                    .fill(Color.orange.opacity(0.3))
                    .frame(height: 1),
                alignment: .top
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    @ViewBuilder
    private var inputArea: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(hex: "2A2A2A"))
                .frame(height: 1)
            
            HStack(spacing: 10) {
                // Left buttons group
                HStack(spacing: 6) {
                    // Attach button
                    Button(action: { presentFilePicker() }) {
                        Image(systemName: "paperclip")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(attachButtonHovered ? Color(hex: "AAAAAA") : Color(hex: "666666"))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(attachButtonHovered ? Color(hex: "252525") : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Attach files")
                    .onHover { hovering in
                        attachButtonHovered = hovering
                    }
                    
                    // Brain button
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            viewModel.useGlobalLibrary.toggle()
                        }
                    }) {
                        ZStack {
                            Image(systemName: viewModel.useGlobalLibrary ? "brain.fill" : "brain")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(
                                    viewModel.useGlobalLibrary
                                        ? Color(hex: "FF6B6B")
                                        : (brainButtonHovered ? Color(hex: "AAAAAA") : Color(hex: "666666"))
                                )
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(
                                            viewModel.useGlobalLibrary
                                                ? Color(hex: "FF6B6B").opacity(0.15)
                                                : (brainButtonHovered ? Color(hex: "252525") : Color.clear)
                                        )
                                )
                            
                            // Active indicator dot
                            if viewModel.useGlobalLibrary, libraryManager.activeProject != nil {
                                Circle()
                                    .fill(Color(hex: "FF6B6B"))
                                    .frame(width: 8, height: 8)
                                    .overlay(
                                        Circle()
                                            .stroke(Color(hex: "1A1A1A"), lineWidth: 2)
                                    )
                                    .offset(x: 9, y: -9)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .help(brainButtonHelp)
                    .onHover { hovering in
                        brainButtonHovered = hovering
                    }
                }
                
                // Input field
                HStack(spacing: 8) {
                    TextField(
                        "",
                        text: $viewModel.inputText,
                        prompt: Text("Message Omni...")
                            .foregroundColor(Color(hex: "666666"))
                    )
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "EAEAEA"))
                    .focused($isInputFocused)
                    .onSubmit {
                        withAnimation(.easeOut(duration: 0.2)) {
                            viewModel.sendMessage()
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "252525"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    isInputFocused ? Color(hex: "333333") : Color.clear,
                                    lineWidth: 1
                                )
                        )
                )
                
                // Send button
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        viewModel.sendMessage()
                    }
                }) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            Group {
                                if viewModel.inputText.isEmpty {
                                    Circle()
                                        .fill(Color(hex: "333333"))
                                } else {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                            }
                        )
                        .scaleEffect(sendButtonHovered && !viewModel.inputText.isEmpty ? 1.05 : 1.0)
                        .shadow(
                            color: viewModel.inputText.isEmpty ? Color.clear : Color(hex: "FF6B6B").opacity(0.3),
                            radius: 8
                        )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.inputText.isEmpty)
                .onHover { hovering in
                    sendButtonHovered = hovering
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: "1A1A1A"))
        }
    }
    
    @ViewBuilder
    private func dropOverlay() -> some View {
        ZStack {
            Color.black.opacity(0.7)
            
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 2, dash: [10, 6])
                )
                .padding(40)
            
            VStack(spacing: 16) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(spacing: 6) {
                    Text("Drop files here")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("PDFs, images, and documents")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "999999"))
                }
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - Helper Properties & Functions
    
    private var brainButtonHelp: String {
        if let activeProject = libraryManager.activeProject {
            if viewModel.useGlobalLibrary {
                return "Stop using '\(activeProject.name)' (\(activeProject.files.count) files)"
            } else {
                return "Include '\(activeProject.name)' (\(activeProject.files.count) files)"
            }
        } else {
            return "No active library project"
        }
    }
    
    func presentFilePicker() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = true
        
        let windowToPresentOn = NSApp.keyWindow ?? NSApp.mainWindow
        
        if let window = windowToPresentOn {
            openPanel.beginSheetModal(for: window) { (result) in
                if result == .OK {
                    var urlsToAttach: [URL] = []
                    for url in openPanel.urls {
                        if url.startAccessingSecurityScopedResource() {
                            urlsToAttach.append(url)
                        }
                    }
                    
                    if !urlsToAttach.isEmpty {
                        viewModel.addAttachedFiles(urls: urlsToAttach)
                    }
                }
            }
        }
    }
}

// MARK: - Enhanced File Pill

struct EnhancedFilePill: View {
    let url: URL
    let onRemove: () -> Void
    
    @State private var isHovered = false
    
    private var fileName: String {
        url.lastPathComponent
    }
    
    private var fileIcon: String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.fill"
        case "jpg", "jpeg", "png", "gif", "heic": return "photo.fill"
        case "txt", "md": return "doc.text.fill"
        case "doc", "docx": return "doc.fill"
        case "xls", "xlsx": return "tablecells.fill"
        case "zip", "rar": return "archivebox.fill"
        default: return "doc.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: fileIcon)
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "FF6B6B"))
            
            Text(fileName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "EAEAEA"))
                .lineLimit(1)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(hex: "666666"))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: "252525"))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(hex: "333333"), lineWidth: 1)
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
