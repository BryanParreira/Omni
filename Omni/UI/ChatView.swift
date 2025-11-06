import SwiftUI
import UniformTypeIdentifiers

struct ChatView: View {
    @StateObject var viewModel: ContentViewModel
    
    @FocusState private var isInputFocused: Bool
    
    @State private var isDropTarget = false
    
    var session: ChatSession {
        viewModel.currentSession
    }
    
    var sortedMessages: [ChatMessage] {
        session.messages.sorted(by: { $0.timestamp < $1.timestamp })
    }
    
    // --- 1. THIS IS THE FIX for the "File Pill" Bug ---
    // This logic determines if we should show the "file pills"
    private var shouldShowFilePills: Bool {
        let hasAttachedFiles = !viewModel.currentSession.attachedFileURLs.isEmpty
        // Check if any message in the history *already* has sources
        let hasMessagesWithSources = sortedMessages.contains(where: { $0.sources != nil && !$0.sources!.isEmpty })
        
        // Only show the pills if we have files attached AND
        // no messages have been sent with them yet.
        return hasAttachedFiles && !hasMessagesWithSources
    }
    // --- END OF FIX ---
    
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
                            
                            if viewModel.isLoading {
                                LoadingIndicatorView().transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
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
                
                // --- 2. THIS IS THE FIX ---
                // We now use our new helper variable to decide
                // whether to show this view or not.
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
                // --- END OF FIX ---
                
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
                            
                            TextField("", text: $viewModel.inputText, prompt: Text("Ask about your files...").foregroundColor(Color(hex: "666666")))
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
                Button(action: { viewModel.clearChat() }) {
                    Image(systemName: "trash")
                }
                .help("Clear chat")
                
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gear")
                }
                .help("Settings")
            }
        }
        .onDrop(of: [UTType.fileURL], isTargeted: $isDropTarget) { providers in
            Task {
                var urls: [URL] = []
                for provider in providers {
                    if let url = try? await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) as? URL {
                        urls.append(url)
                    }
                }
                if !urls.isEmpty {
                    viewModel.addAttachedFiles(urls: urls)
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
    
    // ... (all helper functions are unchanged) ...
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
                    viewModel.addAttachedFiles(urls: openPanel.urls)
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
