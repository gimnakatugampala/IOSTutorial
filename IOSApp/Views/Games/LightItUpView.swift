import SwiftUI
import Combine

// MARK: - Level config
enum GameLevel {
    case l1, l2, l3, l4, overdrive

    var cardCount: Int {
        switch self {
        case .l1: return 3
        case .l2: return 4
        case .l3: return 6
        case .l4: return 9
        case .overdrive: return 9
        }
    }

    var litCount: Int {
        switch self {
        case .overdrive: return 3
        case .l4: return 2
        default: return 1
        }
    }

    var litWindow: Double {
        switch self {
        case .l1: return 1.5
        case .l2: return 1.2
        case .l3: return 0.9
        case .l4: return 0.65
        case .overdrive: return 0.4
        }
    }

    var columns: Int {
        switch self {
        case .l1: return 3
        case .l2: return 2
        case .l3: return 3
        case .l4, .overdrive: return 3
        }
    }

    var glowColor: Color {
        switch self {
        case .l1: return .green
        case .l2: return .cyan
        case .l3: return .yellow
        case .l4: return .orange
        case .overdrive: return .red
        }
    }
}

// MARK: - LightItUpView
struct LightItUpView: View {
    // FIXED: Added @State initialization for lives
    @State private var timeRemaining = 60
    @State private var score = 0
    @State private var lives = 3
    @State private var cards: [Card] = []
    @State private var gameOver = false
    @State private var level: GameLevel = .l1
    @State private var showLevelFlash = false
    @State private var pulseBackground = false

    @AppStorage("lightItUpHighScore") private var highScore = 0
    @Environment(\.dismiss) private var dismiss

    let roundTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var litTimer: AnyCancellable? = nil

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.08).ignoresSafeArea()
                
                // Panic Mode
                if level == .overdrive {
                    Color.red.opacity(pulseBackground ? 0.3 : 0.05)
                        .ignoresSafeArea()
                        .animation(.easeInOut(duration: 0.3).repeatForever(), value: pulseBackground)
                        .onAppear { pulseBackground = true }
                }
                
                if showLevelFlash {
                    level.glowColor.opacity(0.4)
                        .ignoresSafeArea()
                        .zIndex(10)
                        .transition(.opacity)
                }

                if gameOver {
                    gameOverMenu
                } else {
                    VStack(spacing: 20) {
                        hudView
                        
                        // Level Indicator
                        Text(level == .overdrive ? "⚠️ OVERDRIVE ⚠️" : "LEVEL \(levelLabel)")
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .foregroundColor(level.glowColor)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 20)
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: level.columns), spacing: 15) {
                            ForEach(cards) { card in
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(card.isLit ? .white : Color.white.opacity(0.05))
                                    .frame(height: 110)
                                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(card.isLit ? level.glowColor : .white.opacity(0.1), lineWidth: card.isLit ? 4 : 1))
                                    .shadow(color: card.isLit ? level.glowColor : .clear, radius: card.isLit ? 15 : 0)
                                    .scaleEffect(card.isLit ? 1.05 : (level == .overdrive ? 0.9 : 1.0))
                                    .onTapGesture { handleTap(card) }
                            }
                        }
                        .padding(.horizontal, 25)
                        Spacer()
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear { startGame() }
        .onReceive(roundTimer) { _ in
            guard !gameOver else { return }
            if timeRemaining > 0 {
                timeRemaining -= 1
                updateLevel()
                if timeRemaining <= 10 && level == .overdrive {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                }
            } else {
                endGame()
            }
        }
    }
    
    var hudView: some View {
        HStack {
            Button { dismiss() } label: { Image(systemName: "chevron.left.circle.fill").font(.title).foregroundColor(.white.opacity(0.6)) }
            Spacer()
            VStack { Text("SCORE").font(.system(size: 10, weight: .bold)); Text("\(score)").font(.title2).bold() }
            Spacer()
            HStack(spacing: 4) { ForEach(0..<3, id: \.self) { i in Image(systemName: "heart.fill").foregroundColor(i < lives ? .red : .gray) } }
            Spacer()
            VStack { Text("TIME").font(.system(size: 10, weight: .bold)); Text("\(timeRemaining)").font(.title2).bold() }
        }.padding(.horizontal, 20)
    }

    var gameOverMenu: some View {
        VStack(spacing: 20) {
            Text(lives <= 0 ? "GAME OVER" : "TIME'S UP").font(.largeTitle).bold()
            Text("Score: \(score)").font(.title)
            Button("Play Again") { restartGame() }.padding().background(Color.blue).cornerRadius(10)
            Button("Main Menu") { dismiss() }.padding().background(Color.gray).cornerRadius(10)
        }
    }

    var levelLabel: String {
        switch level {
        case .l1: return "1"; case .l2: return "2"; case .l3: return "3"; case .l4: return "4"; case .overdrive: return "MAX"
        }
    }

    func startGame() {
        level = .l1
        lives = 3
        rebuildCards()
        startLitTimer()
    }

    func rebuildCards() { cards = (0..<level.cardCount).map { Card(id: $0) } }
    
    func startLitTimer() {
        litTimer?.cancel()
        litTimer = Timer.publish(every: level.litWindow, on: .main, in: .common).autoconnect().sink { _ in lightUpCards() }
    }

    func lightUpCards() {
        guard !gameOver else { return }
        let missed = cards.filter { $0.isLit }.count
        if missed > 0 {
            lives -= missed
            if lives <= 0 { endGame() }
        }
        guard !gameOver else { return }
        for i in cards.indices { cards[i].isLit = false }
        cards.shuffled().prefix(level.litCount).forEach { cards[$0.id].isLit = true }
    }

    func handleTap(_ card: Card) {
        guard !gameOver else { return }
        if cards[card.id].isLit {
            score += 1
            cards[card.id].isLit = false
        } else {
            lives -= 1
            if lives <= 0 { endGame() }
        }
    }

    func updateLevel() {
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { showLevelFlash = false }
            rebuildCards()
            startLitTimer()
        }
    }

    func endGame() {
        litTimer?.cancel()
        if score > highScore { highScore = score }
        gameOver = true
    }

    func restartGame() {
        score = 0; timeRemaining = 60; lives = 3; gameOver = false; startGame()
    }
}
