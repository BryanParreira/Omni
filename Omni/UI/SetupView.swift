import SwiftUI
import AppKit // For NSWorkspace and NSApp

// Struct to store settings keys
private struct SettingsKeys {
    static let hasCompletedSetup = "hasCompletedSetup"
    static let selectedProvider = "selected_provider"
    static let openAIKey = "openai_api_key"
}

// Custom view for our selection cards
private struct SetupChoiceCard: View {
    let title: String
    let icon: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(LinearGradient(colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "AAAAAA"))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(LinearGradient(colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
            }
            .padding(20)
            .background(Color(hex: isSelected ? "2F2F2F" : "242424"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: "FF8E53") : Color(hex: "2F2F2F"), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// The main Setup View
struct SetupView: View {
    @AppStorage(SettingsKeys.hasCompletedSetup) var hasCompletedSetup: Bool = false
    @AppStorage(SettingsKeys.openAIKey) private var openAIKey: String = ""
    @AppStorage(SettingsKeys.selectedProvider) private var selectedProvider: String = "openai"
    
    // --- REMOVED THEME @AppStorage ---
    
    @State private var currentPage = 1
    @State private var isGrantingAccess = false
    @State private var showingSettingsAlert = false
    
    // Gradient for brand colors
    private let brandGradient = LinearGradient(
        colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        VStack(spacing: 0) {
            // Header: Omni Setup Title
            HStack {
                Image(systemName: "brain.head.profile")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(brandGradient)
                
                Text("Omni Setup")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Step \(currentPage)/3")
                    .font(.callout)
                    .foregroundColor(Color(hex: "8A8A8A"))
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 15)
            .background(Color(hex: "242424"))
            
            // Content Area
            VStack {
                switch currentPage {
                case 1:
                    welcomePage
                case 2:
                    llmSetupPage
                case 3:
                    permissionsPage
                default:
                    EmptyView()
                }
            }
            .animation(.easeInOut, value: currentPage)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "1A1A1A"))
            
            // Footer: Navigation Buttons
            HStack(spacing: 15) {
                Button(action: {
                    withAnimation { currentPage -= 1 }
                }) {
                    Label("Back", systemImage: "chevron.left")
                        .font(.body)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 15)
                        .frame(minWidth: 90)
                }
                .buttonStyle(.plain)
                .background(Color(hex: "2F2F2F"))
                .cornerRadius(8)
                .disabled(currentPage == 1)
                .opacity(currentPage == 1 ? 0.5 : 1)
                
                Spacer()
                
                if currentPage < 3 {
                    Button(action: {
                        withAnimation { currentPage += 1 }
                    }) {
                        Label("Next", systemImage: "chevron.right")
                            .font(.body)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 15)
                            .frame(minWidth: 90)
                    }
                    .buttonStyle(.plain)
                    .background(brandGradient)
                    .cornerRadius(8)
                } else {
                    Button(action: {
                        completeSetup()
                    }) {
                        Label("Finish Setup", systemImage: "checkmark.circle.fill")
                            .font(.body)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 15)
                            .frame(minWidth: 120)
                    }
                    .buttonStyle(.plain)
                    .background(brandGradient)
                    .cornerRadius(8)
                    .disabled(selectedProvider == "openai" && openAIKey.isEmpty)
                }
            }
            .padding(15)
            .background(Color(hex: "242424"))
        }
        .frame(width: 600, height: 650)
        .background(Color(hex: "1A1A1A"))
        .foregroundColor(.white)
        .cornerRadius(10) // Apply corner radius to the whole view
        // --- REMOVED .preferredColorScheme() ---
        .alert(isPresented: $showingSettingsAlert) {
            Alert(
                title: Text("Full Disk Access Required"),
                message: Text("Please grant Omni 'Full Disk Access' in System Settings to enable file analysis. You need to drag Omni into the list manually."),
                dismissButton: .default(Text("Got It"))
            )
        }
    }
    
    // MARK: - Page Views
    
    var welcomePage: some View {
        VStack(spacing: 25) {
            Spacer()
            Image(systemName: "brain.head.profile")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(brandGradient)
            
            Text("Welcome to Omni")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Your private, AI-powered assistant for all your local files, code, and documents. Let's get you set up!")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(hex: "AAAAAA"))
                .padding(.horizontal, 40)
            Spacer()
            
            // --- REMOVED THEME PICKER ---
            
            Spacer()
        }
        .padding(40)
    }
    
    var llmSetupPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Connect Your AI Brain")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Choose how Omni connects to its intelligence. You can change this later in Settings.")
                    .font(.body)
                    .foregroundColor(Color(hex: "AAAAAA"))
                
                SetupChoiceCard(
                    title: "Cloud AI (Recommended)",
                    icon: "cloud.fill",
                    description: "Uses OpenAI (GPT-4o) for the most powerful answers.",
                    isSelected: selectedProvider == "openai"
                ) {
                    selectedProvider = "openai"
                }
                
                if selectedProvider == "openai" {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How to get your API Key:")
                            .font(.subheadline).fontWeight(.semibold)
                        HStack {
                            Text("1. Go to")
                            Link("platform.openai.com/keys", destination: URL(string: "https://platform.openai.com/keys")!)
                                .foregroundStyle(brandGradient)
                            Spacer()
                        }
                        Text("2. Create a new secret key and copy it.")
                        Text("3. Paste your key below:")
                        
                        SecureField("sk-...", text: $openAIKey)
                            .textFieldStyle(.plain)
                            .padding(10)
                            .background(Color(hex: "1A1A1A"))
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "2F2F2F")))
                        
                        Text("Your key is stored securely in your Mac's Keychain and never leaves your computer.")
                            .font(.caption)
                            .foregroundColor(Color(hex: "8A8A8A"))
                    }
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "AAAAAA"))
                    .padding(20)
                    .background(Color(hex: "2F2F2F"))
                    .cornerRadius(12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                SetupChoiceCard(
                    title: "Local LLM (100% Private)",
                    icon: "cpu.fill",
                    description: "Runs models on your Mac for free. 100% private. Requires setup.",
                    isSelected: selectedProvider == "local"
                ) {
                    selectedProvider = "local"
                }
                
                if selectedProvider == "local" {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How to set up Ollama:")
                            .font(.subheadline).fontWeight(.semibold)
                        HStack {
                            Text("1. ")
                            Button("Download and run the Ollama app") {
                                if let url = URL(string: "https://ollama.com/download") {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                            .buttonStyle(.link)
                            .foregroundStyle(brandGradient)
                            Spacer()
                        }
                        Text("2. Make sure the Ollama icon is in your menu bar.")
                        Text("3. Open your Mac's Terminal and run this command to get a model:")
                        
                        Text("ollama pull llama3")
                            .font(.system(.caption, design: .monospaced))
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: "1A1A1A"))
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "2F2F2F")))
                    }
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "AAAAAA"))
                    .padding(20)
                    .background(Color(hex: "2F2F2F"))
                    .cornerRadius(12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(40)
        }
    }
    
    var permissionsPage: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Grant Full Disk Access")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("Omni needs this permission to **find and index** your files.")
                .font(.body)
                .foregroundColor(Color(hex: "AAAAAA"))
            
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "hand.raised.fill")
                        .font(.title3)
                        .foregroundStyle(brandGradient)
                    Text("Why is this required?")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                Text("Omni is a **local** file indexer. To answer questions about your documents, code, and notes, it needs permission to read them. **Your files and their content never leave your Mac.**")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "AAAAAA"))
            }
            .padding()
            .background(Color(hex: "242424"))
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "list.bullet.clipboard.fill")
                        .font(.title3)
                        .foregroundStyle(brandGradient)
                    Text("How to grant access:")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Click the button below to open System Settings.")
                    Text("2. Click the **+** icon, find **Omni** in your Applications folder, and add it.")
                    Text("3. **Turn the toggle ON** for Omni.")
                }
                .font(.subheadline)
                .foregroundColor(Color(hex: "AAAAAA"))
                
                Button(action: {
                    isGrantingAccess = true
                    openFullDiskAccessSettings()
                    showingSettingsAlert = true
                }) {
                    Label(isGrantingAccess ? "Opening Settings..." : "Open Privacy & Security Settings", systemImage: "arrow.up.right.square.fill")
                        .font(.body).fontWeight(.semibold)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 15)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .background(Color(hex: "FF6B6B").opacity(0.9))
                .cornerRadius(8)
                .disabled(isGrantingAccess)
            }
            .padding()
            .background(Color(hex: "242424"))
            .cornerRadius(12)
            
            Spacer()
        }
        .padding(40)
    }
    
    // Helper function to open settings
    private func openFullDiskAccessSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func completeSetup() {
        hasCompletedSetup = true
        
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.setupDidComplete()
        }
        
        NSApp.keyWindow?.close()
    }
}
