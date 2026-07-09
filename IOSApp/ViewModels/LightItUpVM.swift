//
//  LightItUpVM.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-07.
//
import SwiftUI
import Combine

// MARK: - Level config
enum GameLevel {
    case l1, l2, l3, l4, overdrive

    var cardCount: Int {
        switch self {
        case .l1: return 3; case .l2: return 4; case .l3: return 6; case .l4: return 9; case .overdrive: return 9
        }
    }

    var litCount: Int {
        switch self {
        case .overdrive: return 3; case .l4: return 2; default: return 1
        }
    }

    var litWindow: Double {
        switch self {
        case .l1: return 1.5; case .l2: return 1.2; case .l3: return 0.9; case .l4: return 0.65; case .overdrive: return 0.4
        }
    }

    var columns: Int {
        switch self {
        case .l1: return 3; case .l2: return 2; case .l3: return 3; case .l4, .overdrive: return 3
        }
    }

    var glowColor: Color {
        switch self {
        case .l1: return .green; case .l2: return .cyan; case .l3: return .yellow; case .l4: return .orange; case .overdrive: return .red
        }
    }
}

class LightItUpVM: ObservableObject {
    // MARK: - Published State (The View watches these)
    @Published var timeRemaining = 60
    @Published var score = 0
    @Published var lives = 3
    @Published var cards: [Card] = []
    @Published var gameOver = false
    @Published var level: GameLevel = .l1
    @Published var showLevelFlash = false
    @Published var pulseBackground = false

    // Private Timers
    private var litTimer: AnyCancellable?
    private var roundTimer: AnyCancellable?

    // MARK: - Game Intents
    func startGame() {
        score = 0
        timeRemaining = 60
        lives = 3
        gameOver = false
        level = .l1
        pulseBackground = false
        
        rebuildCards()
        startLitTimer()
        startRoundTimer()
    }

    func handleTap(card: Card) {
        guard !gameOver else { return }
        
        if cards[card.id].isLit {
            score += 1
            cards[card.id].isLit = false
        } else {
            lives -= 1
            if lives <= 0 { endGame() }
        }
    }

    // MARK: - Private Game Logic
    private func startRoundTimer() {
        roundTimer?.cancel()
        roundTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tickRound()
            }
    }

    private func tickRound() {
        guard !gameOver else { return }
        if timeRemaining > 0 {
            timeRemaining -= 1
            updateLevel()
        } else {
            endGame()
        }
    }

    private func startLitTimer() {
        litTimer?.cancel()
        litTimer = Timer.publish(every: level.litWindow, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.lightUpCards()
            }
    }

    private func lightUpCards() {
        guard !gameOver else { return }
        
        // Penalize for missed cards
        let missed = cards.filter { $0.isLit }.count
        if missed > 0 {
            lives -= missed
            if lives <= 0 { endGame() }
        }
        
        guard !gameOver else { return }
        
        // Reset and light new cards
        for i in cards.indices { cards[i].isLit = false }
        cards.shuffled().prefix(level.litCount).forEach { cards[$0.id].isLit = true }
    }

    private func rebuildCards() {
        cards = (0..<level.cardCount).map { Card(id: $0) }
    }

    private func updateLevel() {
        let elapsed = 60 - timeRemaining
        let newLevel: GameLevel
        
        switch elapsed {
        case 0..<15: newLevel = .l1
        case 15..<30: newLevel = .l2
        case 30..<40: newLevel = .l3
        case 40..<50: newLevel = .l4
        default: newLevel = .overdrive
        }
        
        if newLevel != level {
            level = newLevel
            showLevelFlash = true
            
            // Turn off the flash after 0.2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.showLevelFlash = false
            }
            
            rebuildCards()
            startLitTimer()
        }
    }

    private func endGame() {
        litTimer?.cancel()
        roundTimer?.cancel()
        gameOver = true
    }
}
