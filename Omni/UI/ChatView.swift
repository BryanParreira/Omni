import SwiftUI

struct ChatView: View {
    @StateObject var viewModel: ContentViewModel
    
    @FocusState private var isInputFocused: Bool
    
    var session: ChatSession {
        viewModel.currentSession
    }
    
    var sortedMessages: [ChatMessage] {
        session.messages.sorted(by: { $0.timestamp < $1.timestamp })
    }
    
    var body: some View {
        ZStack {
            // ... (background) ...
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
                    // ... (onChange modifiers) ...
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
                
                // ... (Attached Files "Pills" View) ...
                if !viewModel.attachedFiles.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.attachedFiles, id: \.self) { url in
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
                
                // ... (Input Area) ...
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
        }
        .environmentObject(viewModel)
        .navigationTitle(session.title)
        .toolbar {
            // ... (toolbar items) ...
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
        .onChange(of: viewModel.shouldFocusInput) { _, shouldFocus in
            if shouldFocus { isInputFocused = true }
        }
        .onAppear {
            viewModel.focusInput()
        }
    }
    
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
    
    // --- THIS IS THE FIX ---
    // We add all our new actions to this helper
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
    // --- END OF FIX ---
    
    func presentFilePicker() {
        // ... (function is unchanged) ...
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
}
