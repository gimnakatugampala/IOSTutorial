import SwiftUI
import Combine

// MARK: - Level config
enum GameLevel {
    case l1, l2, l3, l4
    var cardCount: Int {
        switch self {
        case .l1: return 3
        case .l2: return 4
        case .l3: return 6
        case .l4: return 9
        }
    }
    var litCount: Int { self == .l4 ? 2 : 1 }
    var litWindow: Double {
        switch self {
        case .l1: return 1.5
        case .l2: return 1.2
        case .l3: return 1.0
        case .l4: return 0.8
        }
    }
    var columns: Int {
        switch self {
        case .l1: return 3
        case .l2: return 2
        case .l3: return 3
        case .l4: return 3
        }
    }
    var glowColor: Color {
        switch self {
        case .l1: return .green
        case .l2: return .cyan
        case .l3: return .yellow
        case .l4: return .red
        }
    }
}

// MARK: - LightItUpView
struct LightItUpView: View {
    @State private var timeRemaining = 60
    @State private var score = 0
    @State private var lives = 3
    @State private var cards: [Card] = []
    @State private var gameOver = false
    @State private var level: GameLevel = .l1
    @State private var showLevelFlash = false

    @AppStorage("lightItUpHighScore") private var highScore = 0
    @Environment(\.dismiss) private var dismiss

    let roundTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var litTimer: AnyCancellable? = nil

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Deep dark background
                Color(red: 0.05, green: 0.05, blue: 0.08).ignoresSafeArea()
                
                if showLevelFlash {
                    level.glowColor.opacity(0.3)
                        .ignoresSafeArea()
                        .zIndex(10)
                        .transition(.opacity)
                }

                if gameOver {
                    gameOverMenu
                } else {
                    VStack(spacing: 20) {
                        // HUD
                        HStack {
                            Button { dismiss() } label: {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            VStack(spacing: 4) {
                                Text("SCORE")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white.opacity(0.5))
                                Text("\(score)")
                                    .font(.system(size: 24, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                ForEach(0..<3, id: \.self) { i in
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(i < lives ? .red : .white.opacity(0.1))
                                        .shadow(color: i < lives ? .red.opacity(0.5) : .clear, radius: 5)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(spacing: 4) {
                                Text("TIME")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white.opacity(0.5))
                                Text("\(timeRemaining)")
                                    .font(.system(size: 24, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                        // Level Indicator
                        HStack(spacing: 10) {
                            Text("LEVEL \(levelLabel)")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(level.glowColor)
                                .shadow(color: level.glowColor.opacity(0.8), radius: 5)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(level.glowColor.opacity(0.3), lineWidth: 1))

                        // Grid
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: level.columns),
                            spacing: 15
                        ) {
                            ForEach(cards) { card in
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    // Neon effect logic
                                    .fill(card.isLit ? .white : Color.white.opacity(0.05))
                                    .frame(height: 110)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(card.isLit ? level.glowColor : .white.opacity(0.1), lineWidth: card.isLit ? 4 : 1)
                                    )
                                    .shadow(color: card.isLit ? level.glowColor : .clear, radius: card.isLit ? 15 : 0)
                                    .shadow(color: card.isLit ? level.glowColor.opacity(0.5) : .clear, radius: 30)
                                    .scaleEffect(card.isLit ? 1.05 : 1.0)
                                    .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.6), value: card.isLit)
                                    .onTapGesture { handleTap(card) }
                            }
                        }
                        .padding(.horizontal, 25)
                        
                        Spacer()
                    }
                    .padding(.top, 10)
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
            } else {
                endGame()
            }
        }
    }
    
    // Extracted Game Over Menu for cleaner code
    var gameOverMenu: some View {
        VStack(spacing: 20) {
            Text(lives <= 0 ? "GAME OVER" : "TIME'S UP")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(.white)
            
            Text("Score: \(score)")
                .font(.title2).bold().foregroundColor(.white)
            
            if score >= highScore && score > 0 {
                Text("🏆 New High Score!")
                    .font(.headline)
                    .foregroundColor(.yellow)
            } else {
                Text("Best: \(highScore)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            VStack(spacing: 15) {
                Button { restartGame() } label: {
                    Text("Play Again")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(level.glowColor)
                        .foregroundColor(.black)
                        .cornerRadius(16)
                        .shadow(color: level.glowColor.opacity(0.5), radius: 10, y: 5)
                }
                
                Button { dismiss() } label: {
                    Text("Main Menu")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.ultraThinMaterial)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.2), lineWidth: 1))
                }
            }
            .padding(.top, 20)
        }
        .padding(40)
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.6))
        .cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(.white.opacity(0.2), lineWidth: 1))
        .padding(.horizontal, 30)
    }

    // MARK: - Helpers
    var levelLabel: String {
        switch level {
        case .l1: return "1"; case .l2: return "2"; case .l3: return "3"; case .l4: return "4"
        }
    }

    func startGame() {
        level = .l1
        rebuildCards()
        startLitTimer()
    }

    func rebuildCards() {
        cards = (0..<level.cardCount).map { Card(id: $0) }
    }

    func startLitTimer() {
        litTimer?.cancel()
        litTimer = Timer.publish(every: level.litWindow, on: .main, in: .common)
            .autoconnect()
            .sink { _ in lightUpCards() }
    }

    func lightUpCards() {
        guard !gameOver else { return }
        
        let missedCards = cards.filter { $0.isLit }.count
        if missedCards > 0 {
            withAnimation {
                lives -= missedCards
                if lives <= 0 { endGame() }
            }
        }
        
        guard !gameOver else { return }

        for i in cards.indices { cards[i].isLit = false }
        
        let picks = (0..<cards.count).shuffled().prefix(level.litCount)
        for i in picks { cards[i].isLit = true }
    }

    func handleTap(_ card: Card) {
        guard !gameOver, let index = cards.firstIndex(where: { $0.id == card.id }) else { return }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: cards[index].isLit ? .heavy : .rigid)
        generator.impactOccurred()
        
        withAnimation {
            if cards[index].isLit {
                score += 1
                cards[index].isLit = false
            } else {
                lives -= 1
                if lives <= 0 { endGame() }
            }
        }
    }

    func updateLevel() {
        let elapsed = 60 - timeRemaining
        let newLevel: GameLevel
        switch elapsed {
        case 0..<15:  newLevel = .l1
        case 15..<30: newLevel = .l2
        case 30..<45: newLevel = .l3
        default:      newLevel = .l4
        }
        
        if newLevel != level {
            level = newLevel
            withAnimation(.easeInOut(duration: 0.1)) { showLevelFlash = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.2)) { showLevelFlash = false }
            }
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
        score = 0
        timeRemaining = 60
        lives = 3
        gameOver = false
        startGame()
    }
}

#Preview {
    NavigationStack {
        LightItUpView()
    }
}
