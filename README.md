<div align="center">

```
   ▄▄▄▄▄▄▄▄▄▄▄  ▄▄       ▄▄  ▄▄        ▄  ▄▄▄▄▄▄▄▄▄▄▄ 
  ▐░░░░░░░░░░░▌▐░░▌     ▐░░▌▐░░▌      ▐░▌▐░░░░░░░░░░░▌
  ▐░█▀▀▀▀▀▀▀█░▌▐░▌░▌   ▐░▐░▌▐░▌░▌     ▐░▌ ▀▀▀▀█░█▀▀▀▀ 
  ▐░▌       ▐░▌▐░▌▐░▌ ▐░▌▐░▌▐░▌▐░▌    ▐░▌     ▐░▌     
  ▐░▌       ▐░▌▐░▌ ▐░▐░▌ ▐░▌▐░▌ ▐░▌   ▐░▌     ▐░▌     
  ▐░▌       ▐░▌▐░▌  ▐░▌  ▐░▌▐░▌  ▐░▌  ▐░▌     ▐░▌     
  ▐░▌       ▐░▌▐░▌   ▀   ▐░▌▐░▌   ▐░▌ ▐░▌     ▐░▌     
  ▐░▌       ▐░▌▐░▌       ▐░▌▐░▌    ▐░▌▐░▌     ▐░▌     
  ▐░█▄▄▄▄▄▄▄█░▌▐░▌       ▐░▌▐░▌     ▐░▐░▌ ▄▄▄▄█░█▄▄▄▄ 
  ▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░▌      ▐░░▌▐░░░░░░░░░░░▌
   ▀▀▀▀▀▀▀▀▀▀▀  ▀         ▀  ▀        ▀▀  ▀▀▀▀▀▀▀▀▀▀▀ 
```

### ✨ The Context-Aware Desktop AI Assistant ✨

**Your personal intelligence layer for macOS**

[![macOS](https://img.shields.io/badge/macOS-14%2B-000000?style=for-the-badge&logo=apple&logoColor=white)](https://www.apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-5.9-FA7343?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=for-the-badge)](http://makeapullrequest.com)

[Features](#-key-features) • [Installation](#%EF%B8%8F-installation--setup) • [Usage](#-usage-examples) • [Contributing](#-contributing) • [License](#-license)

---

</div>

## 🎯 Overview

<table>
<tr>
<td width="60%">

Omni transforms your Mac into a **proactive productivity hub** by seamlessly integrating AI assistance with your local files and calendar. Built with **privacy at its core**, Omni enables instant information retrieval and intelligent action suggestions—all while keeping your data secure.

**Perfect for:**
- 👨‍💻 Developers needing quick code explanations
- 📊 Professionals managing multiple workflows
- 🔒 Privacy-conscious users wanting local AI
- ⚡ Anyone seeking instant, context-aware answers

</td>
<td width="40%">

```
╔═══════════════════════╗
║   🧠 Hybrid LLM       ║
║   📅 Calendar Sync    ║
║   ⌨️  Global Hotkey    ║
║   🔒 Privacy First    ║
║   📎 Drag & Drop      ║
║   ⚡ Lightning Fast   ║
╚═══════════════════════╝
```

</td>
</tr>
</table>

---

## 🚀 Key Features

<div align="center">

### Core Intelligence

</div>

| Feature | Description |
|---------|-------------|
| 🧠 **Hybrid LLM Backend** | Choose between cloud providers (OpenAI, Anthropic, Google Gemini) or run models entirely locally with Ollama (Llama 3, Mistral, CodeLlama) |
| 🎯 **AI-Suggested Actions** | Context-aware actions appear dynamically: "Explain this code" for Swift files, "Summarize" for PDFs, "Draft email" for general tasks |
| 🔍 **General Knowledge** | Functions as a flexible assistant even without attached files—ask anything! |

<div align="center">

### Workflow & Productivity

</div>

<table>
<tr>
<td align="center" width="33%">

### 📅
**Meeting Prep**

Native Calendar integration with Google, Exchange & iCloud support

</td>
<td align="center" width="33%">

### ⌨️
**Global Hotkey**

Summon with **`⌥ + Space`** from anywhere

</td>
<td align="center" width="33%">

### 📎
**Drag & Drop**

Instant file analysis for PDFs, code, and more

</td>
</tr>
</table>

---

## ⚙️ Installation & Setup

### 📋 System Requirements

```
macOS:    14 (Sonoma) or newer
Xcode:    15+ (for building from source)
Storage:  ~100MB + space for local models
```

### 🚀 Quick Start

<table>
<tr>
<td width="5%">1️⃣</td>
<td><strong>Launch Omni</strong> — The app runs silently in your menu bar</td>
</tr>
<tr>
<td>2️⃣</td>
<td><strong>Summon</strong> — Press <code>⌥ + Space</code> anywhere on your Mac</td>
</tr>
<tr>
<td>3️⃣</td>
<td><strong>Chat</strong> — Type questions or drag files into the input field</td>
</tr>
</table>

### 🏠 Setting Up Local LLMs (Recommended)

<details>
<summary><b>Click to expand setup instructions</b></summary>

<br>

**For maximum privacy and offline capability:**

#### Step 1: Install Ollama

```bash
# Visit ollama.com to download, or use Homebrew:
brew install ollama
```

#### Step 2: Pull a Model

```bash
# Download Llama 3 (recommended for general use)
ollama pull llama3

# Or try other models:
ollama pull mistral        # Fast and efficient
ollama pull codellama      # Optimized for code
ollama pull phi3          # Lightweight option
```

#### Step 3: Configure Omni

```
1. Open Settings (⚙️ icon)
2. Navigate to AI tab
3. Select model from "Local LLM" dropdown
```

> 💡 **Pro Tip**: Local models run entirely on your Mac—no internet required, complete privacy guaranteed!

</details>

---

## 🛠️ Building from Source

<details>
<summary><b>Developer Setup Instructions</b></summary>

<br>

### Prerequisites

```bash
# Clone the repository
git clone https://github.com/yourusername/omni.git
cd omni

# Open in Xcode
open Omni.xcodeproj
```

### Required Entitlements

Add to your `.entitlements` file:

```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.personal-information.calendars</key>
<true/>
<key>com.apple.security.personal-information.speech-recognition</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
```

### Xcode Configuration

**Signing & Capabilities** → **App Sandbox**:

- ✅ Calendars (App Data)
- ✅ Outgoing Connections (Network)
- ✅ Speech Recognition (Hardware)

### Build & Run

```
1. Select development team in Signing & Capabilities
2. Choose target: macOS
3. Press ⌘ + R to build and run
```

</details>

---

## 🔒 Privacy & Security

<div align="center">

```
┌─────────────────────────────────────────────────┐
│  🏠  LOCAL-FIRST    │  🚫  NO DATA COLLECTION   │
├─────────────────────────────────────────────────┤
│  🔐  SANDBOXED      │  📝  TRANSPARENT          │
├─────────────────────────────────────────────────┤
│  🎯  YOU CONTROL EVERYTHING                     │
└─────────────────────────────────────────────────┘
```

</div>

| Principle | Implementation |
|-----------|---------------|
| **Local-First** | When using Ollama, all AI processing happens entirely on your Mac |
| **Zero Retention** | File content is read only during conversations, never stored |
| **Sandboxed** | Runs in macOS App Sandbox with minimal permissions |
| **Transparent** | Open source—audit the code yourself |
| **Your Choice** | Use cloud providers or fully local models based on your needs |

> ⚠️ **Note**: Cloud providers (OpenAI, Anthropic, Google) process data according to their respective privacy policies.

---

## 📖 Usage Examples

<table>
<tr>
<td width="50%">

### 💬 Ask General Questions

```
"What's the weather in SF?"

"Explain quantum computing 
simply"

"Help me write a poem"
```

</td>
<td width="50%">

### 📅 Meeting Preparation

```
View upcoming meetings 
in sidebar

"What's on my calendar?"

"Prep for my 3pm meeting"
```

</td>
</tr>
<tr>
<td>

### 👨‍💻 Analyze Code

```
Drag .swift file →
"Explain this code"

"Find potential bugs"

"Suggest improvements"
```

</td>
<td>

### 📄 Work with Documents

```
Drag PDF →
"Summarize this document"

"Extract key takeaways"

"Create action items"
```

</td>
</tr>
</table>

---

## 🤝 Contributing

<div align="center">

**We welcome contributions from the community!**

[![GitHub Issues](https://img.shields.io/github/issues/yourusername/omni?style=for-the-badge)](https://github.com/yourusername/omni/issues)
[![GitHub PRs](https://img.shields.io/github/issues-pr/yourusername/omni?style=for-the-badge)](https://github.com/yourusername/omni/pulls)

</div>

### 🐛 Reporting Issues

```
1. Check existing issues first
2. Provide clear reproduction steps
3. Include macOS & Omni version
```

### 💡 Suggesting Features

```
1. Open issue with 'enhancement' label
2. Describe use case and expected behavior
3. Consider privacy implications
```

### 🔧 Submitting Pull Requests

```bash
# 1. Fork the repository
# 2. Create feature branch
git checkout -b feature/amazing-feature

# 3. Commit changes
git commit -m 'Add amazing feature'

# 4. Push to branch
git push origin feature/amazing-feature

# 5. Open Pull Request
```

<details>
<summary><b>Areas we'd love help with</b></summary>

- Supporting additional file types (Excel, Word, etc.)
- New suggested actions for different workflows
- UI/UX improvements
- Performance optimizations
- Documentation and tutorials
- Localization (i18n)

</details>

---

## 🗺️ Roadmap

<div align="center">

| Phase | Features | Status |
|-------|----------|--------|
| **Q1 2025** | Multi-file context, Custom actions | 🚧 In Progress |
| **Q2 2025** | Apple Shortcuts, Voice I/O | 📅 Planned |
| **Q3 2025** | Team knowledge bases, Plugins | 💭 Proposed |

</div>

---

## 📜 License

<div align="center">

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for more information.

```
┌────────────────────────────────────────┐
│  Free to use, modify, and distribute   │
│  Commercial use allowed                │
│  Attribution appreciated               │
└────────────────────────────────────────┘
```

</div>

---

## 🙏 Acknowledgments

<table>
<tr>
<td align="center" width="33%">
<img src="https://img.shields.io/badge/Ollama-000000?style=for-the-badge" alt="Ollama"/>
<br><sub>Local LLM magic</sub>
</td>
<td align="center" width="33%">
<img src="https://img.shields.io/badge/OpenAI-412991?style=for-the-badge&logo=openai&logoColor=white" alt="OpenAI"/>
<br><sub>GPT integration</sub>
</td>
<td align="center" width="33%">
<img src="https://img.shields.io/badge/Anthropic-000000?style=for-the-badge" alt="Anthropic"/>
<br><sub>Claude support</sub>
</td>
</tr>
</table>

<div align="center">

Special thanks to the **open-source community** for inspiration and tools 💙

</div>

---

## 📧 Contact & Support

<div align="center">

| Channel | Link |
|---------|------|
| 🐛 **Issues** | [GitHub Issues](https://github.com/yourusername/omni/issues) |
| 💬 **Discussions** | [GitHub Discussions](https://github.com/yourusername/omni/discussions) |
| 📧 **Email** | support@omniapp.dev |
| 🐦 **Twitter** | [@OmniApp](https://twitter.com/omniapp) |

</div>

---

<div align="center">

```
╔════════════════════════════════════════════════╗
║                                                ║
║     Made with ❤️  for the Mac community        ║
║                                                ║
╚════════════════════════════════════════════════╝
```

**If you find Omni useful, consider giving it a ⭐️ on GitHub!**

<sub>Built with Swift • Powered by AI • Secured by macOS</sub>

---

[⬆ Back to Top](#)

</div>
