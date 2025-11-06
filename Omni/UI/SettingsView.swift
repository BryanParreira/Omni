import SwiftUI

// ===============================================
// HELPER VIEWS (Unchanged)
// ===============================================

struct StyledButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    var isDisabled: Bool = false
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(8)
                .opacity(isDisabled ? 0.5 : 1.0)
                .brightness(isHovered ? 0.1 : 0)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
    }
}

private func settingsCard<Content: View>(
    title: String,
    description: String,
    @ViewBuilder content: @escaping () -> Content
) -> some View {
    VStack(alignment: .leading, spacing: 12) {
        Text(title)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(Color(hex: "EAEAEA"))
        Text(description)
            .font(.system(size: 13))
            .foregroundColor(Color(hex: "AAAAAA"))
            .fixedSize(horizontal: false, vertical: true)
        
        content()
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(hex: "242424"))
    .cornerRadius(10)
    .overlay(
        RoundedRectangle(cornerRadius: 10)
            .stroke(Color(hex: "2F2F2F"), lineWidth: 1)
    )
}


// ===============================================
// MAIN SETTINGS VIEW
// ===============================================

struct SettingsView: View {
    // MARK: - AppStorage Properties
    @AppStorage("openai_api_key") private var openAIKey: String = ""
    @AppStorage("anthropic_api_key") private var anthropicKey: String = ""
    @AppStorage("gemini_api_key") private var geminiKey: String = ""
    @AppStorage("selected_provider") private var selectedProvider: String = "openai"
    @AppStorage("selected_model") private var selectedModel: String = "gpt-4o-mini"
    
    // MARK: - State Properties
    @State private var showAPIKey = false
    @State private var showSuccessMessage = false
    
    var body: some View {
        ZStack {
            // Main window background
            LinearGradient(
                colors: [Color(hex: "1A1A1A"), Color(hex: "1E1E1E")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Content area
            TabView {
                GeneralSettingsView()
                    .tabItem {
                        Label("General", systemImage: "switch.2")
                    }
                
                AISettingsView(
                    openAIKey: $openAIKey,
                    anthropicKey: $anthropicKey,
                    geminiKey: $geminiKey,
                    selectedProvider: $selectedProvider,
                    selectedModel: $selectedModel,
                    showAPIKey: $showAPIKey,
                    showSuccessMessage: $showSuccessMessage
                )
                .tabItem {
                    Label("AI", systemImage: "brain")
                }
                
                AboutView()
                    .tabItem {
                        Label("About", systemImage: "info.circle")
                    }
            }
            .background(Color(hex: "1A1A1A")) // Tab content background
            .accentColor(Color(hex: "FF6B6B")) // Tab bar accent
        }
        .navigationTitle("Settings") // This adds the title to the native bar
        
        // ===============================================
        // .clipShape() and .shadow() have been REMOVED
        // ===============================================
    }
}

// MARK: - General Settings Tab

struct GeneralSettingsView: View {
    @AppStorage("selected_search_scope") private var selectedSearchScope: String = "home"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                settingsCard(
                    title: "Search Scope",
                    description: "Choose which folders Omni should search. Limiting the scope can improve performance.",
                    content: {
                        Picker("Scope", selection: $selectedSearchScope) {
                            Text("Full Home Folder").tag("home")
                            Text("Documents Only").tag("documents")
                            Text("Desktop Only").tag("desktop")
                        }
                        .pickerStyle(.segmented)
                    }
                )
                
                settingsCard(
                    title: "Full Disk Access",
                    description: "Omni requires Full Disk Access to search your files. This is required for 'Full Home Folder' search.",
                    content: {
                        StyledButton(
                            title: "Open System Settings",
                            systemImage: "folder.badge.person.crop",
                            action: {
                                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                        )
                    }
                )
                
                settingsCard(
                    title: "Hotkey",
                    description: "Press Option + Space anywhere to show Omni.",
                    content: {
                        HStack {
                            Text("Global Hotkey:")
                                .foregroundColor(Color(hex: "AAAAAA"))
                            Spacer()
                            Text("⌥ Space")
                                .font(.system(.body, design: .monospaced))
                                .padding(6)
                                .background(Color(hex: "2A2A2A"))
                                .cornerRadius(6)
                                .foregroundColor(.white)
                        }
                    }
                )
            }
            .padding(20)
        }
        .background(Color(hex: "1A1A1A"))
    }
}

// MARK: - AI Settings Tab

struct AISettingsView: View {
    @Binding var openAIKey: String
    @Binding var anthropicKey: String
    @Binding var geminiKey: String
    @Binding var selectedProvider: String
    @Binding var selectedModel: String
    @Binding var showAPIKey: Bool
    @Binding var showSuccessMessage: Bool
    
    @State private var installedOllamaModels: [OllamaModel] = []
    @State private var ollamaError: String? = nil
    @State private var isTestingConnection = false
    @State private var testErrorMessage: String? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Provider Selection
                settingsCard(
                    title: "AI Provider",
                    description: "Choose your preferred AI model provider.",
                    content: {
                        Picker("Provider", selection: $selectedProvider) {
                            Text("OpenAI").tag("openai")
                            Text("Anthropic").tag("anthropic")
                            Text("Google").tag("gemini")
                            Text("Local LLM").tag("local")
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: selectedProvider) { newValue in
                            if newValue == "local" {
                                loadOllamaModels()
                            }
                            updateDefaultModel(for: newValue)
                        }
                    }
                )
                
                // Model Selection
                settingsCard(
                    title: "Model",
                    description: modelDescription,
                    content: {
                        HStack {
                            Text("Selected Model")
                                .foregroundColor(Color(hex: "AAAAAA"))
                            Spacer()
                            
                            if selectedProvider == "local" && !installedOllamaModels.isEmpty {
                                Picker("Model", selection: $selectedModel) {
                                    ForEach(installedOllamaModels) { model in
                                        Text(model.name).tag(model.name)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .tint(Color(hex: "EAEAEA"))
                            } else if selectedProvider == "local" {
                                Text(ollamaError ?? "Loading models...")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "8A8A8A"))
                            } else {
                                Picker("Model", selection: $selectedModel) {
                                    ForEach(availableModels, id: \.self) { model in
                                        Text(model).tag(model)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .tint(Color(hex: "EAEAEA"))
                            }
                        }
                    }
                )
                
                if selectedProvider != "local" {
                    apiKeySettings
                } else {
                    localLLMSettings
                }
            }
            .padding(20)
        }
        .background(Color(hex: "1A1A1A"))
        .onAppear {
            if selectedProvider == "local" {
                loadOllamaModels()
            }
        }
    }
    
    private func loadOllamaModels() {
        Task {
            do {
                let models = try await LocalLLMRunner.shared.fetchInstalledModels()
                
                await MainActor.run {
                    self.installedOllamaModels = models
                    if models.isEmpty {
                        self.ollamaError = "No models found. (Is Ollama running?)"
                    } else {
                        self.ollamaError = nil
                        if !models.contains(where: { $0.name == selectedModel }) {
                            selectedModel = models.first?.name ?? ""
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.ollamaError = "Failed to contact Ollama server. (Is it running?)"
                    self.installedOllamaModels = []
                }
            }
        }
    }
    
    @ViewBuilder
    private var apiKeySettings: some View {
        settingsCard(
            title: "\(providerName) API Key",
            description: "Get your API key from \(apiKeyURL)",
            content: {
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "key.fill")
                            .foregroundColor(Color(hex: "666666"))
                        
                        if showAPIKey {
                            TextField("Enter API key...", text: currentAPIKeyBinding)
                                .textFieldStyle(.plain)
                        } else {
                            SecureField("Enter API key...", text: currentAPIKeyBinding)
                                .textFieldStyle(.plain)
                        }
                        
                        Button(action: { showAPIKey.toggle() }) {
                            Image(systemName: showAPIKey ? "eye.slash" : "eye")
                                .foregroundColor(Color(hex: "8A8A8A"))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(hex: "242424"))
                    .cornerRadius(8)
                    
                    HStack {
                        if showSuccessMessage {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Connection successful!")
                            }
                            .font(.system(size: 12))
                            .transition(.opacity.combined(with: .scale))
                        } else if let testErrorMessage {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(testErrorMessage)
                            }
                            .font(.system(size: 12))
                            .transition(.opacity.combined(with: .scale))
                        }
                        
                        Spacer()
                        
                        if isTestingConnection {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 120, height: 29)
                        } else {
                            StyledButton(
                                title: "Test Connection",
                                systemImage: "bolt.fill",
                                action: testAPIKey,
                                isDisabled: currentAPIKey.isEmpty
                            )
                        }
                    }
                }
            }
        )
    }
    
    @ViewBuilder
    private var localLLMSettings: some View {
        settingsCard(
            title: "Ollama Configuration",
            description: "To use a local LLM, make sure the Ollama app is running on your Mac.",
            content: {
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Instructions:")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "AAAAAA"))
                        Text("1. Download and run the Ollama app.")
                        Text("2. Open Terminal and pull your desired models:")
                        Text("   • ollama pull \(selectedModel)")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8A8A8A"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider().background(Color(hex: "2F2F2F"))
                    
                    HStack {
                        Spacer()
                        StyledButton(
                            title: "Download Ollama",
                            systemImage: "icloud.and.arrow.down",
                            action: {
                                if let url = URL(string: "https://ollama.com/") {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                        )
                        Spacer()
                    }
                }
            }
        )
    }
    
    // MARK: - Helper Functions & Computed Properties
    
    private var availableModels: [String] {
        switch selectedProvider {
        case "openai":
            return ["gpt-4o", "gpt-4o-mini", "gpt-4-turbo", "gpt-3.5-turbo"]
        case "anthropic":
            return ["claude-3-5-sonnet-20241022", "claude-3-5-haiku-20241022", "claude-3-opus-20240229"]
        case "gemini":
            return ["gemini-2.0-flash-exp", "gemini-1.5-pro", "gemini-1.5-flash"]
        case "local":
            return installedOllamaModels.map { $0.name }
        default:
            return []
        }
    }
    
    private var modelDescription: String {
        switch selectedModel {
        case "gpt-4o":
            return "Most capable OpenAI model, great for complex tasks"
        case "gpt-4o-mini":
            return "Fast and affordable, perfect for most tasks"
        case "claude-3-5-sonnet-20241022":
            return "Anthropic's most intelligent model"
        // ... (other cases)
        default:
            if selectedProvider == "local" {
                return "Ollama model running locally on your Mac."
            }
            return "Please select a model."
        }
    }
    
    private var providerName: String {
        switch selectedProvider {
        case "openai": return "OpenAI"
        case "anthropic": return "Anthropic"
        case "gemini": return "Google"
        default: return ""
        }
    }
    
    private var apiKeyURL: String {
        switch selectedProvider {
        case "openai": return "platform.openai.com"
        case "anthropic": return "console.anthropic.com"
        case "gemini": return "aistudio.google.com"
        default: return ""
        }
    }
    
    private var currentAPIKey: String {
        switch selectedProvider {
        case "openai": return openAIKey
        case "anthropic": return anthropicKey
        case "gemini": return geminiKey
        default: return ""
        }
    }
    
    private var currentAPIKeyBinding: Binding<String> {
        switch selectedProvider {
        case "openai": return $openAIKey
        case "anthropic": return $anthropicKey
        case "gemini": return $geminiKey
        default: return .constant("")
        }
    }
    
    private func updateDefaultModel(for provider: String) {
        switch provider {
        case "openai":
            selectedModel = "gpt-4o-mini"
        case "anthropic":
            selectedModel = "claude-3-5-sonnet-20241022"
        case "gemini":
            selectedModel = "gemini-2.0-flash-exp"
        case "local":
            selectedModel = installedOllamaModels.first?.name ?? ""
        default:
            break
        }
    }
    
    private func testAPIKey() {
        Task {
            await MainActor.run {
                isTestingConnection = true
                testErrorMessage = nil
                showSuccessMessage = false
            }
            
            do {
                let url: URL
                let authHeader: String
                
                switch selectedProvider {
                case "openai":
                    url = URL(string: "https://api.openai.com/v1/models")!
                    authHeader = "Bearer \(openAIKey)"
                case "anthropic":
                    url = URL(string: "https://api.anthropic.com/v1/messages")!
                    authHeader = anthropicKey
                case "gemini":
                    url = URL(string: "https://generativelanguage.googleapis.com/v1/models?key=\(geminiKey)")!
                    authHeader = ""
                default: return
                }
                
                var request = URLRequest(url: url)
                if !authHeader.isEmpty {
                    if selectedProvider == "openai" {
                        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
                    } else if selectedProvider == "anthropic" {
                        request.setValue(authHeader, forHTTPHeaderField: "x-api-key")
                        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                    }
                }
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse,
                   (200...299).contains(httpResponse.statusCode) {
                    await MainActor.run {
                        withAnimation {
                            showSuccessMessage = true
                        }
                    }
                } else {
                    await MainActor.run {
                        withAnimation {
                            testErrorMessage = "Invalid API Key or server error."
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation {
                        testErrorMessage = "Connection failed. (Check network)"
                    }
                }
            }
            
            await MainActor.run {
                isTestingConnection = false
            }
        }
    }
}

// MARK: - About Tab

struct AboutView: View {
    
    private var appVersion: String {
        guard let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
              let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String else {
            return "1.0 (1)" // Fallback
        }
        return "Version \(version) (Build \(build))"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Omni")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color(hex: "EAEAEA"))
            
            Text("AI-Powered File Search")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "AAAAAA"))
            
            Text(appVersion)
                .font(.caption)
                .foregroundColor(Color(hex: "8A8A8A"))
            
            Divider()
                .background(Color(hex: "2F2F2F"))
                .padding(.horizontal, 50)
            
            VStack(spacing: 8) {
                Text("Ask natural language questions about your files.")
                Text("Powered by Core Spotlight and AI.")
            }
            .font(.subheadline)
            .foregroundColor(Color(hex: "AAAAAA"))
            .multilineTextAlignment(.center)
            
            Spacer()
            
            HStack(spacing: 20) {
                Link("Documentation", destination: URL(string: "https://github.com")!)
                Text("•")
                    .foregroundColor(Color(hex: "8A8A8A"))
                Link("Report Issue", destination: URL(string: "https://github.com")!)
            }
            .font(.caption)
            .accentColor(Color(hex: "FF6B6B")) // Use accent for links
            
        }
        .padding(40)
        .background(Color(hex: "1A1A1A"))
    }
}
