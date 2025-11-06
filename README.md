✨ Omni: The Context-Aware Desktop AI Assistant
💡 Overview
Omni is a powerful, privacy-focused macOS application designed to be your personal desktop intelligence layer. It indexes your local files and uses advanced Large Language Models (LLMs) (both cloud and local via Ollama) to answer natural language questions about your data, documents, and code.

Unlike simple search tools, Omni is built for proactive productivity, offering smart actions and surfacing relevant context from your digital workspace.

🚀 Key Features
Omni is built to make information retrieval instant and actionable.

🧠 AI-Powered File Indexing (RAG): Connects to local files (.pdf, .md, .swift, etc.) and uses an LLM to answer complex, natural language questions about their content.

🔌 Flexible LLM Backend: Supports major cloud providers (OpenAI, Anthropic, Gemini) and features deep integration with Ollama for running powerful models (like Llama 3) entirely locally on your Mac for privacy and speed.

🎯 AI-Suggested Actions (A-RAG): Messages returned by the AI come with clickable "Suggested Actions" based on the file type (e.g., "Explain this code," "Draft an email," "Analyze data").

📅 Meeting Preparation: Integrates with your native macOS calendar (including Google/Exchange accounts) to display upcoming events right in the sidebar, ensuring you're always prepared.

🛠️ Developer-Focused: Excellent for quickly searching and analyzing code files.

💻 Installation
Omni is currently built for macOS.

Requirements
macOS 14 (Sonoma) or newer.

Xcode 15+ (if building from source).

Running Locally (Developers)
Clone the Repository:

Bash

git clone [YOUR_REPO_URL]
cd Omni
Open in Xcode:

Bash

xed .
Run: Select the Omni target and press Cmd + R.

For Local LLM Users (Optional)
To enable the local LLM feature:

Install Ollama: Download and run the Ollama application from ollama.com.

Pull a Model: Open Terminal and pull your desired model (e.g., llama3):

Bash

ollama pull llama3
⚙️ Configuration
Launch: Omni runs silently in the background and can be accessed via the Status Bar icon.

Hotkey: Summon Omni instantly using the global hotkey: ⌥ + Space.

AI Setup: Open the Settings (⚙️ icon) and navigate to the AI Tab.

Cloud Provider: Enter your API key for OpenAI, Anthropic, or Gemini.

Local LLM: Select your installed model (e.g., llama3) from the dropdown.

🔒 Privacy & Permissions
Omni is built with privacy as a core principle.

No Cloud Storage: File content is read only for the purpose of generating context for the LLM. We do not store or transmit your file content to our servers.

Local LLM Support: The native Ollama integration allows users to run models locally, ensuring data never leaves your machine.

🤝 Contributing
We welcome contributions! If you have suggestions for new file types, LLM actions, or encounter any bugs, please open an Issue or submit a Pull Request.

Planned Improvements:
Sidebar Chat Renaming functionality.

Implement additional Suggested Actions (e.g., "Create JIRA ticket").

Add Reminders integration via EventKit.

📜 License
Distributed under the MIT License. See LICENSE for more information.
