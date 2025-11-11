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

// MARK: - Animated Mock Views

// Mockup for Welcome Page (Chat Demo)
private struct AnimatedChatMock: View {
    @State private var showFile = false
    @State private var showQuestion = false
    @State private var showLoading = false
    @State private var showAnswer = false
    @State private var resetAnimation = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Mock Chat
            VStack(spacing: 12) {
                if showFile {
                    HStack {
                        Image(systemName: "doc.text.fill")
                        Text("Company_Report.pdf")
                        Spacer()
                    }
                    .font(.caption)
                    .padding(8)
                    .background(Color(hex: "2F2F2F"))
                    .cornerRadius(6)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }
                
                if showQuestion {
                    Text("What's the main takeaway?")
                        .font(.caption)
                        .padding(10)
                        .background(Color(hex: "3A3A3A"))
                        .cornerRadius(10)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
                
                if showLoading {
                    HStack(spacing: 4) {
                        ForEach(0..<3) { i in
                            Circle().frame(width: 4, height: 4)
                        }
                    }
                    .foregroundColor(Color(hex: "8A8A8A"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
                }
                
                if showAnswer {
                    Text("The main takeaway is a 20% increase in Q4 revenue, driven by new market expansion.")
                        .font(.caption)
                        .padding(10)
                        .background(Color(hex: "2A2A2A"))
                        .cornerRadius(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
                Spacer()
            }
            .padding(12)
        }
        .frame(width: 400, height: 200)
        .background(Color(hex: "1A1A1A"))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "3A3A3A")))
        .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 10)
        .onAppear {
            startAnimation()
        }
        .onChange(of: resetAnimation) { _, _ in
            startAnimation()
        }
    }
    
    func startAnimation() {
        showFile = false
        showQuestion = false
        showLoading = false
        showAnswer = false
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5)) {
            showFile = true
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(1.5)) {
            showQuestion = true
        }
        withAnimation(.easeInOut.delay(2.5)) {
            showLoading = true
        }
        withAnimation(.easeInOut.delay(3.5)) {
            showLoading = false
            showAnswer = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            resetAnimation.toggle()
        }
    }
}

// Mockup for Features Page (Web Scrape)
private struct AnimatedWebScrapeMock: View {
    @State private var showURL = false
    @State private var showLoading = false
    @State private var showPill = false
    @State private var resetAnimation = false

    var body: some View {
        VStack(spacing: 15) {
            HStack(spacing: 8) {
                Image(systemName: "text.cursor")
                    .foregroundColor(Color(hex: "666666"))
                if showURL {
                    Text("https://en.wikipedia.org/wiki/Swift...")
                        .font(.caption)
                        .foregroundColor(Color(hex: "EAEAEA"))
                        .transition(.opacity)
                }
                Spacer()
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: "242424")))
            
            if showLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .transition(.opacity)
            }
            
            if showPill {
                HStack {
                    Image(systemName: "doc.text.fill")
                    Text("en.wikipedia.org.txt")
                    Spacer()
                }
                .font(.caption)
                .padding(8)
                .background(Color(hex: "2F2F2F"))
                .cornerRadius(6)
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(Color(hex: "1A1A1A"))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "3A3A3A")))
        .onAppear { startAnimation() }
        .onChange(of: resetAnimation) { _, _ in startAnimation() }
    }
    
    func startAnimation() {
        showURL = false
        showLoading = false
        showPill = false
        
        withAnimation(.easeInOut.delay(0.5)) {
            showURL = true
        }
        withAnimation(.easeInOut.delay(1.5)) {
            showURL = false
            showLoading = true
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(2.5)) {
            showLoading = false
            showPill = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            resetAnimation.toggle()
        }
    }
}

// Mockup for Features Page (OCR)
private struct AnimatedOCRMock: View {
    @State private var showImage = false
    @State private var showLoading = false
    @State private var showPill = false
    @State private var resetAnimation = false
    
    var body: some View {
        VStack(spacing: 15) {
            if showImage {
                Image(systemName: "photo.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(brandGradient)
                    .transition(.scale.combined(with: .opacity))
            }
            
            if showLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .transition(.opacity)
            }
            
            if showPill {
                HStack {
                    Image(systemName: "doc.text.fill")
                    Text("Assignment.jpg.txt")
                    Spacer()
                }
                .font(.caption)
                .padding(8)
                .background(Color(hex: "2F2F2F"))
                .cornerRadius(6)
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(Color(hex: "1A1A1A"))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "3A3A3A")))
        .onAppear { startAnimation() }
        .onChange(of: resetAnimation) { _, _ in startAnimation() }
    }
    
    func startAnimation() {
        showImage = false
        showLoading = false
        showPill = false
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5)) {
            showImage = true
        }
        withAnimation(.easeInOut.delay(1.5)) {
            showImage = false
            showLoading = true
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(2.5)) {
            showLoading = false
            showPill = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            resetAnimation.toggle()
        }
    }
}

// Mockup for Features Page (Global Library)
private struct AnimatedLibraryMock: View {
    @State private var brainOn = false
    @State private var resetAnimation = false

    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "brain")
                .font(.system(size: 30))
                .foregroundColor(brainOn ? Color(hex: "FF6B6B") : Color(hex: "666666"))
                .shadow(
                    color: brainOn ? Color(hex: "FF6B6B").opacity(0.7) : Color.clear,
                    radius: brainOn ? 8 : 0
                )
            
            Text(brainOn ? "Global Library Active" : "Global Library Inactive")
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(brainOn ? .white : Color(hex: "AAAAAA"))
            
            Text("Access your key files in *any* chat.")
                .font(.caption)
                .foregroundColor(Color(hex: "AAAAAA"))
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(Color(hex: "1A1A1A"))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "3A3A3A")))
        .onAppear { startAnimation() }
        .onChange(of: resetAnimation) { _, _ in startAnimation() }
    }
    
    func startAnimation() {
        brainOn = false
        withAnimation(.easeInOut(duration: 1.0).delay(1.0)) {
            brainOn = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            resetAnimation.toggle()
        }
    }
}

// Mockup for Permissions Page
private struct MockSettingsToggleView: View {
    @State private var isAnimating = false
    @State private var showPlus = true
    @State private var showOmni = false
    @State private var isToggled = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "app.dash")
                    .font(.title2)
                Text("Other App")
                Spacer()
                Toggle("", isOn: .constant(true)).labelsHidden()
            }
            .foregroundColor(Color(hex: "AAAAAA"))
            .padding(8)
            
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
        .onAppear { startAnimation() }
    }
    
    func startAnimation() {
        isAnimating = false
        showPlus = true
        showOmni = false
        isToggled = false
        
        withAnimation(.easeInOut(duration: 0.5).delay(1.0)) {
            isAnimating = true
        }
        withAnimation(.easeInOut(duration: 0.5).delay(1.5)) {
            isAnimating = false
            showPlus = false
            showOmni = true
        }
        withAnimation(.easeInOut(duration: 0.5).delay(2.5)) {
            isToggled = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            startAnimation()
        }
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
            
            let isDisabled = (currentPage == 3 && selectedProvider == "cloud" && currentApiKey.isEmpty)
            
            if currentPage < 4 {
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
            
            Text("Welcome to Omni.")
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(.white)
            
            Text("See how Omni turns your files into answers.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(hex: "AAAAAA"))
                .padding(.horizontal, 60)
            
            // The "wow" animation is now the first thing they see
            AnimatedChatMock()
            
            Spacer()
        }
        .padding(40)
    }
    
    // --- 🛑 REDESIGNED: Features Page (With NEW Animations) 🛑 ---
    private var featuresPage: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 30) {
                Text("Unlock Your Full Context")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Omni works with more than just text.")
                    .font(.title3)
                    .foregroundColor(Color(hex: "AAAAAA"))
                    .padding(.bottom, 10)

                // Grid of new animations
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Analyze Web Pages")
                            .font(.headline)
                            .foregroundColor(Color(hex: "EAEAEA"))
                            .padding(.leading, 5)
                        AnimatedWebScrapeMock()
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Read Text From Images")
                            .font(.headline)
                            .foregroundColor(Color(hex: "EAEAEA"))
                            .padding(.leading, 5)
                        AnimatedOCRMock()
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Build a Global Library")
                            .font(.headline)
                            .foregroundColor(Color(hex: "EAEAEA"))
                            .padding(.leading, 5)
                        AnimatedLibraryMock()
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Access Anywhere")
                            .font(.headline)
                            .foregroundColor(Color(hex: "EAEAEA"))
                            .padding(.leading, 5)
                        // Placeholder for Hotkey
                        VStack(spacing: 15) {
                            Image(systemName: "keyboard.option")
                                .font(.system(size: 30))
                                .foregroundStyle(brandGradient)
                            Text("⌥ + Space")
                                .font(.system(.callout, design: .monospaced))
                                .padding(8)
                                .background(Color(hex: "2F2F2F"))
                                .cornerRadius(6)
                            
                            Text("Summon Omni from any app.")
                                .font(.caption)
                                .foregroundColor(Color(hex: "AAAAAA"))
                        }
                        .padding()
                        .frame(maxWidth: .infinity, minHeight: 120)
                        .background(Color(hex: "1A1A1A"))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "3A3A3A")))
                    }
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
    
    // --- Permissions Page (with "Wow" Animation) ---
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
             handleNext()
        }
        
        hasCompletedSetup = true
        
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.setupDidComplete()
        }
        
        NSApp.keyWindow?.close()
    }
}
