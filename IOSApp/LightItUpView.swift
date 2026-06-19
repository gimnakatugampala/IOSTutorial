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
        case .l2: return .blue
        case .l3: return .yellow
        case .l4: return .red
        }
    }
}

// MARK: - LightItUpView
struct LightItUpView: View {
    @State private var timeRemaining = 60
    @State private var score = 0
    @State private var cards: [Card] = []
    @State private var gameOver = false
    @State private var level: GameLevel = .l1

    @AppStorage("lightItUpHighScore") private var highScore = 0

    let roundTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var litTimer: AnyCancellable? = nil

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(red: 0.1, green: 0.1, blue: 0.15).ignoresSafeArea()

                if gameOver {
                    VStack(spacing: 20) {
                        Text("Time's Up!")
                            .font(.largeTitle).bold().foregroundColor(.white)
                        Text("Score: \(score)")
                            .font(.title).foregroundColor(.white)
                        if score >= highScore {
                            Text("🏆 New High Score!")
                                .foregroundColor(.yellow)
                        } else {
                            Text("Best: \(highScore)")
                                .foregroundColor(.gray)
                        }
                        Button("Play Again") { restartGame() }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Score: \(score)")
                                .font(.title2).bold().foregroundColor(.white)
                            Spacer()
                            Text("Time: \(timeRemaining)s")
                                .font(.title2).foregroundColor(.white)
                        }
                        .padding(.horizontal)

                        Text("Level \(levelLabel)")
                            .font(.headline)
                            .foregroundColor(level.glowColor)

                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: level.columns),
                            spacing: 12
                        ) {
                            ForEach(cards) { card in
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(card.isLit ? level.glowColor : Color(white: 0.2))
                                    .frame(height: 100)
                                    .scaleEffect(card.isLit ? 1.08 : 1.0)
                                    .shadow(color: card.isLit ? level.glowColor.opacity(0.7) : .clear, radius: 12)
                                    .animation(.easeInOut(duration: 0.15), value: card.isLit)
                                    .onTapGesture { handleTap(card) }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
            }
        }
        .navigationTitle("Light It Up")
        .navigationBarTitleDisplayMode(.inline)
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

    // MARK: - Helpers
    var levelLabel: String {
        switch level {
        case .l1: return "1"
        case .l2: return "2"
        case .l3: return "3"
        case .l4: return "4"
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
        // dim all first
        for i in cards.indices { cards[i].isLit = false }
        // pick random lit cards
        let picks = (0..<cards.count).shuffled().prefix(level.litCount)
        for i in picks { cards[i].isLit = true }
    }

    func handleTap(_ card: Card) {
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else { return }
        withAnimation {
            if cards[index].isLit {
                score += 1
                cards[index].isLit = false
            } else {
                score = max(0, score - 1)
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
        gameOver = false
        startGame()
    }
}
