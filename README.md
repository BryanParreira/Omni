✨ Omni: The Context-Aware Desktop AI Assistant
<p align="center">
  <img src="https://img.shields.io/badge/macOS-14%2B-blue" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Swift-5.9-orange" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="MIT License">
</p>
A powerful, privacy-focused macOS application that serves as your personal desktop intelligence layer. Omni securely accesses your local files and calendar, using advanced Large Language Models (LLMs) to answer natural language questions, surface relevant information, and suggest actionable next steps.

💡 Overview
Omni transforms your Mac into a proactive productivity hub by seamlessly integrating AI assistance with your local files and calendar. Built with privacy at its core, Omni enables instant information retrieval and intelligent action suggestions—all while keeping your data secure.
Perfect for:

Developers who need quick code explanations and documentation assistance
Professionals managing multiple meetings and document workflows
Privacy-conscious users who want AI capabilities without cloud dependency
Anyone seeking instant, context-aware answers from their local files


🚀 Key Features
Core Intelligence

🧠 Hybrid LLM Backend: Choose between major cloud providers (OpenAI, Anthropic, Google Gemini) or run models entirely locally with deep Ollama integration (Llama 3, Mistral, and more)
🎯 AI-Suggested Actions (A-RAG): Dynamic, contextual actions based on file type:

"Explain this code" for Swift/Python files
"Summarize document" for PDFs
"Draft an email" for general tasks
Custom actions tailored to your workflow


🔍 General Knowledge Mode: Functions as a flexible assistant even without attached files

Workflow & Productivity

📅 Meeting Preparation: Native macOS Calendar integration displays upcoming events in the sidebar, supporting Google Calendar, Exchange, and iCloud
⌨️ Global Hotkey Access: Summon Omni instantly with ⌥ + Space from anywhere on your Mac
📎 Drag-and-Drop Support: Simply drag files (PDF, code, text, etc.) into the chat for instant analysis
🗑️ Smart Chat Management: Clear current conversations or delete entire sessions via the sidebar context menu
💬 Persistent History: All conversations are saved locally for easy reference


⚙️ Installation & Setup
System Requirements

macOS: 14 (Sonoma) or newer
Xcode: 15+ (if building from source)
Storage: ~100MB for the app, plus space for local models if using Ollama

Quick Start

Launch Omni: The app runs silently in your menu bar
Summon the Interface: Press ⌥ + Space anywhere
Start Chatting:

Type any question or request
Drag-and-drop files directly into the input field
Click suggested actions to streamline your workflow



Setting Up Local LLMs (Optional but Recommended)
For maximum privacy and offline capability:

Install Ollama:

bash   # Visit ollama.com to download, or use Homebrew:
   brew install ollama

Pull a Model:

bash   # Download Llama 3 (recommended for general use)
   ollama pull llama3
   
   # Or try other models:
   ollama pull mistral
   ollama pull codellama  # Great for code-related tasks

Configure Omni:

Open Settings (⚙️ icon in the app)
Navigate to the AI tab
Select your installed model from the "Local LLM" dropdown



Pro Tip: Local models run entirely on your Mac—no internet required, complete privacy guaranteed.

🛠️ Building from Source
Prerequisites
bash# Clone the repository
git clone https://github.com/yourusername/omni.git
cd omni

# Open in Xcode
open Omni.xcodeproj
Required Entitlements
The project uses App Sandbox and requires specific entitlements. Ensure your .entitlements file includes:
xml<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.personal-information.calendars</key>
<true/>
<key>com.apple.security.personal-information.speech-recognition</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
```

### Xcode Configuration

In **Signing & Capabilities** → **App Sandbox**, enable:

- ✅ **Calendars** (under App Data)
- ✅ **Outgoing Connections (Client)** (under Network) — *Required for Ollama and cloud APIs*
- ✅ **Speech Recognition** (under Hardware)

### Build & Run

1. Select your development team in **Signing & Capabilities**
2. Choose your target device (macOS)
3. Press **`⌘ + R`** to build and run

---

## 🔒 Privacy & Security

Omni is built with privacy as a foundational principle:

- **🏠 Local-First**: When using Ollama, all AI processing happens entirely on your Mac
- **🚫 No Data Collection**: We never collect, transmit, or store your files or conversations on external servers
- **🔐 Sandboxed**: Runs in macOS App Sandbox with minimal permissions
- **📝 Transparent**: File content is read only during active conversations and never retained afterward
- **🎯 You Control the Data**: Choose between cloud providers or fully local models based on your privacy needs

**Note**: Cloud providers (OpenAI, Anthropic, Google) process data according to their respective privacy policies.

---

## 📖 Usage Examples

### Ask General Questions
```
"What's the weather like today in San Francisco?"
"Explain quantum computing in simple terms"
```

### Analyze Code
```
Drag a .swift file → "Explain what this code does"
"Find potential bugs in this function"
"Suggest performance improvements"
```

### Work with Documents
```
Drag a PDF → "Summarize this document"
"Extract key takeaways from this report"
"Create an action item list"
```

### Meeting Preparation
```
View upcoming meetings in the sidebar
"What's on my calendar today?"
"Prepare talking points for my 3pm meeting"

🤝 Contributing
We welcome contributions from the community! Here's how you can help:
Reporting Issues

Check existing issues first
Provide clear reproduction steps
Include macOS version and Omni version

Suggesting Features

Open an issue with the enhancement label
Describe the use case and expected behavior
Consider privacy implications

Submitting Pull Requests

Fork the repository
Create a feature branch (git checkout -b feature/amazing-feature)
Commit your changes (git commit -m 'Add amazing feature')
Push to the branch (git push origin feature/amazing-feature)
Open a Pull Request

Areas we'd love help with:

Supporting additional file types (Excel, Word, etc.)
New suggested actions for different workflows
UI/UX improvements
Performance optimizations
Documentation and tutorials


🗺️ Roadmap

 Multi-file conversation context
 Custom action templates
 Integration with Apple Shortcuts
 Support for team knowledge bases
 Voice input/output
 Plugin system for third-party integrations


📜 License
Distributed under the MIT License. See LICENSE for more information.

🙏 Acknowledgments

Ollama for making local LLMs accessible
OpenAI, Anthropic, and Google for their powerful cloud APIs
The open-source community for inspiration and tools


📧 Contact & Support

Issues: GitHub Issues
Discussions: GitHub Discussions
Email: support@omniapp.dev


<p align="center">
  Made with ❤️ for the Mac community
</p>
<p align="center">
  <sub>If you find Omni useful, consider giving it a ⭐️ on GitHub!</sub>
</p>
