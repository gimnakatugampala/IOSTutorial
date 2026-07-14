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
        case .l1: return 1.5; case .l2: return 1.2; case .l3: return 1.0; case .l4: return 0.8; case .overdrive: return 0.4
        }
    }

    var columns: Int {
        switch self {
        case .l1: return 3; case .l2: return 2; case .l3: return 3; case .l4, .overdrive: return 3
        }
    }

    var glowColor: Color {
        switch self {
        case .l1: return AppTheme.ramp(0); case .l2: return AppTheme.ramp(1); case .l3: return AppTheme.ramp(2); case .l4: return AppTheme.ramp(3); case .overdrive: return AppTheme.ramp(4)
        }
    }

    var label: String {
        switch self {
        case .l1: return "1"; case .l2: return "2"; case .l3: return "3"; case .l4: return "4"; case .overdrive: return "MAX"
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

    // MARK: - Combo / Bonus State (creative additions beyond the base spec)
    @Published var streak = 0
    @Published private(set) var bestStreak = 0
    @Published var lastTapWasGolden = false

    // Accuracy bookkeeping, used to compute the end-of-round performance grade
    private var correctTaps = 0
    private var wrongTaps = 0
    private var missedCards = 0

    /// Chance any given lit card is rolled as a bonus "golden" card (worth 3x).
    private let goldenChance: Double = 0.15
    private let goldenBonusPoints = 3
    /// Every N-streak taps adds +1 bonus point on top of the base value.
    private let streakBonusEvery = 3

    /// The full length of the current round, set by the caller (defaults to 60s to
    /// match the base spec). Level boundaries scale proportionally to this so a
    /// 30s or 90s round still ramps through all 5 stages sensibly.
    private var totalRoundLength: Int = 60

    /// Lives are capped here so leveling up can never push the HUD (which only
    /// draws 3 heart icons) past what it can display.
    private let maxLives = 3

    /// Set true the moment any lit card in the current window is tapped
    /// correctly. Used so a life is only lost when a window is a total whiff —
    /// tapping even one of several simultaneously-lit tiles now protects the
    /// whole window, instead of the untouched extras still costing a life.
    private var hitSomethingThisWindow = false

    // Private Timers
    private var litTimer: AnyCancellable?
    private var roundTimer: AnyCancellable?

    // MARK: - Game Intents
    func startGame(roundLength: Int = 60) {
        score = 0
        streak = 0
        bestStreak = 0
        correctTaps = 0
        wrongTaps = 0
        missedCards = 0
        lastTapWasGolden = false
        hitSomethingThisWindow = false

        totalRoundLength = max(roundLength, 10)
        timeRemaining = totalRoundLength
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
            let golden = cards[card.id].isGolden
            let basePoints = golden ? goldenBonusPoints : 1
            let comboBonus = streak / streakBonusEvery
            score += basePoints + comboBonus

            streak += 1
            bestStreak = max(bestStreak, streak)
            correctTaps += 1
            lastTapWasGolden = golden
            hitSomethingThisWindow = true

            cards[card.id].isLit = false
            cards[card.id].isGolden = false
        } else {
            // Tapping a dark tile no longer costs a life on its own — it's only
            // tracked for the accuracy stat. Life loss is decided once per
            // window (see lightUpCards) based on whether the lit tile(s) were
            // ever tapped, so a single window can only ever cost at most 1 life.
            wrongTaps += 1
        }
    }

    // MARK: - Performance Grade (creative end-of-round summary)
    var accuracy: Double {
        let totalAttempts = correctTaps + wrongTaps + missedCards
        guard totalAttempts > 0 else { return 0 }
        return Double(correctTaps) / Double(totalAttempts)
    }

    /// A simple report-card grade combining accuracy and best combo, so the
    /// game-over screen reflects skill, not just raw score.
    var performanceGrade: String {
        if accuracy >= 0.95 && bestStreak >= 12 { return "S" }
        if accuracy >= 0.85 { return "A" }
        if accuracy >= 0.7 { return "B" }
        if accuracy >= 0.5 { return "C" }
        return "D"
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
        
        // Penalize only on a total whiff. At L4/overdrive several cards are lit
        // at once — as long as the player tapped at least ONE of them correctly
        // this window, no life is lost, even if the others expired untapped.
        // Missed cards are still logged for the accuracy/grade stat either way.
        let missed = cards.filter { $0.isLit }.count
        if missed > 0 {
            registerMiss(livesLost: hitSomethingThisWindow ? 0 : 1, missedCount: missed)
        }
        hitSomethingThisWindow = false
        
        guard !gameOver else { return }
        
        // Reset and light new cards
        for i in cards.indices {
            cards[i].isLit = false
            cards[i].isGolden = false
        }

        let toLight = cards.shuffled().prefix(level.litCount)
        var goldenAssigned = false
        for lit in toLight {
            cards[lit.id].isLit = true
            if !goldenAssigned && Double.random(in: 0...1) < goldenChance {
                cards[lit.id].isGolden = true
                goldenAssigned = true
            }
        }
    }

    private func registerMiss(livesLost: Int, missedCount: Int) {
        missedCards += missedCount
        guard livesLost > 0 else { return }
        streak = 0
        lives -= livesLost
        if lives <= 0 { endGame() }
    }

    private func rebuildCards() {
        cards = (0..<level.cardCount).map { Card(id: $0) }
    }

    private func updateLevel() {
        let elapsed = totalRoundLength - timeRemaining
        let fraction = Double(elapsed) / Double(totalRoundLength)
        let newLevel: GameLevel

        // L1-L4 occupy the spec'd proportions (25% / 25% / 25% / ~16.7%) of the
        // round; the final ~8.3% is reserved for the bonus "overdrive" finale so
        // it never eats into L4's window. At roundLength = 60 this reproduces
        // the exact slide brackets: 0-15 / 15-30 / 30-45 / 45-55 / 55-60.
        switch fraction {
        case ..<0.25: newLevel = .l1
        case 0.25..<0.50: newLevel = .l2
        case 0.50..<0.75: newLevel = .l3
        case 0.75..<(11.0 / 12.0): newLevel = .l4
        default: newLevel = .overdrive
        }
        
        if newLevel != level {
            level = newLevel
            showLevelFlash = true

            // Reward surviving to the next level with a bonus life (never above
            // the starting max of 3, so the 3-heart HUD always has room to show it).
            if lives < maxLives {
                lives += 1
            }
            
            // Turn off the flash after long enough for the player to actually read it
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { [weak self] in
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
