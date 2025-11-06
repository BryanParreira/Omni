import SwiftUI

struct ChatView: View {
    @StateObject var viewModel: ContentViewModel
    
    @FocusState private var isInputFocused: Bool
    
    var session: ChatSession {
        viewModel.currentSession
    }
    
    // This sorts the messages by date
    var sortedMessages: [ChatMessage] {
        session.messages.sorted(by: { $0.timestamp < $1.timestamp })
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "1A1A1A"), Color(hex: "1E1E1E")],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // ===============================================
                // The custom top bar has been REMOVED
                // ===============================================
                
                // Chat Area
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {
                            ForEach(sortedMessages) { message in
                                MessageBubbleView(message: message)
                                    .id(message.id)
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
                
                // Attached Files "Pills" View
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
        }
        // ===============================================
        // THIS IS THE FIX:
        // We add back the native toolbar
        // ===============================================
        .navigationTitle(session.title)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: { viewModel.clearChat() }) {
                    Image(systemName: "trash")
                }
                .help("Clear chat (Deletes this session)")
                
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gear")
                }
                .help("Settings")
            }
        }
        // ===============================================
        .onChange(of: viewModel.shouldFocusInput) { _, shouldFocus in
            if shouldFocus { isInputFocused = true }
        }
        .onAppear {
            viewModel.focusInput()
        }
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
}
