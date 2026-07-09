//
//  QuizQuestion.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-10.
//

import Foundation

// MARK: - API Models
struct TriviaResponse: Codable {
    let response_code: Int?
    let results: [TriviaResult]
}

struct TriviaResult: Codable {
    let question: String
    let correct_answer: String
    let incorrect_answers: [String]
}

// MARK: - App Model
struct QuizQuestion: Identifiable {
    let id = UUID()
    let text: String
    let correctAnswer: String
    let answers: [String]
    
    init(from apiResult: TriviaResult) {
        self.text = apiResult.question.base64Decoded
        self.correctAnswer = apiResult.correct_answer.base64Decoded
        
        var allAnswers = apiResult.incorrect_answers.map { $0.base64Decoded }
        allAnswers.append(self.correctAnswer)
        self.answers = allAnswers.shuffled()
    }
}

