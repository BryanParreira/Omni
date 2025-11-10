<div align="center">

 ▄▄▄▄▄▄▄▄▄▄▄  ▄▄       ▄▄  ▄▄        ▄  ▄▄▄▄▄▄▄▄▄▄▄
▐░░░░░░░░░░░▌▐░░▌     ▐░░▌▐░░▌      ▐░▌▐░░░░░░░░░░░▌
▐░█▀▀▀▀▀▀▀█░▌▐░▌░▌   ▐░▐░▌▐░▌░▌     ▐░▌ ▀▀▀▀█░█▀▀▀▀
▐░▌       ▐░▌▐░▌▐░▌ ▐░▌▐░▌▐░▌▐░▌    ▐░▌     ▐░▌
▐░▌       ▐░▌▐░▌ ▐░▐░▌ ▐░▌▐░▌ ▐░▌   ▐░▌     ▐░▌
▐░▌       ▐░▌▐░▌  ▐░▌  ▐░▌▐░▌  ▐░▌  ▐░▌     ▐░▌
▐░▌       ▐░▌▐░▌   ▀   ▐░▌▐░▌   ▐░▌ ▐░▌     ▐░▌
▐░▌       ▐░▌▐░▌       ▐░▌▐░▌    ▐░▌▐░▌     ▐░▌
▐░█▄▄▄▄▄▄▄█░▌▐░▌       ▐░▌▐░▌     ▐░▐░▌ ▄▄▄▄█░█▄▄▄▄
▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░▌      ▐░░▌▐░░░░░░░░░░░▌
 ▀▀▀▀▀▀▀▀▀▀▀  ▀         ▀  ▀        ▀▀  ▀▀▀▀▀▀▀▀▀▀▀
The Context-Aware Desktop AI Assistant for your Mac

Features • Installation • Usage • Privacy • Contributing

</div>

What is Omni?
Omni is a context-aware AI assistant that runs on your Mac. It connects to your local files, documents, and web pages to provide instant, intelligent answers, all while prioritizing your privacy.

Summon Omni from anywhere with a global hotkey, drag-and-drop files to instantly add context, or paste a URL to chat with a web page. Choose between cloud models like GPT-4o or run 100% offline with local models like Llama 3 for complete privacy.

✨ Features
🧠 Hybrid LLM Backend: Switch seamlessly between cloud providers (OpenAI, Anthropic, Google Gemini) or run models entirely locally with deep Ollama integration (Llama 3, Mistral, etc.).

📂 Drag & Drop Analysis: Drop files (PDFs, .txt, .md, code files) directly into the app to add them to the chat's context.

🌐 Web Source Integration: Paste any URL into the chat bar to fetch, clean, and add the website's content as a source.

⌨️ Global Hotkey: Summon Omni from any application with a simple Option + Space shortcut.

📝 AI-Generated Notebooks: Turn any chat history into a clean, structured note with a single click. Save your key insights as a .md or .txt file.

⚡ AI-Suggested Actions: Get dynamic, contextual button prompts based on your conversation, like "Draft an email" or "Explain this code."

🔒 Privacy-First: Your files are indexed locally and never uploaded. When using local models, the entire process is 100% offline.

🚀 How it Works
Omni uses a Retrieval-Augmented Generation (RAG) pipeline to provide context-aware answers.

Index: When you add a file or web page, FileIndexer reads the content, splits it into small chunks, and stores them in a local SwiftData database.

Retrieve: When you ask a question, FileSearchService finds the most relevant chunks of text from the database.

Generate: The user's question and the retrieved text chunks are sent to the AI (either local or cloud) as context. The AI then generates an answer based only on that information.

🖥️ Installation & Setup
For Users (Recommended)
Go to the Latest Release page.

Download the Omni.v1.0.0.dmg file.

Open the .dmg and drag Omni.app into your Applications folder.

For Developers (Build from Source)
Clone the repository:

Bash

git clone https://github.com/yourusername/omni.git
cd omni
Install the SwiftSoup package dependency (File > Add Packages...).

Open Omni.xcodeproj in Xcode 15 or newer.

Select your development team in "Signing & Capabilities."

Press ⌘ + R to build and run.

<details> <summary><strong>Required Entitlements for Building</strong></summary>

Your .entitlements file must include:

XML

<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.files.user-selected.read-only</key>
<true/>
<key>com.apple.security.files.bookmarks.app-scope</key>
<true/>
</details>

Usage
1. Quick Start
Launch Omni (it will run in your menu bar).

Press ⌥ + Space to show the chat window.

Drag a file, paste a URL, or just start asking questions!

2. Setting Up Your AI
You can configure your AI provider in Settings (⚙️) > AI.

Cloud Providers (OpenAI, Anthropic, etc.)
Select your provider (e.g., "OpenAI").

Paste your API key into the text field.

Click "Test Connection" to verify your key.

Choose your preferred model (e.g., gpt-4o-mini).

Local Models (Ollama)
For 100% private, offline use:

<details> <summary><strong>Click to expand Ollama setup instructions</strong></summary>

Install & Run Ollama:

Bash

# Visit ollama.com to download, or use Homebrew:
brew install ollama

# Run the Ollama server
ollama serve
Pull a Model:

Bash

# We recommend Llama 3.1
ollama pull llama3.1

# Or other great models:
ollama pull mistral  # Fast and efficient
ollama pull codellama # Optimized for code
Configure Omni:

In Omni's settings, go to the "AI" tab.

Select "Local LLM" as your provider.

Choose your installed model from the dropdown menu.

</details>

🔒 Privacy & Security
Your privacy is the core principle of this app.

Local-First Processing: When using Ollama, all AI processing and file indexing happens entirely on your Mac. No data ever leaves your device.

Sandboxed Execution: Omni runs in the secure macOS App Sandbox with minimal permissions. It only accesses what you explicitly give it.

No Data Retention: File content is never copied. The app only creates a local index of your text. When you clear a chat, all associated sources are de-referenced.

Transparent & Open-Source: The full codebase is available for you to audit exactly what Omni does with your data.

Note: When using cloud providers (OpenAI, Anthropic, Google), your prompts and context are sent to their servers and are subject to their privacy policies. For 100% privacy, use Local Mode.

🗺️ Roadmap
Q1 2026:

[ ] 🧠 Global Source Library: Add a "global memory" for the AI (style guides, personal bios)

[ ] 🔔 Proactive File Watcher: Automatically index files from watched folders (e.g., Downloads).

[ ] 📌 Pinned Insights: Add the ability to "pin" key messages to your Notebook.

Q2 2026:

[ ] 🎙️ Voice Input: Add support for dictation and voice commands.

[ ] 🚀 System-Wide Actions: Use your HotkeyManager to grab selected text from any app.

[ ] 🔗 Shortcuts Integration: Connect Omni to the Apple Shortcuts app for automation.

👋 Contributing
Contributions are welcome! Whether it's reporting a bug, suggesting a feature, or submitting code, your help is appreciated.

<table> <tr> <td width="33%" align="center">

Report Bugs


Check existing issues, then open a new one with reproduction steps.

</td> <td width="33%" align="center">

Suggest Features


Open an issue with the 'enhancement' label and describe your use case.

</td> <td width="33%" align="center">

Submit Code


Fork, create a feature branch, and open a Pull Request.

</td> </tr> </table>

<details> <summary><strong>Areas we'd love help with</strong></summary>

Supporting more file types (.docx, .pptx, etc.)

New AI-suggested actions

UI/UX polish and animations

Performance optimizations for indexing

Documentation and user tutorials

Localization into other languages

</details>

⚖️ License
This project is licensed under the MIT License. See the LICENSE file for complete terms.
