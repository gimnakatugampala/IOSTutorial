//
//  TapFrenzyVM.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-07.
//
import SwiftUI
import Combine



class TapFrenzyVM: ObservableObject {
    // MARK: - Game State
    @Published var score: Int = 0
    @Published var timeRemaining: Int = 10
    @Published var isGameOver: Bool = false
    @Published var hasStarted: Bool = false
    @Published var difficulty: GameDifficulty = .easy
    
    // The view will listen to this to know when to jump the button
    @Published var moveTrigger = UUID()
    
    private var gameTimer: AnyCancellable?
    private var moveTimer: AnyCancellable?
    
    // MARK: - Difficulty Settings
    
    // Controls how fast the button jumps
    private var moveInterval: Double {
        switch difficulty {
        case .easy: return 2.0   // Slow
        case .medium: return 1.0 // Medium
        case .hard: return 0.6   // Fast
        }
    }
    
    // Controls the penalty for missing the button
    private var missPenalty: Int {
        switch difficulty {
        case .easy: return 0
        case .medium: return 1
        case .hard: return 1
        }
    }
    
    // MARK: - Intents (User Actions)
    
    func selectDifficulty(_ diff: GameDifficulty) {
        self.difficulty = diff
        startGame()
    }
    
    private func startGame() {
        score = 0
        timeRemaining = 10
        isGameOver = false
        hasStarted = true
        moveTrigger = UUID()
        
        startTimers()
    }
    
    func targetTapped() {
        guard !isGameOver else { return }
        score += 1
    }
    
    func backgroundTapped() {
        guard !isGameOver && hasStarted else { return }
        
        // Deduct points based on difficulty
        score -= missPenalty
        
        // Don't let the score go below zero!
        if score < 0 { score = 0 }
        
        // Trigger haptic error if they lost points
        if missPenalty > 0 {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
    
    // MARK: - Private Logic
    
    private func startTimers() {
        gameTimer?.cancel()
        moveTimer?.cancel()
        
        // 1. The 10-second countdown timer
        gameTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tickTimer()
            }
        
        // 2. The dynamic movement timer (changes based on difficulty!)
        moveTimer = Timer.publish(every: moveInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                // Tell the View to move the button
                self?.moveTrigger = UUID()
            }
    }
    
    private func tickTimer() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            endGame()
        }
    }
    
    private func endGame() {
        isGameOver = true
        gameTimer?.cancel()
        moveTimer?.cancel()
    }
}
