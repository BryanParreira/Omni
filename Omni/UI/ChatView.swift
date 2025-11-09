import SwiftUI
import UniformTypeIdentifiers // This import provides UTType

struct ChatView: View {
    @StateObject var viewModel: ContentViewModel
    
    @FocusState private var isInputFocused: Bool
    
    @State private var isDropTarget = false
    
    // --- 🛑 NEW STATE FOR ANIMATION 🛑 ---
    @State private var isAnimatingDots = false
    
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
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1A1A1A"), Color(hex: "1E1E1E")],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Chat Area
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {
                            ForEach(sortedMessages) { message in
                                VStack(alignment: .leading, spacing: 8) {
                                    MessageBubbleView(message: message)
                                        .id(message.id)
                                    
                                    if !message.isUser, let action = message.suggestedAction {
                                        suggestedActionButton(action: action, message: message)
                                    }
                                }
                                .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                            }
                            
                            // --- 🛑 THIS IS THE FIX 🛑 ---
                            // Replaced 'LoadingIndicatorView()' with the
                            // 3-dot animation code directly.
                            if viewModel.isLoading {
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
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: "242424")).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "2F2F2F"), lineWidth: 1)))
                                    }
                                    Spacer(minLength: 100)
                                }
                                .onAppear { isAnimatingDots = true }
                                .onDisappear { isAnimatingDots = false } // Added this for safety
                                .transition(.scale.combined(with: .opacity))
                            }
                            // --- 🛑 END OF FIX 🛑 ---
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
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
                
                // Input Area
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
                    .background(Color(hex: "1A1A1A"))
                }
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
    
    // ... (All helper functions remain unchanged) ...
    
    @ViewBuilder
    private func suggestedActionButton(action: String, message: ChatMessage) -> some View {
        let (title, icon) = titleAndIcon(for: action)
        
        Button(action: {
            viewModel.performAction(action: action, on: message)
        }) {
            Label(title, systemImage: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "EAEAEA"))
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(hex: "2A2A2A"))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .padding(.leading, 40)
    }
    
    private func titleAndIcon(for action: String) -> (String, String) {
        let title: String
        let icon: String
        
        switch action {
        case "DRAFT_EMAIL":
            title = "Draft an email with this summary"
            icon = "square.and.pencil"
        case "SUMMARIZE_DOCUMENT":
            title = "Copy this summary"
            icon = "doc.on.doc"
        case "EXPLAIN_CODE":
            title = "Explain this code"
            icon = "doc.text.magnifyingglass"
        case "FIND_BUGS":
            title = "Find potential bugs in this code"
            icon = "ant"
        case "ANALYZE_DATA":
            title = "Analyze this data"
            icon = "chart.bar"
        case "FIND_TRENDS":
            title = "Find trends in this data"
            icon = "chart.line.uptrend.xyaxis"
        default:
            title = action.replacingOccurrences(of: "_", with: " ").capitalized
            icon = "sparkles"
        }
        return (title, icon)
    }
    
    func presentFilePicker() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = true
        
        if let window = NSApp.keyWindow {
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
}
