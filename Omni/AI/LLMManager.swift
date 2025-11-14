import Foundation
import SwiftData // <-- Add this import

enum LLMMode {
    case openAI
    case local
}

class LLMManager {
    static let shared = LLMManager()
    
    private init() {}
    
    private var currentMode: LLMMode {
        let apiKey = UserDefaults.standard.string(forKey: "openai_api_key")
        let provider = UserDefaults.standard.string(forKey: "selected_provider")
        
        if provider == "openai" && (apiKey != nil && !apiKey!.isEmpty) {
            return .openAI
        }
        return .local
    }
    
    // MARK: - System Prompts
    
    private let generalSystemPrompt = """
    You are a helpful general-purpose AI assistant named Omni.
    Answer the user's question clearly and concisely.
    """
    
    private let overviewSystemPrompt = """
    You are an expert document analyst. You will be given the first few chunks of a document.
    Your task is to generate a concise summary, 3-4 key topics, and 3 suggested questions.
    You MUST respond in this exact format, with no other text:
    
    Summary: [Your 1-2 sentence summary]
    Key Topics:
    - [Topic 1]
    - [Topic 2]
    - [Topic 3]
    Suggested Questions:
    1. [Suggested Question 1]
    2. [Suggested Question 2]
    3. [Suggested Question 3]
    """

    private let notebookSystemPrompt = """
    You are a professional research assistant. Your task is to synthesize a chat discussion into a clean, structured notebook entry.
    The user will provide the full chat history.
    Analyze the entire conversation and generate a comprehensive summary in Markdown format.
    The summary should include:
    1. A concise overview of the main topic.
    2. Key insights or conclusions reached.
    3. A list of important bullet points, facts, or data mentioned.

    Respond ONLY with the Markdown-formatted note. Do not add any conversational text.
    """
    
    // --- 1. NEW SYSTEM PROMPT (EXAM) ---
    private let examSystemPrompt = """
    You are an expert exam creator. You will be given a large context from one or more documents.
    Your task is to generate a challenging, high-quality practice exam based *only* on the provided text.
    You MUST generate 5 multiple-choice questions.
    You MUST format your response as a single, valid JSON object, with no other text or markdown delimiters.
    
    The JSON structure MUST be:
    {
      "name": "Practice Exam: [Main Topic of Context]",
      "questions": [
        {
          "questionText": "Your full question text here...",
          "options": ["Option A", "Option B", "Option C", "Option D"],
          "correctAnswerIndex": 2,
          "explanation": "A brief explanation of why this is the correct answer, based on the context."
        }
      ]
    }
    
    Generate 5 questions.
    """
    
    // --- 2. NEW SYSTEM PROMPT (TIMELINE) ---
    private let timelineSystemPrompt = """
    You are an expert project analyst and historian. You will be given context from one or more documents.
    Your task is to scan the text for any events, dates, milestones, or key decisions and organize them into a chronological timeline.
    
    You MUST format your response as a clean Markdown string.
    If you find dates, use them. If not, use the order of events.
    
    Respond ONLY with the Markdown.
    
    Example:
    
    # Project Timeline
    
    ## Q3 2025
    * **Oct 15:** Initial project kickoff meeting.
    * **Oct 22:** Design specifications were finalized.
    
    ## Q4 2025
    * **Nov 5:** Development of core features began.
    * **Nov 30:** Milestone 1 (Alpha) was completed.
    
    ## Key Decisions
    - The team decided to switch from API A to API B during the Oct 15 kickoff.
    - The design scope was finalized on Oct 22.
    """
    
    // MARK: - Public API
    
    /// Generates a standard chat response, now returning a simple String.
    func generateResponse(chatHistory: [ChatMessage], context: String, files: [URL]) async throws -> String {
        
        let responseText: String
        var messages: [OpenAIMessage] = []
        
        let systemPrompt = files.isEmpty ? generalSystemPrompt : generateSmartPrompt(for: files)
        messages.append(OpenAIMessage(role: "system", content: systemPrompt))
        
        if !context.isEmpty {
            let contextMessage = "File Context:\n\(context)"
            messages.append(OpenAIMessage(role: "user", content: contextMessage))
        }
        
        for message in chatHistory {
            if message.content.contains("Hi! I'm Omni") && chatHistory.count == 1 {
                continue
            }
            let role = message.isUser ? "user" : "assistant"
            messages.append(OpenAIMessage(role: role, content: message.content))
        }
        
        switch currentMode {
        case .openAI:
            responseText = try await OpenAIClient.shared.generateResponse(
                messages: messages
            )
        case .local:
            responseText = try await LocalLLMRunner.shared.generateResponse(
                messages: messages
            )
        }
        
        return responseText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Generates a summary overview for a new file.
    func generateOverview(chunks: [String], fileName: String) async throws -> String {
        
        let context = "CONTEXT FROM '\(fileName)':\n" + chunks.joined(separator: "\n---\n")
        let messages = [
            OpenAIMessage(role: "system", content: overviewSystemPrompt),
            OpenAIMessage(role: "user", content: context)
        ]
        
        let responseText: String
        switch currentMode {
        case .openAI:
            responseText = try await OpenAIClient.shared.generateResponse(messages: messages)
        case .local:
            responseText = try await LocalLLMRunner.shared.generateResponse(messages: messages)
        }
        
        return responseText
    }
    
    /// Generates a full notebook summary from a chat history.
    func generateNotebook(chatHistory: [ChatMessage], files: [URL]) async throws -> String {
        
        var messages: [OpenAIMessage] = []
        
        messages.append(OpenAIMessage(role: "system", content: notebookSystemPrompt))
        
        var fullHistory = "Here is the chat history to summarize:\n\n"
        for message in chatHistory {
            if message.content.contains("Hi! I'm Omni") && chatHistory.count == 1 {
                continue
            }
            let role = message.isUser ? "[User]" : "[Assistant]"
            fullHistory += "\(role)\n\(message.content)\n\n"
        }
        messages.append(OpenAIMessage(role: "user", content: fullHistory))

        let responseText: String
        switch currentMode {
        case .openAI:
            responseText = try await OpenAIClient.shared.generateResponse(
                messages: messages
            )
        case .local:
            responseText = try await LocalLLMRunner.shared.generateResponse(
                messages: messages
            )
        }
        
        return responseText
    }
    
    // --- 3. NEW EXAM AGENT FUNCTION ---
    func generateExam(from project: Project, modelContext: ModelContext) async throws -> Quiz {
        
        // --- !!! ACTION REQUIRED !!! ---
        // I need your `LibraryManager` or `FileIndexer` code to know
        // how to get the text content for all files in a project.
        // I will use a placeholder function.
        let fullContext = await getContextForProject(project)
        // --- !!! END ACTION REQUIRED !!! ---

        if fullContext.isEmpty {
            throw AIError.invalidResponse // Or a custom error
        }
        
        let messages = [
            OpenAIMessage(role: "system", content: examSystemPrompt),
            OpenAIMessage(role: "user", content: fullContext)
        ]
        
        let responseText: String
        switch currentMode {
        case .openAI:
            responseText = try await OpenAIClient.shared.generateResponse(messages: messages)
        case .local:
            responseText = try await LocalLLMRunner.shared.generateResponse(messages: messages)
        }
        
        // Decode the JSON response
        guard let jsonData = responseText.data(using: .utf8) else {
            print("Error: Could not convert response to Data")
            throw AIError.invalidResponse
        }
        
        let decodableQuiz: DecodableQuiz
        do {
            decodableQuiz = try JSONDecoder().decode(DecodableQuiz.self, from: jsonData)
        } catch {
            print("Error decoding JSON: \(error)")
            print("Raw LLM Response: \(responseText)")
            throw AIError.invalidResponse
        }

        // Create the SwiftData models
        let quiz = Quiz(name: decodableQuiz.name, project: project)
        for dq in decodableQuiz.questions {
            let question = QuizQuestion(
                questionText: dq.questionText,
                options: dq.options,
                correctAnswerIndex: dq.correctAnswerIndex,
                explanation: dq.explanation
            )
            quiz.questions.append(question)
        }
        
        // We can insert the quiz into the context here
        modelContext.insert(quiz)
        try modelContext.save()
        
        return quiz
    }

    // --- 4. NEW TIMELINE AGENT FUNCTION ---
    func generateTimeline(from project: Project) async throws -> String {
        
        // --- !!! ACTION REQUIRED !!! ---
        let fullContext = await getContextForProject(project)
        // --- !!! END ACTION REQUIRED !!! ---

        if fullContext.isEmpty {
            throw AIError.invalidResponse
        }
        
        let messages = [
            OpenAIMessage(role: "system", content: timelineSystemPrompt),
            OpenAIMessage(role: "user", content: fullContext)
        ]
        
        let responseText: String
        switch currentMode {
        case .openAI:
            responseText = try await OpenAIClient.shared.generateResponse(messages: messages)
        case .local:
            responseText = try await LocalLLMRunner.shared.generateResponse(messages: messages)
        }
        
        return responseText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Private Helpers
    
    // --- !!! ACTION REQUIRED !!! ---
    // This is a placeholder. You need to replace this with your actual
    // logic for getting all text content from your `FileIndexer` or `LibraryManager`.
    private func getContextForProject(_ project: Project) async -> String {
        print("Fetching context for project: \(project.name)...")
        //
        // PSEUDO-CODE:
        // let fileChunks = FileIndexer.shared.getAllChunks(for: project)
        // return fileChunks.map { $0.content }.joined(separator: "\n\n---\n\n")
        //
        // For now, I'll return placeholder text.
        // Replace this with your actual implementation.
        return "This is placeholder text for \(project.name). Replace getContextForProject in LLMManager.swift with your code to fetch all text chunks for a project."
    }
    // --- !!! END ACTION REQUIRED !!! ---
    
    private func generateSmartPrompt(for files: [URL]) -> String {
        return """
        You are a File System Analyst AI assistant named Omni.
        
        CRITICAL RULES:
        1. Answer questions ONLY based on the file content provided in the context.
        2. When citing sources, simply say "According to the file" or "Based on the provided document" - do NOT mention specific filenames.
        3. If the context has no relevant information, say so clearly.
        4. **SYNTHESIS:** If you combine information from multiple sources, say "Based on the provided files" or "According to the documents".
        5. Be natural and conversational - avoid overly formal language.
        """
    }
}
