// MARK: - Omni/Core/Quiz.swift
import Foundation
import SwiftData

// This is the main quiz object, linked to a project
@Model
class Quiz {
    var name: String
    var dateCreated: Date = Date()
    
    // --- THIS IS THE FIX ---
    // We store the UUID of the Project, not a PersistentIdentifier
    var sourceProjectID: UUID?
    // --- END OF FIX ---
    
    @Relationship(deleteRule: .cascade)
    var questions: [QuizQuestion] = []
    
    // The init will now correctly assign the project's ID
    init(name: String, project: Project? = nil) {
        self.name = name
        self.sourceProjectID = project?.id // This now works
    }
}

// This holds a single interactive question
@Model
class QuizQuestion {
    var questionText: String
    var options: [String]
    var correctAnswerIndex: Int
    var explanation: String // The AI's explanation for *why* it's the right answer
    
    init(questionText: String, options: [String], correctAnswerIndex: Int, explanation: String) {
        self.questionText = questionText
        self.options = options
        self.correctAnswerIndex = correctAnswerIndex
        self.explanation = explanation
    }
}

// This is a simple, non-model struct we'll use for decoding
// the LLM's JSON output before creating the SwiftData models.
struct DecodableQuiz: Decodable {
    let name: String
    let questions: [DecodableQuestion]
}

struct DecodableQuestion: Decodable {
    let questionText: String
    let options: [String]
    let correctAnswerIndex: Int
    let explanation: String
}
