import SwiftUI
import AppKit

// MARK: - Constants & Helper Views

private struct SettingsKeys {
    static let hasCompletedSetup = "hasCompletedSetup"
    static let selectedProvider = "selected_provider"
    static let openAIKey = "openai_api_key"
    static let anthropicKey = "anthropic_api_key"
    static let geminiKey = "gemini_api_key"
    
    // *** NEW ***
    // Add the key for the selected local model
    static let selectedLocalModel = "selected_model"
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

// Helper View for Permission Rows
private struct PermissionRow: View {
    let title: String
    let description: String
    let icon: String
    let hasPermission: Bool
    let grantAction: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(brandGradient)
                .frame(width: 30)
                .padding(.top, 3)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "AAAAAA"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            if hasPermission {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.green)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Button("Grant", action: grantAction)
                    .buttonStyle(SecondaryButtonStyle())
            }
        }
        .animation(.easeInOut(duration: 0.3), value: hasPermission)
    }
}

// MARK: - Animated Mock Views
// ... (All Animated Mock Views are unchanged) ...
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
    
    // *** NEW ***
    // Use @AppStorage to bind directly to the saved model in UserDefaults
    @AppStorage(SettingsKeys.selectedLocalModel) private var selectedOllamaModel: String = ""
    
    @State private var currentPage = 1
    @State private var showingSettingsAlert = false
    
    @State private var cloudProvider: String = "openai"
    @State private var currentApiKey: String = ""
    
    @State private var hasAccessibilityPermission: Bool = false
    @State private var hasGrantedFullDiskAccess: Bool = false // This is a proxy
    
    // *** NEW *** State for Ollama model list
    @State private var ollamaModels: [OllamaModel] = []
    @State private var ollamaFetchError: String? = nil
    @State private var isFetchingModels: Bool = false
    
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
        .alert("Grant Full Disk Access", isPresented: $showingSettingsAlert) {
            Button("Got It") {
                // Assume the user did it to enable the Finish button.
                hasGrantedFullDiskAccess = true
            }
        } message: {
            Text("Please grant Omni 'Full Disk Access' in System Settings to enable file analysis. You may need to drag Omni into the list manually.")
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
            
            // --- *** UPDATED *** Disability Logic ---
            let isPage3CloudDisabled = (currentPage == 3 && selectedProvider == "cloud" && currentApiKey.isEmpty)
            // Disable if local is selected but no model is chosen
            let isPage3LocalDisabled = (currentPage == 3 && selectedProvider == "local" && selectedOllamaModel.isEmpty)
            let isPage4Disabled = (currentPage == 4 && (!hasAccessibilityPermission || !hasGrantedFullDiskAccess))
            
            let isDisabled = isPage3CloudDisabled || isPage3LocalDisabled || isPage4Disabled
            // --- End Update ---
            
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
                .buttonStyle(PrimaryButtonStyle(isDisabled: isDisabled))
                .disabled(isDisabled)
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
            
            AnimatedChatMock()
            
            Spacer()
        }
        .padding(40)
    }
    
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
                    // *** NEW *** Fetch models when user clicks
                    fetchOllamaModels()
                }
                
                if selectedProvider == "local" {
                    localProviderSetup // This view is now updated
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
    
    // --- *** UPDATED *** localProviderSetup ---
    private var localProviderSetup: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Ollama Configuration:")
                .font(.headline)
                .foregroundColor(Color(hex: "EAEAEA"))
            
            // --- *** NEW *** Model Picker Section ---
            VStack(alignment: .leading, spacing: 10) {
                Text("Select Installed Model:")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "EAEAEA"))

                if isFetchingModels {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Fetching models...")
                            .font(.caption)
                            .foregroundColor(Color(hex: "AAAAAA"))
                    }
                } else if let error = ollamaFetchError {
                    Text("Error: \(error)")
                        .font(.caption)
                        .foregroundColor(.red)
                } else if ollamaModels.isEmpty {
                    Text("No models found. Make sure Ollama is running and you have downloaded a model (e.g., `ollama run llama3.1`).")
                        .font(.caption)
                        .foregroundColor(Color(hex: "AAAAAA"))
                } else {
                    // We have models, show the picker
                    Picker("Model", selection: $selectedOllamaModel) {
                        Text("Select a model...").tag("")
                        ForEach(ollamaModels, id: \.name) { model in
                            Text(model.name).tag(model.name)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    // No need for .onChange, @AppStorage handles saving
                }
            }
            .padding(.bottom, 10)
            // --- End Model Picker Section ---

            Text("How to get more models:")
                .font(.subheadline)
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
            }
            .font(.subheadline)
            .foregroundColor(Color(hex: "AAAAAA"))
        }
        .padding(25)
        .background(Color(hex: "242424"))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
        .onAppear {
            // Fetch models when this view appears
            fetchOllamaModels()
        }
    }
    
    // --- *** UPDATED *** Permissions Page ---
    private var permissionsPage: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Grant Permissions")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Omni needs two key permissions to unlock its full potential. Your data **never** leaves your Mac.")
                .font(.title3)
                .foregroundColor(Color(hex: "AAAAAA"))
                .padding(.bottom, 10)
            
            // --- Visual Guide ---
            VStack(alignment: .leading, spacing: 25) { // Added more spacing
                
                // --- 1. ACCESSIBILITY PERMISSION ROW ---
                PermissionRow(
                    title: "Accessibility",
                    description: "Required to capture selected text with your hotkey (Cmd+Opt+X).",
                    icon: "hand.cursor.fill",
                    hasPermission: hasAccessibilityPermission,
                    grantAction: {
                        PermissionsHelper.requestAccessibilityPermission()
                        // Re-check permission after a moment
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            checkAllPermissions()
                        }
                    }
                )
                
                Divider().background(Color(hex: "3A3A3A"))
                
                // --- 2. FULL DISK ACCESS ROW ---
                PermissionRow(
                    title: "Full Disk Access",
                    description: "Required to find, read, and index your local files for analysis.",
                    icon: "folder.fill.badge.person.crop",
                    hasPermission: hasGrantedFullDiskAccess,
                    grantAction: {
                        openFullDiskAccessSettings()
                        showingSettingsAlert = true
                    }
                )
            }
            .padding(25)
            .background(Color(hex: "242424"))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
            
            // --- Animated Mock ---
            Text("How to Grant Access")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top, 10)
            
            Text("1. Click \"Grant\" to open System Settings.\n2. Find Omni in the list.\n3. Turn the toggle ON.")
                .font(.subheadline)
                .foregroundColor(Color(hex: "AAAAAA"))
                .fixedSize(horizontal: false, vertical: true)
            
            MockSettingsToggleView()
                .frame(maxWidth: .infinity, alignment: .center)
            
            Spacer()
        }
        .padding(40)
        .onAppear {
            // Check permissions every time this page appears
            checkAllPermissions()
        }
        // Re-check when the app becomes active, in case the user
        // comes back from System Settings
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
            checkAllPermissions()
        }
    }
    
    // MARK: - Helper Functions
    
    // *** NEW *** Checks all required permissions
    private func checkAllPermissions() {
        self.hasAccessibilityPermission = PermissionsHelper.checkAccessibilityPermission()
        // We can't *programmatically* check Full Disk Access.
        // We set `hasGrantedFullDiskAccess` to true when the user
        // dismisses the "Got It" alert.
    }
    
    // *** NEW *** Function to fetch Ollama models
    private func fetchOllamaModels() {
        guard !isFetchingModels else { return }
        print("Fetching Ollama models...")
        isFetchingModels = true
        ollamaFetchError = nil
        
        Task {
            do {
                let models = try await LocalLLMRunner.shared.fetchInstalledModels()
                
                await MainActor.run {
                    self.ollamaModels = models
                    self.isFetchingModels = false
                    print("Found models: \(models.map { $0.name })")
                    
                    // Set the picker to the saved value, if it exists in the list
                    let savedModel = UserDefaults.standard.string(forKey: SettingsKeys.selectedLocalModel) ?? ""
                    if models.first(where: { $0.name == savedModel }) != nil {
                        self.selectedOllamaModel = savedModel
                    } else if let firstModel = models.first {
                        // If no valid model is saved, select the first one
                        self.selectedOllamaModel = firstModel.name
                    } else {
                        self.selectedOllamaModel = "" // No models installed
                    }
                }
            } catch {
                await MainActor.run {
                    print("Error fetching models: \(error.localizedDescription)")
                    self.ollamaFetchError = "Could not connect to Ollama. Is it running?"
                    self.isFetchingModels = false
                    self.ollamaModels = []
                }
            }
        }
    }
    
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
                // Save local provider and the selected model
                UserDefaults.standard.set("local", forKey: SettingsKeys.selectedProvider)
                // @AppStorage already saved the model, but this is good for clarity.
                UserDefaults.standard.set(selectedOllamaModel, forKey: SettingsKeys.selectedLocalModel)
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
        // 1. You set the flag (perfect!)
        hasCompletedSetup = true
        
        // 2. You find the AppDelegate (perfect!)
        if let appDelegate = NSApp.delegate as? AppDelegate {
            // 3. You call the correct function (perfect!)
            appDelegate.setupDidComplete()
        }
        
        // 4. You close this window (perfect!)
        (NSApp.delegate as? AppDelegate)?.closeSetupWindow()
    }
}
