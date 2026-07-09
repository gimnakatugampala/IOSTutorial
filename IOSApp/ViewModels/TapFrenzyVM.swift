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
    
    // We use Combine's AnyCancellable to hold the timer in memory so we can stop it later
    private var timerSubscription: AnyCancellable?
    
    // MARK: - Intents (User Actions)
    
    func startGame() {
        // 1. Reset everything to default values
        score = 0
        timeRemaining = 10
        isGameOver = false
        
        // 2. Start a timer that ticks exactly once per second
        timerSubscription = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tickTimer()
            }
    }
    
    func tapRegistered() {
        // If the game is over, taps shouldn't do anything
        guard !isGameOver else { return }
        
        // Base requirement: +1 point per tap.
        // (If you chose the Combo or Trap challenges from the Week 1 slides, add that logic here!)
        score += 1
    }
    
    // MARK: - Private Logic
    
    private func tickTimer() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            endGame()
        }
    }
    
    private func endGame() {
        isGameOver = true
        // Cancel the timer so it doesn't keep running in the background and drain battery
        timerSubscription?.cancel()
    }
}
