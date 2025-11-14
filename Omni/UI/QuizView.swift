// MARK: - UI/QuizView.swift
import SwiftUI
import SwiftData

struct QuizView: View {
    let quiz: Quiz
    
    @State private var currentQuestionIndex = 0
    @State private var selectedOption: Int? = nil
    @State private var isAnswerSubmitted = false
    @State private var score = 0
    
    @Environment(\.dismiss) private var dismiss
    
    private var currentQuestion: QuizQuestion {
        quiz.questions[currentQuestionIndex]
    }
    
    private var isQuizFinished: Bool {
        currentQuestionIndex == quiz.questions.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Quiz Content
            if isQuizFinished {
                quizFinishedView
            } else {
                quizQuestionView
            }
            
            // Footer
            footerView
        }
        .frame(minWidth: 600, maxWidth: 800, minHeight: 500, maxHeight: 700)
        .background(Color(hex: "1E1E1E"))
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(quiz.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Text("Generated from your documents. Good luck!")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "888888"))
            }
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "666666"))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color(hex: "252525")))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape)
        }
        .padding(20)
        .background(Color(hex: "1A1A1A"))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "2A2A2A")), alignment: .bottom)
    }
    
    private var quizQuestionView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Question Text
                Text("Question \(currentQuestionIndex + 1) of \(quiz.questions.count)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "FF6B6B"))
                
                Text(currentQuestion.questionText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "EAEAEA"))
                    .lineSpacing(4)
                
                // Options
                VStack(spacing: 12) {
                    ForEach(0..<currentQuestion.options.count, id: \.self) { index in
                        optionButton(text: currentQuestion.options[index], index: index)
                    }
                }
                
                // AI Explanation (if answered)
                if isAnswerSubmitted {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI Explanation")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "AAAAAA"))
                        Text(currentQuestion.explanation)
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "999999"))
                            .lineSpacing(3)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "252525"))
                    .cornerRadius(8)
                }
            }
            .padding(30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var quizFinishedView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: score > (quiz.questions.count / 2) ? "sparkles" : "graduationcap.fill")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "FF6B6B"))
            
            VStack(spacing: 6) {
                Text("Quiz Complete!")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Text("You scored \(score) out of \(quiz.questions.count)")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "AAAAAA"))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var footerView: some View {
        HStack {
            Spacer()
            if isQuizFinished {
                Button("Close") { dismiss() }
                    .buttonStyle(QuizButtonStyle(color: Color(hex: "FF6B6B")))
            } else if isAnswerSubmitted {
                Button("Next Question") {
                    currentQuestionIndex += 1
                    isAnswerSubmitted = false
                    selectedOption = nil
                }
                .buttonStyle(QuizButtonStyle(color: Color(hex: "FF6B6B")))
            } else {
                Button("Submit Answer") {
                    if let selectedOption = selectedOption {
                        isAnswerSubmitted = true
                        if selectedOption == currentQuestion.correctAnswerIndex {
                            score += 1
                        }
                    }
                }
                .disabled(selectedOption == nil)
                .buttonStyle(QuizButtonStyle(color: Color(hex: "FF6B6B"), disabled: selectedOption == nil))
            }
        }
        .padding(20)
        .background(Color(hex: "1A1A1A"))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "2A2A2A")), alignment: .top)
    }
    
    // MARK: - Components
    
    @ViewBuilder
    private func optionButton(text: String, index: Int) -> some View {
        let isSelected = selectedOption == index
        let isCorrect = index == currentQuestion.correctAnswerIndex
        
        Button(action: {
            if !isAnswerSubmitted {
                selectedOption = index
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? Color(hex: "FF6B6B") : Color(hex: "666666"))
                
                Text(text)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "AAAAAA"))
                
                Spacer()
                
                if isAnswerSubmitted {
                    Image(systemName: isCorrect ? "checkmark.circle" : (isSelected ? "xmark.circle" : ""))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isCorrect ? .green : .red)
                }
            }
            .padding(16)
            .background(Color(hex: "252525"))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color(hex: "FF6B6B").opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    struct QuizButtonStyle: ButtonStyle {
        let color: Color
        var disabled: Bool = false
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(color)
                .cornerRadius(7)
                .opacity(disabled ? 0.4 : (configuration.isPressed ? 0.8 : 1.0))
        }
    }
}
