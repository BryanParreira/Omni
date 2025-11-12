import SwiftUI
import UniformTypeIdentifiers // This import provides UTType

struct ChatView: View {
    @StateObject var viewModel: ContentViewModel
    
    @FocusState private var isInputFocused: Bool
    
    @State private var isDropTarget = false
    
    // This state is for the 3-dot loading animation
    @State private var isAnimatingDots = false
    
    var session: ChatSession {
        viewModel.currentSession
    }
    
    var sortedMessages: [ChatMessage] {
        session.messages.sorted(by: { $0.timestamp < $1.timestamp })
    }

    /// Shows file pills if files are attached AND no messages have been sent yet.
    private var shouldShowFilePills: Bool {
        let hasAttachedFiles = !viewModel.currentSession.attachedFileURLs.isEmpty
        let hasMessagesWithSources = sortedMessages.contains(where: { $0.sources != nil && !$0.sources!.isEmpty })
        return hasAttachedFiles && !hasMessagesWithSources
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1A1A1A"), Color(hex: "1E1E1E")],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()
            
            VStack(spacing: 0) {
                chatArea
                filePillsArea
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
                    defer {
                        group.leave()
                    }
                    
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
        // --- 🛑 FIX: The .onChange modifiers are moved INSIDE this closure ---
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    ForEach(sortedMessages) { message in
                        VStack(alignment: .leading, spacing: 8) {
                            MessageBubbleView(message: message)
                                .id(message.id)
                        }
                        .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                    }
                    
                    // This is the 3-dot loading animation
                    if viewModel.isLoading {
                        // --- 🛑 FIX: Modifiers moved onto the Group ---
                        Group {
                            // --- MODIFICATION: WRAPPED IN HSTACK + SPACER TO ALIGN LEFT ---
                            HStack {
                                HStack(alignment: .top, spacing: 12) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 6) {
                                            ForEach(0..<3) { index in
                                                Circle()
                                                    .fill(Color(hex: "8A8A8A"))
                                                    .frame(width: 6, height: 6)
                                                    .scaleEffect(isAnimatingDots ? 1.0 : 0.5)
                                                    .opacity(isAnimatingDots ? 1.0 : 0.5)
                                                    .animation(
                                                        Animation.easeInOut(duration: 0.6)
                                                            .repeatForever()
                                                            .delay(Double(index) * 0.2),
                                                        value: isAnimatingDots
                                                    )
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: "242424")).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "2F2F2F"), lineWidth: 1)))
                                .onAppear { isAnimatingDots = true }
                                .onDisappear { isAnimatingDots = false }
                                .transition(.scale.combined(with: .opacity))
                                
                                Spacer() // <-- THIS PUSHES THE BUBBLE LEFT
                            }
                            
                            Spacer(minLength: 100)
                        }
                    }
                }
                .padding(.vertical, 16) // Added vertical padding
            }
            .padding(.horizontal, 20)
            .contextMenu {
                Button(role: .destructive, action: {
                    viewModel.clearChat()
                }) {
                    Label("Clear Chat", systemImage: "trash")
                }
            }
            // --- 🛑 FIX: .onChange modifiers moved here, attached to ScrollView ---
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
    private var filePillsArea: some View {
        if shouldShowFilePills {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.currentSession.attachedFileURLs, id: \.self) { url in
                        FilePillView(url: url) {
                            viewModel.removeAttachment(url: url)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(Color(hex: "242424"))
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    @ViewBuilder
    private var inputArea: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color(hex: "2A2A2A")).frame(height: 1)
            HStack(spacing: 12) {
                Button(action: { presentFilePicker() }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "666666"))
                }
                .buttonStyle(.plain)
                .help("Attach files")
                
                Button(action: {
                    viewModel.useGlobalLibrary.toggle()
                }) {
                    Image(systemName: "brain")
                        .font(.system(size: 18))
                        .foregroundColor(viewModel.useGlobalLibrary ? Color(hex: "FF6B6B") : Color(hex: "666666"))
                        .shadow(
                            color: viewModel.useGlobalLibrary ? Color(hex: "FF6B6B").opacity(0.7) : Color.clear,
                            radius: viewModel.useGlobalLibrary ? 6 : 0,
                            x: 0, y: 0
                        )
                        .animation(.easeInOut(duration: 0.2), value: viewModel.useGlobalLibrary)
                }
                .buttonStyle(.plain)
                .help(viewModel.useGlobalLibrary ? "Stop using Global Library" : "Include Global Library in context")
                
                HStack(spacing: 8) {
                    Image(systemName: "text.cursor")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "666666"))
                    
                    TextField("", text: $viewModel.inputText, prompt: Text("Ask a question or paste a URL...").foregroundColor(Color(hex: "666666")))
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "EAEAEA"))
                        .focused($isInputFocused)
                        .onSubmit { withAnimation { viewModel.sendMessage() } }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: "242424")))
                
                if !viewModel.inputText.isEmpty {
                    Button(action: { withAnimation { viewModel.sendMessage() } }) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(LinearGradient(colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: "1A1A1a"))
        }
    }
    
    @ViewBuilder
    private func dropOverlay() -> some View {
        ZStack {
            Color.black.opacity(0.6)
            
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    Color(hex: "AAAAAA"),
                    style: StrokeStyle(lineWidth: 2, dash: [10])
                )
                .padding(20)
            
            VStack(spacing: 12) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(LinearGradient(colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")], startPoint: .topLeading, endPoint: .bottomTrailing))
                Text("Drop Files Here")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "EAEAEA"))
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - Helper Functions
    
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
        } else {
            print("❌ ERROR: Could not find a window to present the file picker.")
        }
    }
}
