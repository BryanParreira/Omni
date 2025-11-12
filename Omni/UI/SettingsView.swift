import SwiftUI
import AppKit
import SwiftData

// ===============================================
// HELPER VIEWS
// ===============================================

struct StyledButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    var isDisabled: Bool = false
    var style: ButtonStyleType = .primary
    
    enum ButtonStyleType {
        case primary
        case secondary
    }
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(style == .primary ? .white : Color(hex: "EAEAEA"))
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    Group {
                        if style == .primary {
                            LinearGradient(
                                colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            Color(hex: "252525")
                        }
                    }
                )
                .cornerRadius(7)
                .opacity(isDisabled ? 0.5 : 1.0)
                .brightness(isHovered && !isDisabled ? 0.1 : 0)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

private func settingsCard<Content: View>(
    title: String,
    description: String,
    icon: String? = nil,
    @ViewBuilder content: @escaping () -> Content
) -> some View {
    VStack(alignment: .leading, spacing: 14) {
        HStack(spacing: 10) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "FF6B6B"))
                    .frame(width: 28, height: 28)
                    .background(Color(hex: "FF6B6B").opacity(0.12))
                    .cornerRadius(6)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "EAEAEA"))
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "888888"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        
        content()
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(hex: "222222"))
    .cornerRadius(10)
    .overlay(
        RoundedRectangle(cornerRadius: 10)
            .stroke(Color(hex: "2A2A2A"), lineWidth: 1)
    )
}

// ===============================================
// CUSTOM TAB BAR
// ===============================================

private struct CustomTabBar: View {
    @Binding var selection: SettingsTab
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(SettingsTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        selection = tab
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 13, weight: .medium))
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(selection == tab ? Color(hex: "EAEAEA") : Color(hex: "888888"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(selection == tab ? Color(hex: "2A2A2A") : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(hex: "1E1E1E"))
        .cornerRadius(8)
    }
}

// ===============================================
// MAIN SETTINGS VIEW
// ===============================================

private enum SettingsTab: String, CaseIterable {
    case general = "General"
    case ai = "AI"
    case library = "Library"
    case about = "About"
    
    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .ai: return "brain.head.profile"
        case .library: return "folder"
        case .about: return "info.circle"
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - AppStorage Properties
    @AppStorage("openai_api_key") private var openAIKey: String = ""
    @AppStorage("anthropic_api_key") private var anthropicKey: String = ""
    @AppStorage("gemini_api_key") private var geminiKey: String = ""
    @AppStorage("selected_provider") private var selectedProvider: String = "openai"
    @AppStorage("selected_model") private var selectedModel: String = "gpt-4o-mini"
    
    // MARK: - State Properties
    @State private var showAPIKey = false
    @State private var showSuccessMessage = false
    @State private var currentTab: SettingsTab = .general
    
    var body: some View {
        VStack(spacing: 0) {
            // Clean header
            HStack {
                Text("Settings")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "666666"))
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color(hex: "252525"))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .background(Color(hex: "1A1A1A"))
            
            Rectangle()
                .fill(Color(hex: "2A2A2A"))
                .frame(height: 1)
            
            // Tab Bar
            CustomTabBar(selection: $currentTab)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 16)
                .background(Color(hex: "1A1A1A"))

            // Content
            ZStack {
                Color(hex: "1A1A1A")
                
                Group {
                    switch currentTab {
                    case .general:
                        GeneralSettingsView()
                    case .ai:
                        AISettingsView(
                            openAIKey: $openAIKey,
                            anthropicKey: $anthropicKey,
                            geminiKey: $geminiKey,
                            selectedProvider: $selectedProvider,
                            selectedModel: $selectedModel,
                            showAPIKey: $showAPIKey,
                            showSuccessMessage: $showSuccessMessage
                        )
                    case .library:
                        LibrarySettingsView()
                    case .about:
                        AboutView()
                    }
                }
                .transition(.opacity)
            }
        }
        .background(Color(hex: "1A1A1A"))
        .frame(width: 680, height: 560)
    }
}

// MARK: - General Settings Tab

struct GeneralSettingsView: View {
    @AppStorage("selected_search_scope") private var selectedSearchScope: String = "home"
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                
                settingsCard(
                    title: "Search Scope",
                    description: "Choose which folders Omni should search",
                    icon: "folder.badge.gearshape",
                    content: {
                        VStack(spacing: 8) {
                            ForEach([("home", "Full Home Folder", "Search all accessible files"),
                                     ("documents", "Documents Only", "Faster, focused search"),
                                     ("desktop", "Desktop Only", "Desktop files only")], id: \.0) { scope in
                                RadioButton(
                                    title: scope.1,
                                    subtitle: scope.2,
                                    isSelected: selectedSearchScope == scope.0,
                                    action: { selectedSearchScope = scope.0 }
                                )
                            }
                        }
                    }
                )
                
                settingsCard(
                    title: "Full Disk Access",
                    description: "Required for 'Full Home Folder' search",
                    icon: "lock.shield",
                    content: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Grant Omni access to your files")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "AAAAAA"))
                                Text("Ensures comprehensive search")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: "666666"))
                            }
                            
                            Spacer()
                            
                            StyledButton(
                                title: "Open Settings",
                                systemImage: "arrow.up.forward.app",
                                action: {
                                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
                                        NSWorkspace.shared.open(url)
                                    }
                                },
                                style: .secondary
                            )
                        }
                    }
                )
                
                settingsCard(
                    title: "Global Hotkey",
                    description: "Quick access from anywhere",
                    icon: "command",
                    content: {
                        HStack(spacing: 12) {
                            HStack(spacing: 6) {
                                Text("⌥")
                                    .font(.system(size: 16, weight: .medium))
                                Text("+")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(hex: "666666"))
                                Text("Space")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(Color(hex: "EAEAEA"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(hex: "2A2A2A"))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(hex: "333333"), lineWidth: 1)
                            )
                            
                            Spacer()
                            
                            Text("Press to show Omni")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "777777"))
                        }
                    }
                )
            }
            .padding(24)
        }
    }
}

struct RadioButton: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color(hex: "FF6B6B") : Color(hex: "3A3A3A"), lineWidth: 2)
                        .frame(width: 16, height: 16)
                    
                    if isSelected {
                        Circle()
                            .fill(Color(hex: "FF6B6B"))
                            .frame(width: 8, height: 8)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "EAEAEA"))
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "777777"))
                }
                
                Spacer()
            }
            .padding(10)
            .background(isSelected ? Color(hex: "252525") : Color(hex: "1E1E1E"))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color(hex: "FF6B6B").opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .brightness(isHovered ? 0.05 : 0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                // Provider Selection
                settingsCard(
                    title: "AI Provider",
                    description: "Choose your preferred AI service",
                    icon: "cpu",
                    content: {
                        VStack(spacing: 6) {
                            ForEach([("openai", "OpenAI", "sparkles"),
                                     ("anthropic", "Anthropic", "brain"),
                                     ("gemini", "Google", "globe"),
                                     ("local", "Local LLM", "desktopcomputer")], id: \.0) { provider in
                                ProviderButton(
                                    title: provider.1,
                                    icon: provider.2,
                                    isSelected: selectedProvider == provider.0,
                                    action: {
                                        selectedProvider = provider.0
                                        if provider.0 == "local" {
                                            loadOllamaModels()
                                        }
                                        updateDefaultModel(for: provider.0)
                                    }
                                )
                            }
                        }
                    }
                )
                
                // Model Selection
                if selectedProvider != "local" || !installedOllamaModels.isEmpty {
                    settingsCard(
                        title: "Model Selection",
                        description: modelDescription,
                        icon: "slider.horizontal.3",
                        content: {
                            HStack {
                                Text("Active Model")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "AAAAAA"))
                                
                                Spacer()
                                
                                Menu {
                                    ForEach(availableModels, id: \.self) { model in
                                        Button(model) {
                                            selectedModel = model
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(selectedModel)
                                            .font(.system(size: 12, weight: .medium))
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 9))
                                    }
                                    .foregroundColor(Color(hex: "EAEAEA"))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: "2A2A2A"))
                                    .cornerRadius(6)
                                }
                                .menuIndicator(.hidden)
                                .menuStyle(.borderlessButton)
                            }
                        }
                    )
                }
                
                if selectedProvider != "local" {
                    apiKeySettings
                } else {
                    localLLMSettings
                }
            }
            .padding(24)
        }
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
                        self.ollamaError = "No models found"
                    } else {
                        self.ollamaError = nil
                        if !models.contains(where: { $0.name == selectedModel }) {
                            selectedModel = models.first?.name ?? ""
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.ollamaError = "Failed to connect"
                    self.installedOllamaModels = []
                }
            }
        }
    }
    
    @ViewBuilder
    private var apiKeySettings: some View {
        settingsCard(
            title: "\(providerName) API Key",
            description: "Securely stored in your system keychain",
            icon: "key.fill",
            content: {
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(Color(hex: "666666"))
                            .font(.system(size: 11))
                        
                        if showAPIKey {
                            TextField("sk-...", text: currentAPIKeyBinding)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12, design: .monospaced))
                        } else {
                            SecureField("sk-...", text: currentAPIKeyBinding)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12, design: .monospaced))
                        }
                        
                        Button(action: { showAPIKey.toggle() }) {
                            Image(systemName: showAPIKey ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(Color(hex: "777777"))
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(10)
                    .background(Color(hex: "1E1E1E"))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(hex: "2A2A2A"), lineWidth: 1)
                    )
                    
                    HStack(spacing: 8) {
                        if showSuccessMessage {
                            HStack(spacing: 5) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 11))
                                Text("Connected")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: "AAAAAA"))
                            }
                            .transition(.scale.combined(with: .opacity))
                        } else if let testErrorMessage {
                            HStack(spacing: 5) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 11))
                                Text(testErrorMessage)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: "AAAAAA"))
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        Spacer()
                        
                        if isTestingConnection {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .scaleEffect(0.6)
                                Text("Testing...")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: "888888"))
                            }
                        } else {
                            StyledButton(
                                title: "Test",
                                systemImage: "bolt.fill",
                                action: testAPIKey,
                                isDisabled: currentAPIKey.isEmpty
                            )
                        }
                    }
                    
                    HStack(spacing: 4) {
                        Text("Get your key from")
                            .font(.system(size: 10))
                        Link(apiKeyURL, destination: URL(string: "https://\(apiKeyURL)")!)
                            .font(.system(size: 10))
                    }
                    .foregroundColor(Color(hex: "777777"))
                }
            }
        )
    }
    
    @ViewBuilder
    private var localLLMSettings: some View {
        settingsCard(
            title: "Ollama Setup",
            description: ollamaError ?? "Run AI models locally on your Mac",
            icon: "server.rack",
            content: {
                VStack(spacing: 12) {
                    if installedOllamaModels.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 28))
                                .foregroundColor(Color(hex: "FF8E53"))
                            
                            VStack(spacing: 6) {
                                Text("Ollama Not Detected")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color(hex: "EAEAEA"))
                                Text("Install Ollama to use local AI models")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: "888888"))
                            }
                            
                            StyledButton(
                                title: "Download Ollama",
                                systemImage: "arrow.down.circle",
                                action: {
                                    if let url = URL(string: "https://ollama.com/") {
                                        NSWorkspace.shared.open(url)
                                    }
                                }
                            )
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 11))
                                Text("Ollama is running")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(hex: "EAEAEA"))
                                Spacer()
                                Text("\(installedOllamaModels.count) models")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: "777777"))
                            }
                            
                            Rectangle()
                                .fill(Color(hex: "2A2A2A"))
                                .frame(height: 1)
                                .padding(.vertical, 4)
                            
                            Text("Pull additional models:")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "AAAAAA"))
                            
                            Text("ollama pull llama2")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(Color(hex: "FF8E53"))
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(hex: "1E1E1E"))
                                .cornerRadius(5)
                        }
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
            return "Most capable OpenAI model"
        case "gpt-4o-mini":
            return "Fast and efficient"
        case "claude-3-5-sonnet-20241022":
            return "Anthropic's most intelligent model"
        default:
            if selectedProvider == "local" {
                return "Running locally"
            }
            return "Select a model"
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
                        withAnimation(.easeOut(duration: 0.2)) {
                            showSuccessMessage = true
                        }
                        Task {
                            try? await Task.sleep(nanoseconds: 3_000_000_000)
                            withAnimation {
                                showSuccessMessage = false
                            }
                        }
                    }
                } else {
                    await MainActor.run {
                        withAnimation {
                            testErrorMessage = "Invalid key"
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation {
                        testErrorMessage = "Connection failed"
                    }
                }
            }
            
            await MainActor.run {
                isTestingConnection = false
            }
        }
    }
}

struct ProviderButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? Color(hex: "FF6B6B") : Color(hex: "777777"))
                    .frame(width: 28, height: 28)
                    .background(isSelected ? Color(hex: "FF6B6B").opacity(0.15) : Color(hex: "252525"))
                    .cornerRadius(6)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? Color(hex: "EAEAEA") : Color(hex: "AAAAAA"))
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "FF6B6B"))
                        .font(.system(size: 14))
                }
            }
            .padding(10)
            .background(isSelected ? Color(hex: "252525") : Color(hex: "1E1E1E"))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color(hex: "FF6B6B").opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .brightness(isHovered ? 0.05 : 0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - About Tab

struct AboutView: View {
    
    private var appVersion: String {
        guard let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
              let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String else {
            return "1.0 (1)"
        }
        return "Version \(version) (\(build))"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 20) {
                // App Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: Color(hex: "FF6B6B").opacity(0.3), radius: 16, y: 8)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 8) {
                    Text("Omni")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("AI-Powered File Search")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "AAAAAA"))
                    
                    Text(appVersion)
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "666666"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(hex: "252525"))
                        .cornerRadius(5)
                }
                
                VStack(spacing: 10) {
                    FeatureRow(icon: "magnifyingglass", text: "Natural language file search")
                    FeatureRow(icon: "bolt.fill", text: "Lightning-fast indexing")
                    FeatureRow(icon: "lock.shield.fill", text: "Privacy-focused AI")
                }
                .padding(16)
                .background(Color(hex: "222222"))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(hex: "2A2A2A"), lineWidth: 1)
                )
            }
            
            Spacer()
            
            VStack(spacing: 10) {
                HStack(spacing: 16) {
                    Link(destination: URL(string: "https://github.com")!) {
                        Label("Docs", systemImage: "book.fill")
                            .font(.system(size: 11))
                    }
                    
                    Text("•")
                        .foregroundColor(Color(hex: "555555"))
                        .font(.system(size: 11))
                    
                    Link(destination: URL(string: "https://github.com")!) {
                        Label("Report Issue", systemImage: "exclamationmark.bubble.fill")
                            .font(.system(size: 11))
                    }
                    
                    Text("•")
                        .foregroundColor(Color(hex: "555555"))
                        .font(.system(size: 11))
                    
                    Link(destination: URL(string: "https://github.com")!) {
                        Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 11))
                    }
                }
                .accentColor(Color(hex: "FF6B6B"))
                
                Text("Made with ❤️ for Mac users")
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "666666"))
            }
            .padding(.bottom, 28)
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "FF6B6B"))
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "AAAAAA"))
            
            Spacer()
        }
    }
}
