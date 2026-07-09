//
//  QuizRushVM.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-07.
//
import SwiftUI
import Combine


// MARK: - ViewModel State
enum ViewState {
    case loading, loaded, failed
}

@MainActor
class QuizRushViewModel: ObservableObject {
    @Published var state: ViewState = .loading
    @Published var questions: [QuizQuestion] = []
    @Published var currentIndex = 0
    @Published var score = 0
    @Published var streak = 0
    @Published var isGameOver = false
    
    @Published var answerFeedback: Bool? = nil
    @Published var shakeOffset: CGFloat = 0
    
    func loadQuestions() async {
        state = .loading
        do {
            let url = URL(string: "https://opentdb.com/api.php?amount=10&type=multiple&encode=base64")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedResponse = try JSONDecoder().decode(TriviaResponse.self, from: data)
            
            if decodedResponse.results.isEmpty {
                self.state = .failed
                return
            }
            
            self.questions = decodedResponse.results.map { QuizQuestion(from: $0) }
            self.resetGameStats()
            self.state = .loaded
            
        } catch {
            self.state = .failed
        }
    }
    
    func resetGameStats() {
        currentIndex = 0
        score = 0
        streak = 0
        isGameOver = false
        answerFeedback = nil
    }
    
    func checkAnswer(_ answer: String) {
        guard currentIndex < questions.count, answerFeedback == nil else { return }
        let isCorrect = answer == questions[currentIndex].correctAnswer
        
        if isCorrect {
            score += 10 + (streak * 5)
            streak += 1
            answerFeedback = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            score = max(0, score - 5)
            streak = 0
            answerFeedback = false
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            
            withAnimation(.linear(duration: 0.1)) { self.shakeOffset = 10 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.linear(duration: 0.1)) { self.shakeOffset = -10 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.linear(duration: 0.1)) { self.shakeOffset = 0 }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.answerFeedback = nil
            if self.currentIndex < self.questions.count - 1 {
                self.currentIndex += 1
            } else {
                self.isGameOver = true
            }
        }
    }
}
