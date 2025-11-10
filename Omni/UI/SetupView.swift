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

// Visual row for feature highlights (used on page 2)
private struct FeatureHighlightRow: View {
    let icon: String // SF Symbol name
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .symbolRenderingMode(.palette)
                .foregroundStyle(brandGradient, Color(hex: "EAEAEA").opacity(0.8))
                .frame(width: 45, height: 45)
                .background(Color(hex: "2F2F2F"))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(Color(hex: "AAAAAA"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(hex: "242424"))
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
    
    // State for the AI page
    @State private var cloudProvider: String = "openai"
    @State private var currentApiKey: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
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
            
            // Footer
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
            
            // --- 🛑 THIS IS THE FIX 🛑 ---
            // The logic for disabling the button was incorrect.
            let isNextDisabled = (currentPage == 3 && selectedProvider == "cloud" && currentApiKey.isEmpty)
            
            if currentPage < 4 {
                Button(action: {
                    handleNext()
                }) {
                    Label("Next", systemImage: "chevron.right")
                }
                .buttonStyle(PrimaryButtonStyle(isDisabled: isNextDisabled))
                .disabled(isNextDisabled)
            } else {
                // The "Finish Setup" button should never be disabled
                // unless we add a final check (e.g., for permissions).
                Button(action: {
                    completeSetup()
                }) {
                    Label("Finish Setup", systemImage: "sparkles")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            // --- 🛑 END OF FIX 🛑 ---
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
                Text("Unlock Your Context")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Explore how Omni can revolutionize your workflow.")
                    .font(.title3)
                    .foregroundColor(Color(hex: "AAAAAA"))
                    .padding(.bottom, 10)

                VStack(spacing: 20) {
                    FeatureHighlightRow(
                        icon: "doc.text.magnifyingglass",
                        title: "Chat With Your Files",
                        description: "Drop in PDFs, code, or text files to ask questions and get instant summaries."
                    )
                    
                    FeatureHighlightRow(
                        icon: "photo.fill",
                        title: "Read Text From Images (OCR)",
                        description: "Drop in screenshots or photos, and Omni will read the text from them."
                    )
                    
                    FeatureHighlightRow(
                        icon: "globe.americas.fill",
                        title: "Analyze Web Pages",
                        description: "Paste any URL into the chat bar to add live web content as a source."
                    )
                    
                    FeatureHighlightRow(
                        icon: "brain",
                        title: "Global Source Library",
                        description: "Give Omni a 'long-term memory' of your most important files, available in any chat."
                    )
                    
                    FeatureHighlightRow(
                        icon: "doc.text.fill",
                        title: "Generate Notebooks",
                        description: "Turn any chat conversation into a clean, structured note to save your key insights."
                    )
                    
                    FeatureHighlightRow(
                        icon: "cpu.fill",
                        title: "100% Private Local AI",
                        description: "Connect to Ollama to run models on your Mac. Your files and chats never leave your device."
                    )
                }
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
    
    // --- 🛑 REDESIGNED: "Wow" Permissions Page 🛑 ---
    private var permissionsPage: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Grant Full Disk Access")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Omni needs this to find and read your files. Your files and their content **never** leave your Mac.")
                .font(.title3)
                .foregroundColor(Color(hex: "AAAAAA"))
                .padding(.bottom, 10)
            
            // --- Visual Guide ---
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    Image(systemName: "lock.shield.fill")
                        .font(.title)
                        .foregroundStyle(brandGradient)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Your Privacy is Paramount")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Omni is a **local-first** app. This permission is only for reading your files locally. Your data never leaves your device.")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "AAAAAA"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                Divider().background(Color(hex: "3A3A3A"))

                Text("How to Grant Access")
                    .font(.headline)
                    .foregroundColor(.white)
                
                // Animated Mock UI
                HStack(spacing: 20) {
                    // Step 1: Button
                    VStack(alignment: .leading, spacing: 10) {
                        Text("STEP 1")
                            .font(.caption)
                            .foregroundColor(Color(hex: "AAAAAA"))
                        Button(action: {
                            isGrantingAccess = true
                            openFullDiskAccessSettings()
                            showingSettingsAlert = true
                        }) {
                            Label(isGrantingAccess ? "Opening..." : "Open Settings", systemImage: "gearshape.fill")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(isGrantingAccess)
                    }
                    
                    Image(systemName: "arrow.right")
                        .font(.title)
                        .foregroundColor(Color(hex: "4A4A4A"))
                    
                    // Step 2 & 3: Visual Demo
                    VStack(alignment: .leading, spacing: 10) {
                        Text("STEP 2 & 3")
                            .font(.caption)
                            .foregroundColor(Color(hex: "AAAAAA"))
                        
                        // Animated mock UI
                        MockSettingsToggleView()
                    }
                }
                
            }
            .padding(25)
            .background(Color(hex: "242424"))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
            
            Spacer()
        }
        .padding(40)
    }
    
    // --- 🛑 NEW: Mock UI for Permissions Page 🛑 ---
    private struct MockSettingsToggleView: View {
        @State private var isAnimating = false
        @State private var showPlus = true
        @State private var showOmni = false
        @State private var isToggled = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                // Mock app list
                HStack {
                    Image(systemName: "app.dash")
                        .font(.title2)
                    Text("Other App")
                    Spacer()
                    Toggle("", isOn: .constant(true)).labelsHidden()
                }
                .foregroundColor(Color(hex: "AAAAAA"))
                .padding(8)
                
                // Animated Omni row
                if showOmni {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.title2)
                            .foregroundStyle(brandGradient)
                        Text("Omni")
                            .fontWeight(.semibold)
                        Spacer()
                        Toggle("", isOn: $isToggled).labelsHidden()
                    }
                    .padding(8)
                    .background(Color.blue.opacity(0.3))
                    .cornerRadius(6)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Animated Plus button
                if showPlus {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color(hex: "8A8A8A"))
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .opacity(isAnimating ? 1.0 : 0.7)
                }
            }
            .padding(12)
            .frame(width: 250, height: 140, alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: "1A1A1A")))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "4A4A4A")))
            .onAppear {
                startAnimation()
            }
        }
        
        func startAnimation() {
            // Reset
            isAnimating = false
            showPlus = true
            showOmni = false
            isToggled = false
            
            // Sequence
            withAnimation(.easeInOut(duration: 0.5).delay(1.0)) {
                isAnimating = true // Plus button pulses
            }
            withAnimation(.easeInOut(duration: 0.5).delay(1.5)) {
                isAnimating = false
                showPlus = false
                showOmni = true // Omni app appears
            }
            withAnimation(.easeInOut(duration: 0.5).delay(2.5)) {
                isToggled = true // Toggle turns on
            }
            // Loop
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                startAnimation()
            }
        }
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
        // This was the fix: We must call handleNext() to save the
        // AI settings if the user is on page 3 and clicks "Finish"
        // (though they can't). This handles the page 4 click.
        if currentPage == 4 {
             handleNext() // This will increment page to 5, but that's ok
        }
        
        hasCompletedSetup = true
        
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.setupDidComplete()
        }
        
        NSApp.keyWindow?.close()
    }
}
