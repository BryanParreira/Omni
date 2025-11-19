import SwiftUI
import AppKit

// MARK: - Constants & Helper Views

private struct SettingsKeys {
    static let hasCompletedSetup = "hasCompletedSetup"
    static let selectedProviderType = "selected_provider" // "cloud" or "local"
    static let activeCloudProvider = "active_cloud_provider" // "openai", "anthropic", etc.
    static let openAIKey = "openai_api_key"
    static let anthropicKey = "anthropic_api_key"
    static let geminiKey = "gemini_api_key"
    static let selectedLocalModel = "selected_model"
}

private let brandGradient = LinearGradient(
    colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

// MARK: - Premium Button Styles

private struct PremiumPrimaryButton: ButtonStyle {
    var isDisabled: Bool = false
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .padding(.vertical, 14)
            .padding(.horizontal, 28)
            .background(
                ZStack {
                    brandGradient
                    if isHovered && !isDisabled {
                        Color.white.opacity(0.1)
                    }
                }
            )
            .cornerRadius(12)
            .shadow(color: isDisabled ? .clear : Color(hex: "FF6B6B").opacity(0.4), radius: 12, y: 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(isDisabled ? 0.5 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
    }
}

private struct PremiumSecondaryButton: ButtonStyle {
    var isDisabled: Bool = false
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(Color(hex: "EAEAEA"))
            .padding(.vertical, 14)
            .padding(.horizontal, 28)
            .background(Color(hex: "2A2A2A"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "3A3A3A"), lineWidth: 1)
            )
            .brightness(isHovered && !isDisabled ? 0.05 : 0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(isDisabled ? 0.5 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
    }
}

// MARK: - Premium AI Choice Card

private struct PremiumAICard: View {
    let title: String
    let subtitle: String
    let icon: String
    let features: [String]
    let limitations: [String]
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 18) {
                // Header
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(isSelected ? brandGradient : LinearGradient(colors: [Color(hex: "3A3A3A")], startPoint: .top, endPoint: .bottom))
                            .frame(width: 48, height: 48)
                            .shadow(color: isSelected ? Color(hex: "FF6B6B").opacity(0.4) : .clear, radius: 8)
                        
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "AAAAAA"))
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(brandGradient)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                
                Divider()
                    .background(Color(hex: "3A3A3A"))
                
                // Features
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(features, id: \.self) { feature in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                                .padding(.top, 2)
                            Text(feature)
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "EAEAEA"))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    ForEach(limitations, id: \.self) { limitation in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "FF8E53"))
                                .padding(.top, 2)
                            Text(limitation)
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "AAAAAA"))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(24)
            .background(Color(hex: "242424"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? brandGradient : LinearGradient(colors: [Color(hex: "3A3A3A")], startPoint: .top, endPoint: .bottom), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? Color(hex: "FF6B6B").opacity(0.2) : Color.black.opacity(0.1), radius: isSelected ? 16 : 8, y: isSelected ? 8 : 4)
            .brightness(isHovered && !isSelected ? 0.05 : 0)
            .scaleEffect(isHovered ? 1.01 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Permission Card

private struct PermissionCard: View {
    let title: String
    let description: String
    let icon: String
    let hasPermission: Bool
    let grantAction: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(hasPermission ? LinearGradient(colors: [.green.opacity(0.2)], startPoint: .top, endPoint: .bottom) : LinearGradient(colors: [Color(hex: "3A3A3A")], startPoint: .top, endPoint: .bottom))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(hasPermission ? .green : Color(hex: "AAAAAA"))
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "AAAAAA"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            // Status/Button
            if hasPermission {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Granted")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.green)
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                Button(action: grantAction) {
                    Text("Grant Access")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(brandGradient)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(Color(hex: "242424"))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(hasPermission ? Color.green.opacity(0.3) : Color(hex: "3A3A3A"), lineWidth: 1)
        )
        .brightness(isHovered ? 0.03 : 0)
        .animation(.easeInOut(duration: 0.2), value: hasPermission)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Animated Mock Views

private struct AnimatedChatMock: View {
    @State private var showFile = false
    @State private var showQuestion = false
    @State private var showLoading = false
    @State private var showAnswer = false
    @State private var resetAnimation = false
    
    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 14) {
                if showFile {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text.fill")
                            .foregroundStyle(brandGradient)
                        Text("Company_Report.pdf")
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                    }
                    .padding(10)
                    .background(Color(hex: "2A2A2A"))
                    .cornerRadius(8)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }
                
                if showQuestion {
                    Text("What's the main takeaway?")
                        .font(.system(size: 13))
                        .padding(12)
                        .background(Color(hex: "3A3A3A"))
                        .cornerRadius(12)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
                
                if showLoading {
                    HStack(spacing: 5) {
                        ForEach(0..<3) { i in
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundColor(Color(hex: "FF6B6B"))
                                .opacity(0.6)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
                }
                
                if showAnswer {
                    Text("The main takeaway is a 20% increase in Q4 revenue, driven by new market expansion.")
                        .font(.system(size: 13))
                        .padding(12)
                        .background(Color(hex: "2A2A2A"))
                        .cornerRadius(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
                Spacer()
            }
            .padding(16)
        }
        .frame(width: 450, height: 220)
        .background(Color(hex: "1A1A1A"))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "3A3A3A"), lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        .onAppear { startAnimation() }
        .onChange(of: resetAnimation) { _, _ in startAnimation() }
    }
    
    func startAnimation() {
        showFile = false
        showQuestion = false
        showLoading = false
        showAnswer = false
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5)) { showFile = true }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(1.5)) { showQuestion = true }
        withAnimation(.easeInOut.delay(2.5)) { showLoading = true }
        withAnimation(.easeInOut.delay(3.5)) {
            showLoading = false
            showAnswer = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            resetAnimation.toggle()
        }
    }
}

private struct FeatureShowcaseCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: "FF6B6B").opacity(0.2), Color(hex: "FF8E53").opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 64, height: 64)
                
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(brandGradient)
            }
            
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "AAAAAA"))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "242424"))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "3A3A3A"), lineWidth: 1))
    }
}

// MARK: - Main Setup View

struct SetupView: View {
    @AppStorage(SettingsKeys.hasCompletedSetup) var hasCompletedSetup: Bool = false
    @AppStorage(SettingsKeys.openAIKey) private var openAIKey: String = ""
    @AppStorage(SettingsKeys.anthropicKey) private var anthropicKey: String = ""
    @AppStorage(SettingsKeys.geminiKey) private var geminiKey: String = ""
    
    // We store "cloud" or "local" here
    @AppStorage(SettingsKeys.selectedProviderType) private var selectedProvider: String = "cloud"
    // We store the active cloud provider (openai, anthropic, etc) here
    @AppStorage(SettingsKeys.activeCloudProvider) private var activeCloudProvider: String = "openai"
    @AppStorage(SettingsKeys.selectedLocalModel) private var selectedOllamaModel: String = ""
    
    @State private var currentPage = 1
    @State private var showingAccessibilityAlert = false
    @State private var showingFullDiskAlert = false
    @State private var cloudProviderSelection: String = "openai" // Temporary state
    @State private var currentApiKey: String = ""
    @State private var hasAccessibilityPermission: Bool = false
    @State private var hasGrantedFullDiskAccess: Bool = false
    @State private var ollamaModels: [OllamaModel] = []
    @State private var ollamaFetchError: String? = nil
    @State private var isFetchingModels: Bool = false
    
    // Timer to check permissions
    let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color(hex: "1A1A1A").ignoresSafeArea()
            
            VStack(spacing: 0) {
                setupHeader
                
                TabView(selection: $currentPage) {
                    welcomePage.tag(1)
                    featuresPage.tag(2)
                    aiSetupPage.tag(3)
                    permissionsPage.tag(4)
                }
                .tabViewStyle(.automatic)
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                setupFooter
            }
        }
        .frame(width: 800, height: 700)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.5), radius: 30, y: 20)
        .alert("Grant Accessibility Access", isPresented: $showingAccessibilityAlert) {
            Button("I've Granted Access") {
                hasAccessibilityPermission = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please grant Omni 'Accessibility' permission in System Settings, then click 'I've Granted Access' below.")
        }
        .alert("Grant Full Disk Access", isPresented: $showingFullDiskAlert) {
            Button("I've Granted Access") {
                hasGrantedFullDiskAccess = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please grant Omni 'Full Disk Access' in System Settings to enable file analysis, then click 'I've Granted Access' below.")
        }
        .onReceive(timer) { _ in
            if currentPage == 4 {
                checkAllPermissions()
            }
        }
    }
    
    // MARK: - Header & Footer
    
    private var setupHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(brandGradient)
                        .frame(width: 40, height: 40)
                        .shadow(color: Color(hex: "FF6B6B").opacity(0.4), radius: 8)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text("Omni Setup")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 8) {
                    ForEach(1...4, id: \.self) { step in
                        Circle()
                            .fill(step <= currentPage ? brandGradient : LinearGradient(colors: [Color(hex: "3A3A3A")], startPoint: .top, endPoint: .bottom))
                            .frame(width: 8, height: 8)
                            .shadow(color: step <= currentPage ? Color(hex: "FF6B6B").opacity(0.4) : .clear, radius: 4)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(hex: "2A2A2A"))
                        .frame(height: 4)
                    
                    Capsule()
                        .fill(brandGradient)
                        .frame(width: geometry.size.width * CGFloat(currentPage) / 4, height: 4)
                        .shadow(color: Color(hex: "FF6B6B").opacity(0.6), radius: 6)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentPage)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 32)
            .padding(.bottom, 20)
        }
        .background(Color(hex: "1F1F1F"))
    }
    
    private var setupFooter: some View {
        HStack(spacing: 16) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    currentPage -= 1
                }
            }) {
                Label("Back", systemImage: "chevron.left")
            }
            .buttonStyle(PremiumSecondaryButton(isDisabled: currentPage == 1))
            .disabled(currentPage == 1)
            
            Spacer()
            
            let isPage3CloudDisabled = (currentPage == 3 && selectedProvider == "cloud" && currentApiKey.isEmpty)
            let isPage3LocalDisabled = (currentPage == 3 && selectedProvider == "local" && selectedOllamaModel.isEmpty)
            let isPage4Disabled = (currentPage == 4 && (!hasAccessibilityPermission || !hasGrantedFullDiskAccess))
            let isDisabled = isPage3CloudDisabled || isPage3LocalDisabled || isPage4Disabled
            
            if currentPage < 4 {
                Button(action: {
                    handleNext()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        currentPage += 1
                    }
                }) {
                    Label("Next", systemImage: "chevron.right")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(PremiumPrimaryButton(isDisabled: isDisabled))
                .disabled(isDisabled)
            } else {
                Button(action: completeSetup) {
                    Label("Get Started", systemImage: "sparkles")
                }
                .buttonStyle(PremiumPrimaryButton(isDisabled: isDisabled))
                .disabled(isDisabled)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
        .background(Color(hex: "1F1F1F"))
    }
    
    // MARK: - Pages
    
    private var welcomePage: some View {
        ScrollView {
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 16) {
                    Text("Welcome to Omni")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(hex: "EAEAEA")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    Text("Your AI-powered file assistant")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "AAAAAA"))
                }
                
                AnimatedChatMock()
                
                Text("Turn your files into instant answers")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "8A8A8A"))
                
                Spacer()
            }
            .padding(40)
        }
    }
    
    private var featuresPage: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    Text("Powerful Features")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Everything you need for intelligent file management")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "AAAAAA"))
                }
                .padding(.top, 20)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    FeatureShowcaseCard(
                        icon: "globe",
                        title: "Web Analysis",
                        description: "Extract and analyze content from any webpage"
                    )
                    FeatureShowcaseCard(
                        icon: "doc.text.viewfinder",
                        title: "Smart OCR",
                        description: "Read and index text from images instantly"
                    )
                    FeatureShowcaseCard(
                        icon: "folder.fill.badge.gearshape",
                        title: "Global Library",
                        description: "Access your key files in any conversation"
                    )
                    FeatureShowcaseCard(
                        icon: "command",
                        title: "Quick Access",
                        description: "⌥ + Space to summon from anywhere"
                    )
                    FeatureShowcaseCard(
                        icon: "questionmark.diamond.fill",
                        title: "AI Quiz Generator",
                        description: "Turn any document into an interactive practice test."
                    )
                    FeatureShowcaseCard(
                        icon: "calendar.day.timeline.leading",
                        title: "Project Timelines",
                        description: "Instantly create a chronological history from files."
                    )
                }
            }
            .padding(32)
        }
    }
    
    private var aiSetupPage: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text("Choose Your AI")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Select between powerful cloud models or private local processing")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "AAAAAA"))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                PremiumAICard(
                    title: "Cloud AI",
                    subtitle: "Recommended for best results",
                    icon: "cloud.fill",
                    features: [
                        "Most powerful models (GPT-4o, Claude 3.5 Sonnet)",
                        "No local setup required",
                        "Always up-to-date"
                    ],
                    limitations: [
                        "Requires internet connection",
                        "Usage costs apply"
                    ],
                    isSelected: selectedProvider == "cloud"
                ) {
                    selectedProvider = "cloud"
                    currentApiKey = ""
                }
                
                if selectedProvider == "cloud" {
                    cloudProviderSetup
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                PremiumAICard(
                    title: "Local AI",
                    subtitle: "Privacy-focused processing",
                    icon: "lock.shield.fill",
                    features: [
                        "100% private and offline",
                        "No API costs",
                        "Your data never leaves your Mac"
                    ],
                    limitations: [
                        "Requires Ollama installation",
                        "Less powerful than cloud models"
                    ],
                    isSelected: selectedProvider == "local"
                ) {
                    selectedProvider = "local"
                    currentApiKey = ""
                    fetchOllamaModels()
                }
                
                if selectedProvider == "local" {
                    localProviderSetup
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(32)
        }
    }
    
    private var cloudProviderSetup: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Cloud Provider")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Picker("Provider", selection: $cloudProviderSelection) {
                Text("OpenAI").tag("openai")
                Text("Anthropic").tag("anthropic")
                Text("Google").tag("gemini")
            }
            .pickerStyle(.segmented)
            .onChange(of: cloudProviderSelection) { _, _ in currentApiKey = "" }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("API Key")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "AAAAAA"))
                
                HStack(spacing: 10) {
                    Image(systemName: "key.fill")
                        .foregroundColor(Color(hex: "666666"))
                        .font(.system(size: 14))
                    
                    SecureField(apiKeyPlaceholder, text: $currentApiKey)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, design: .monospaced))
                }
                .padding(12)
                .background(Color(hex: "1F1F1F"))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(hex: "3A3A3A"), lineWidth: 1)
                )
            }
            
            Link(destination: apiKeyURL) {
                HStack(spacing: 6) {
                    Text("Get your API key")
                        .font(.system(size: 13))
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11))
                }
                .foregroundStyle(brandGradient)
            }
        }
        .padding(20)
        .background(Color(hex: "242424"))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: "3A3A3A"), lineWidth: 1)
        )
    }
    
    private var localProviderSetup: some View {
        VStack(alignment: .leading, spacing: 20) {
            if isFetchingModels {
                HStack(spacing: 12) {
                    ProgressView().scaleEffect(0.8)
                    Text("Searching for models...")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "AAAAAA"))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
            } else if let error = ollamaFetchError {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(Color(hex: "FF8E53"))
                    
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "AAAAAA"))
                        .multilineTextAlignment(.center)
                    
                    Link(destination: URL(string: "https://ollama.com/download")!) {
                        Text("Download Ollama")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(brandGradient)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else if ollamaModels.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundColor(Color(hex: "666666"))
                    
                    Text("No models found")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "AAAAAA"))
                    
                    Text("Install a model using Terminal:")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "8A8A8A"))
                    
                    Text("ollama pull llama3")
                        .font(.system(size: 13, design: .monospaced))
                        .padding(10)
                        .background(Color(hex: "1F1F1F"))
                        .cornerRadius(8)
                        .foregroundColor(Color(hex: "FF8E53"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Select Model")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Menu {
                        ForEach(ollamaModels, id: \.name) { model in
                            Button(model.name) {
                                selectedOllamaModel = model.name
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "cpu")
                                .foregroundColor(Color(hex: "666666"))
                            
                            Text(selectedOllamaModel.isEmpty ? "Choose a model..." : selectedOllamaModel)
                                .font(.system(size: 13))
                                .foregroundColor(selectedOllamaModel.isEmpty ? Color(hex: "666666") : .white)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "666666"))
                        }
                        .padding(12)
                        .background(Color(hex: "1F1F1F"))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(hex: "3A3A3A"), lineWidth: 1)
                        )
                    }
                    .menuStyle(.borderlessButton)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 12))
                        Text("\(ollamaModels.count) model(s) available")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "AAAAAA"))
                    }
                }
            }
        }
        .padding(20)
        .background(Color(hex: "242424"))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: "3A3A3A"), lineWidth: 1)
        )
        .onAppear {
            fetchOllamaModels()
        }
    }
    
    private var permissionsPage: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    Text("Grant Permissions")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Two quick steps to unlock Omni's full potential")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "AAAAAA"))
                }
                .padding(.top, 20)
                
                VStack(spacing: 16) {
                    PermissionCard(
                        title: "Accessibility Access",
                        description: "Allows Omni to capture text with your hotkey (⌥ + Space)",
                        icon: "hand.point.up.braille.fill",
                        hasPermission: hasAccessibilityPermission,
                        grantAction: {
                            openAccessibilitySettings()
                            showingAccessibilityAlert = true
                        }
                    )
                    
                    PermissionCard(
                        title: "Full Disk Access",
                        description: "Required to search and index your local files",
                        icon: "folder.fill.badge.gearshape",
                        hasPermission: hasGrantedFullDiskAccess,
                        grantAction: {
                            openFullDiskAccessSettings()
                            showingFullDiskAlert = true
                        }
                    )
                }
                
                // Info box
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(brandGradient)
                        
                        Text("Your Privacy Matters")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    
                    Text("All file processing happens locally on your Mac. Your data never leaves your device unless you explicitly use cloud AI features.")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "AAAAAA"))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "FF6B6B").opacity(0.1), Color(hex: "FF8E53").opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(brandGradient.opacity(0.3), lineWidth: 1)
                )
            }
            .padding(32)
        }
        .onAppear {
            checkAllPermissions()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
            checkAllPermissions()
        }
    }
    
    // MARK: - Helper Functions
    
    private func checkAllPermissions() {
        // Use native macOS accessibility check
        self.hasAccessibilityPermission = AXIsProcessTrusted()
        
        // We cannot check Full Disk Access programmatically without attempting file I/O.
        // For the setup UI, if they clicked the button, we assume they did it.
        // In production, you would try to read a file to verify.
    }
    
    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func openFullDiskAccessSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func fetchOllamaModels() {
        guard !isFetchingModels else { return }
        isFetchingModels = true
        ollamaFetchError = nil
        
        Task {
            do {
                // Assuming LocalLLMRunner is available in your project
                let models = try await LocalLLMRunner.shared.fetchInstalledModels()
                
                await MainActor.run {
                    self.ollamaModels = models
                    self.isFetchingModels = false
                    
                    let savedModel = UserDefaults.standard.string(forKey: SettingsKeys.selectedLocalModel) ?? ""
                    if models.first(where: { $0.name == savedModel }) != nil {
                        self.selectedOllamaModel = savedModel
                    } else if let firstModel = models.first {
                        self.selectedOllamaModel = firstModel.name
                    } else {
                        self.selectedOllamaModel = ""
                    }
                }
            } catch {
                await MainActor.run {
                    self.ollamaFetchError = "Could not connect to Ollama. Is it running?"
                    self.isFetchingModels = false
                    self.ollamaModels = []
                }
            }
        }
    }
    
    private var apiKeyURL: URL {
        switch cloudProviderSelection {
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
        switch cloudProviderSelection {
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
            if selectedProvider == "cloud" {
                // Save specific key based on selection
                switch cloudProviderSelection {
                case "openai":
                    openAIKey = currentApiKey
                case "anthropic":
                    anthropicKey = currentApiKey
                case "gemini":
                    geminiKey = currentApiKey
                default:
                    break
                }
                
                // IMPORTANT FIX:
                // 1. Set the general provider type to "cloud"
                UserDefaults.standard.set("cloud", forKey: SettingsKeys.selectedProviderType)
                // 2. Set the SPECIFIC cloud provider (openai/anthropic/gemini)
                UserDefaults.standard.set(cloudProviderSelection, forKey: SettingsKeys.activeCloudProvider)
                
            } else {
                // Local Logic
                UserDefaults.standard.set("local", forKey: SettingsKeys.selectedProviderType)
                UserDefaults.standard.set(selectedOllamaModel, forKey: SettingsKeys.selectedLocalModel)
            }
        }
    }
    
    private func completeSetup() {
        // 1. PERMANENTLY SAVE THE FLAG
        UserDefaults.standard.set(true, forKey: SettingsKeys.hasCompletedSetup)
        
        // 2. Notify AppDelegate to switch modes
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.setupDidComplete()
            appDelegate.closeSetupWindow()
        }
    }
}
