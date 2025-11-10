import SwiftUI
import AppKit

// MARK: - Constants & Helper Views

private struct SettingsKeys {
    static let hasCompletedSetup = "hasCompletedSetup"
    static let selectedProvider = "selected_provider"
    static let openAIKey = "openai_api_key"
    static let anthropicKey = "anthropic_api_key"
    static let geminiKey = "gemini_api_key"
}

private let brandGradient = LinearGradient(
    colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

// A custom button style for primary actions
private struct PrimaryButtonStyle: ButtonStyle {
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 25)
            .background(brandGradient)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(isDisabled ? 0.5 : (configuration.isPressed ? 0.9 : 1.0))
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// A custom button style for secondary actions
private struct SecondaryButtonStyle: ButtonStyle {
    var isDisabled: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(Color(hex: "EAEAEA"))
            .padding(.vertical, 12)
            .padding(.horizontal, 25)
            .background(Color(hex: "2F2F2F"))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(isDisabled ? 0.5 : (configuration.isPressed ? 0.9 : 1.0))
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Visual card for feature highlights (used on page 2)
private struct FeatureCard: View {
    let icon: String // SF Symbol name
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .light))
                .symbolRenderingMode(.palette)
                .foregroundStyle(brandGradient, Color(hex: "EAEAEA").opacity(0.8))
                .frame(width: 50, height: 50)
                .background(Color(hex: "1A1A1A"))
                .cornerRadius(10)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(description)
                .font(.body)
                .foregroundColor(Color(hex: "AAAAAA"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(hex: "242424"))
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
    }
}

// Card for AI provider choices (Cloud vs. Local)
private struct AIChoiceCard: View {
    let title: String
    let icon: String
    let pros: [String]
    let cons: [String]
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(brandGradient)
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(brandGradient)
                    }
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(pros, id: \.self) { pro in
                        HStack(alignment: .top) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(Color.green)
                                .padding(.top, 2)
                            Text(pro)
                                .font(.callout)
                                .foregroundColor(Color(hex: "EAEAEA"))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    ForEach(cons, id: \.self) { con in
                        HStack(alignment: .top) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(Color.red)
                                .padding(.top, 2)
                            Text(con)
                                .font(.callout)
                                .foregroundColor(Color(hex: "AAAAAA"))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(25)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(hex: "2F2F2F"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(isSelected ? AnyShapeStyle(brandGradient) : AnyShapeStyle(Color(hex: "3A3A3A")), lineWidth: isSelected ? 3 : 1)
                    )
                    .shadow(color: isSelected ? Color(hex: "FF8E53").opacity(0.4) : .clear, radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
}


// MARK: - Main SetupView

struct SetupView: View {
    @AppStorage(SettingsKeys.hasCompletedSetup) var hasCompletedSetup: Bool = false
    @AppStorage(SettingsKeys.openAIKey) private var openAIKey: String = ""
    @AppStorage(SettingsKeys.anthropicKey) private var anthropicKey: String = ""
    @AppStorage(SettingsKeys.geminiKey) private var geminiKey: String = ""
    @AppStorage(SettingsKeys.selectedProvider) private var selectedProvider: String = "cloud"
    
    @State private var currentPage = 1
    @State private var isGrantingAccess = false
    @State private var showingSettingsAlert = false
    
    @State private var cloudProvider: String = "openai"
    @State private var currentApiKey: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header: Omni Setup Title and Progress
            setupHeader
            
            // Content Area
            VStack {
                switch currentPage {
                case 1: welcomePage
                case 2: featuresPage
                case 3: aiSetupPage
                case 4: permissionsPage
                default: EmptyView()
                }
            }
            .animation(.easeInOut(duration: 0.4), value: currentPage)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "1A1A1A"))
            
            // Footer: Navigation Buttons
            setupFooter
        }
        .frame(width: 700, height: 750)
        .background(Color(hex: "1A1A1A"))
        .foregroundColor(.white)
        .cornerRadius(15)
        .alert(isPresented: $showingSettingsAlert) {
            Alert(
                title: Text("Full Disk Access Required"),
                message: Text("Please grant Omni 'Full Disk Access' in System Settings to enable file analysis. You might need to drag Omni into the list manually."),
                dismissButton: .default(Text("Got It"))
            )
        }
    }
    
    // MARK: - Header & Footer Components
    
    private var setupHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(brandGradient)
                
                Text("Omni Setup")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Step \(currentPage)/4")
                    .font(.callout)
                    .foregroundColor(Color(hex: "8A8A8A"))
            }
            .padding(.horizontal, 30)
            .padding(.top, 20)
            
            // Progress Bar
            GeometryReader { geometry in
                let progress = CGFloat(currentPage) / 4.0
                Capsule()
                    .fill(Color(hex: "2F2F2F"))
                    .frame(height: 6)
                    .overlay(
                        Capsule()
                            .fill(brandGradient)
                            .frame(width: geometry.size.width * progress)
                            .animation(.easeOut(duration: 0.4), value: progress)
                        , alignment: .leading
                    )
            }
            .frame(height: 6)
            .padding(.horizontal, 30)
            .padding(.bottom, 15)
        }
        .background(Color(hex: "242424"))
    }
    
    private var setupFooter: some View {
        HStack(spacing: 20) {
            Button(action: {
                withAnimation { currentPage -= 1 }
            }) {
                Label("Back", systemImage: "chevron.left")
            }
            .buttonStyle(SecondaryButtonStyle(isDisabled: currentPage == 1))
            .disabled(currentPage == 1)
            
            Spacer()
            
            if currentPage < 4 {
                let isDisabled = (currentPage == 3 && selectedProvider == "cloud" && currentApiKey.isEmpty)
                Button(action: {
                    handleNext()
                }) {
                    Label("Next", systemImage: "chevron.right")
                }
                .buttonStyle(PrimaryButtonStyle(isDisabled: isDisabled))
                .disabled(isDisabled)
            } else {
                Button(action: {
                    completeSetup()
                }) {
                    Label("Finish Setup", systemImage: "sparkles")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(20)
        .background(Color(hex: "242424"))
    }
    
    // MARK: - Page Views
    
    private var welcomePage: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "brain.head.profile")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .symbolRenderingMode(.palette)
                .foregroundStyle(brandGradient, Color(hex: "EAEAEA").opacity(0.8))
                .symbolEffect(.bounce.up.byLayer, options: .repeating, value: currentPage)
            
            Text("Welcome to Omni.")
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(.white)
            
            Text("Your personal AI assistant for everything on your Mac. Let's get started on setting up your ultimate workspace.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(hex: "AAAAAA"))
                .padding(.horizontal, 60)
            
            Spacer()
        }
        .padding(40)
    }
    
    private var featuresPage: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 30) {
                Text("Unlock Powerful Capabilities")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Explore how Omni can revolutionize your workflow.")
                    .font(.title3)
                    .foregroundColor(Color(hex: "AAAAAA"))
                    .padding(.bottom, 10)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    FeatureCard(
                        icon: "doc.text.magnifyingglass",
                        title: "Chat With Your Files",
                        description: "Drop in PDFs, code, or text files to ask questions and get instant summaries."
                    )
                    
                    FeatureCard(
                        icon: "globe.americas.fill",
                        title: "Analyze Web Pages",
                        description: "Paste any URL into the chat bar to add live web content as a source."
                    )
                    
                    FeatureCard(
                        icon: "keyboard.option",
                        title: "Global Hotkey Access",
                        description: "Summon Omni instantly from any app with a quick press of ⌥ + Space."
                    )
                    
                    FeatureCard(
                        icon: "cpu.fill",
                        title: "100% Private Local AI",
                        description: "Connect to Ollama to run models on your Mac. Your files and chats never leave your device."
                    )
                }
                .frame(maxWidth: 800)
            }
            .padding(40)
        }
    }
    
    private var aiSetupPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                Text("Choose Your AI Engine")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Omni supports both powerful cloud-based AIs and privacy-focused local models. Select what's best for you.")
                    .font(.title3)
                    .foregroundColor(Color(hex: "AAAAAA"))
                    .padding(.bottom, 10)
                
                AIChoiceCard(
                    title: "Cloud AI (Recommended)",
                    icon: "cloud.fill",
                    pros: ["Access to the smartest, most powerful models (e.g., GPT-4o, Claude 3.5 Sonnet).", "Easier setup, no local software required."],
                    cons: ["Requires an internet connection.", "Incurs usage costs from the AI provider.", "Data processed by the AI provider."],
                    isSelected: selectedProvider == "cloud"
                ) {
                    selectedProvider = "cloud"
                    currentApiKey = ""
                }
                
                if selectedProvider == "cloud" {
                    cloudProviderSetup
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                AIChoiceCard(
                    title: "Local LLM (Privacy-Focused)",
                    icon: "cpu.fill",
                    pros: ["100% private: your data never leaves your Mac.", "Free to use, works entirely offline.", "No API keys needed."],
                    cons: ["Requires a separate app (Ollama) to be installed and running.", "Models are generally less powerful than cloud alternatives.", "Uses your Mac's CPU/GPU resources."],
                    isSelected: selectedProvider == "local"
                ) {
                    selectedProvider = "local"
                    currentApiKey = ""
                }
                
                if selectedProvider == "local" {
                    localProviderSetup
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(40)
            .frame(maxWidth: .infinity)
        }
    }
    
    private var cloudProviderSetup: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Select Cloud Service:")
                .font(.headline)
                .foregroundColor(Color(hex: "EAEAEA"))
            
            Picker("AI Provider", selection: $cloudProvider) {
                Text("OpenAI").tag("openai")
                Text("Anthropic").tag("anthropic")
                Text("Google Gemini").tag("gemini")
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .onChange(of: cloudProvider) { _, _ in currentApiKey = "" }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Get your API key from:")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "AAAAAA"))
                Link(apiKeyURL.host ?? "provider website", destination: apiKeyURL)
                    .font(.callout)
                    .foregroundStyle(brandGradient)
            }
            
            SecureField(apiKeyPlaceholder, text: $currentApiKey)
                .textFieldStyle(.plain)
                .font(.body)
                .padding(12)
                .background(Color(hex: "1F1F1F"))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "3A3A3A")))
            
            Text("Your API key is securely stored in your Mac's Keychain.")
                .font(.caption)
                .foregroundColor(Color(hex: "8A8A8A"))
        }
        .padding(25)
        .background(Color(hex: "242424"))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
    
    private var localProviderSetup: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Setup Ollama (Local LLM Engine):")
                .font(.headline)
                .foregroundColor(Color(hex: "EAEAEA"))
            
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Text("1.")
                    Button("Download and run the Ollama app") {
                        if let url = URL(string: "https://ollama.com/download") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.link)
                    .foregroundStyle(brandGradient)
                }
                Text("2. Ensure the Ollama icon is visible in your Mac's menu bar (it needs to be running).")
                Text("3. Open Terminal and install a model (e.g., Llama 3.1):")
                
                Text("ollama run llama3.1")
                    .font(.system(.body, design: .monospaced))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "1F1F1F"))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "3A3A3A")))
                
                Text("Omni will automatically detect your installed Ollama models.")
                    .font(.caption)
                    .foregroundColor(Color(hex: "8A8A8A"))
            }
            .font(.subheadline)
            .foregroundColor(Color(hex: "AAAAAA"))
        }
        .padding(25)
        .background(Color(hex: "242424"))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
    
    private var permissionsPage: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Grant Full Disk Access")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Omni needs this critical permission to **find and index** all your files, documents, and code across your Mac.")
                .font(.title3)
                .foregroundColor(Color(hex: "AAAAAA"))
                .padding(.bottom, 10)
            
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    Image(systemName: "lock.shield.fill")
                        .font(.title)
                        .foregroundStyle(brandGradient)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Your Privacy is Paramount")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Omni is a **local-first** app. Full Disk Access is only for reading your files locally. **Your data and its content never leave your Mac.**")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "AAAAAA"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                Divider().background(Color(hex: "3A3A3A"))
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("Follow these steps:")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    // --- 🛑 THIS IS THE FIX 🛑 ---
                    // The .foregroundColor() modifier has been replaced
                    // with .foregroundStyle() to accept the gradient.
                    HStack(alignment: .top) {
                        Text("1.")
                            .fontWeight(.bold)
                            .foregroundStyle(brandGradient)
                        Text("Click the button below to open your Mac's **System Settings** directly to the 'Full Disk Access' section.")
                    }
                    HStack(alignment: .top) {
                        Text("2.")
                            .fontWeight(.bold)
                            .foregroundStyle(brandGradient)
                        Text("Click the **'+'** button (you might need to unlock with your password), then navigate to your **Applications** folder and add **Omni**.")
                    }
                    HStack(alignment: .top) {
                        Text("3.")
                            .fontWeight(.bold)
                            .foregroundStyle(brandGradient)
                        Text("Crucially, make sure the **toggle switch for Omni is turned ON** in the list.")
                    }
                    // --- 🛑 END OF FIX 🛑 ---
                }
                .font(.subheadline)
                .foregroundColor(Color(hex: "AAAAAA"))
            }
            .padding(25)
            .background(Color(hex: "242424"))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
            
            Button(action: {
                isGrantingAccess = true
                openFullDiskAccessSettings()
                showingSettingsAlert = true
            }) {
                Label(isGrantingAccess ? "Opening System Settings..." : "Open Privacy & Security Settings", systemImage: "gearshape.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
            .frame(maxWidth: .infinity)
            .disabled(isGrantingAccess)
            
            Spacer()
        }
        .padding(40)
    }
    
    // MARK: - Helper Functions
    
    private var apiKeyURL: URL {
        switch cloudProvider {
        case "openai":
            return URL(string: "https://platform.openai.com/keys")!
        case "anthropic":
            return URL(string: "https://console.anthropic.com/keys")!
        case "gemini":
            return URL(string: "https://aistudio.google.com/keys")!
        default:
            return URL(string: "https://google.com")!
        }
    }
    
    private var apiKeyPlaceholder: String {
        switch cloudProvider {
        case "openai":
            return "sk-..."
        case "anthropic":
            return "sk-ant-..."
        case "gemini":
            return "AIzaSy..."
        default:
            return "Enter API Key"
        }
    }
    
    private func handleNext() {
        if currentPage == 3 {
            // Save the keys from the AI page
            if selectedProvider == "cloud" {
                switch cloudProvider {
                case "openai":
                    openAIKey = currentApiKey
                case "anthropic":
                    anthropicKey = currentApiKey
                case "gemini":
                    geminiKey = currentApiKey
                default:
                    break
                }
                UserDefaults.standard.set(cloudProvider, forKey: SettingsKeys.selectedProvider)
            } else {
                UserDefaults.standard.set("local", forKey: SettingsKeys.selectedProvider)
            }
        }
        
        withAnimation { currentPage += 1 }
    }
    
    private func openFullDiskAccessSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func completeSetup() {
        if currentPage == 4 {
             handleNext() // Just in case, save any state
        }
        
        hasCompletedSetup = true
        
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.setupDidComplete()
        }
        
        NSApp.keyWindow?.close()
    }
}
