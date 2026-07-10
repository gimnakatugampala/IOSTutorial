import SwiftUI
import Combine

struct TapFrenzyView: View {
    @StateObject private var vm = TapFrenzyVM()
    
    @EnvironmentObject var statsVM: StatsVM
    @EnvironmentObject var locationService: LocationService

    @State private var buttonPosition = CGPoint(x: 200, y: 400)
    @State private var buttonSize: CGFloat = 200
    
    // 🚨 1. Separate High Scores for each difficulty!
    @AppStorage("tapFrenzyHighScore_easy") private var highScoreEasy = 0
    @AppStorage("tapFrenzyHighScore_medium") private var highScoreMedium = 0
    @AppStorage("tapFrenzyHighScore_hard") private var highScoreHard = 0
    
    @Environment(\.dismiss) private var dismiss

    // Dynamically get the right high score to show
    var currentHighScore: Int {
        switch vm.difficulty {
        case .easy: return highScoreEasy
        case .medium: return highScoreMedium
        case .hard: return highScoreHard
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                LinearGradient(
                    colors: [AppTheme.background, AppTheme.tapFrenzy.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                // 🚨 2. Detect missed taps on the background!
                .onTapGesture {
                    vm.backgroundTapped()
                }

                if !vm.hasStarted {
                    // Pre-game Difficulty Menu
                    difficultySelectionMenu(in: geometry)
                } else {
                    // The Game
                    VStack {
                        HStack(spacing: 15) {
                            Button { dismiss() } label: { Image(systemName: "chevron.left.circle.fill").font(.system(size: 40)).foregroundStyle(.white.opacity(0.8), .ultraThinMaterial) }
                            statCard(icon: "trophy.fill", title: "SCORE", value: "\(vm.score)", color: .orange)
                            statCard(icon: "timer", title: "TIME", value: "\(vm.timeRemaining)", color: .cyan)
                        }
                        .padding(.horizontal)
                        Spacer()
                    }
                    .padding(.top)

                    if !vm.isGameOver {
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            vm.targetTapped()
                            
                            withAnimation(.spring()) {
                                if buttonSize > 50 { buttonSize -= 10 }
                            }
                        } label: {
                            Circle()
                                .fill(RadialGradient(gradient: Gradient(colors: [.pink, .red.opacity(0.8)]), center: .topLeading, startRadius: 10, endRadius: buttonSize))
                                
                                // The Border
                                .overlay(
                                    Circle().strokeBorder(LinearGradient(colors: [.white.opacity(0.6), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 4)
                                )
                                
                                // Static Font Size + GPU Scale Effect
                                .overlay(
                                    Text("TAP")
                                        .font(.system(size: 50, weight: .black, design: .rounded)) // Static size!
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.3), radius: 2, y: 2)
                                        .scaleEffect(buttonSize / 200) // GPU scaling based on the original 200 max size
                                        .fixedSize() // Locks the layout frame
                                )
                                .frame(width: buttonSize, height: buttonSize)
                                .shadow(color: .red.opacity(0.6), radius: 20, y: 10)
                        }
                        .position(buttonPosition)
                    } else {
                        gameOverMenu(in: geometry)
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            // 🚨 3. The View just listens to the VM to know when to jump!
            .onChange(of: vm.moveTrigger) { _ in
                let x = CGFloat.random(in: 60...(geometry.size.width - 60))
                let y = CGFloat.random(in: 180...(geometry.size.height - 150))
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    buttonPosition = CGPoint(x: x, y: y)
                }
            }
            .onChange(of: vm.timeRemaining) { newValue in
                withAnimation(.easeInOut(duration: 1.0)) {
                    buttonSize = 50 + CGFloat(newValue) * 15
                }
            }
        }
    }

    // MARK: - UI Components
    
    @ViewBuilder
    func difficultySelectionMenu(in geometry: GeometryProxy) -> some View {
        VStack(spacing: 30) {
            Text("Select Difficulty")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(.white)
            
            ForEach(GameDifficulty.allCases) { diff in
                Button {
                    // Start GPS fetch early!
                    locationService.fetchLocation()
                    buttonPosition = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    vm.selectDifficulty(diff)
                } label: {
                    Text(diff.rawValue)
                        .font(.title2).bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(color(for: diff))
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
            }
            
            Button { dismiss() } label: {
                Text("Back to Main Menu").foregroundColor(.gray)
            }
        }
        .padding(40)
        .background(.ultraThinMaterial)
        .cornerRadius(30)
        .padding(30)
    }
    
    func color(for diff: GameDifficulty) -> Color {
        switch diff {
        case .easy: return AppTheme.success
        case .medium: return AppTheme.warning
        case .hard: return AppTheme.danger
        }
    }

    func statCard(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.title2).foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.6))
                Text(value).font(.system(size: 20, weight: .black, design: .rounded)).foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1), lineWidth: 1))
    }
    
    @ViewBuilder
    func gameOverMenu(in geometry: GeometryProxy) -> some View {
        VStack(spacing: 25) {
            Image(systemName: "trophy.fill").font(.system(size: 70)).foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)).shadow(color: .orange.opacity(0.5), radius: 10)
            Text("GAME OVER").font(.system(size: 32, weight: .black, design: .rounded)).foregroundColor(.white)
            
            // Show difficulty played
            Text("Difficulty: \(vm.difficulty.rawValue)").foregroundColor(.white.opacity(0.8))

            VStack(spacing: 5) {
                Text("Final Score").font(.subheadline).foregroundColor(.white.opacity(0.7))
                Text("\(vm.score)").font(.system(size: 60, weight: .black, design: .rounded)).foregroundColor(.white)
            }
            
            Text(vm.score >= currentHighScore ? "🏆 New High Score!" : "Best (\(vm.difficulty.rawValue)): \(currentHighScore)")
                .font(.headline)
                .foregroundColor(vm.score >= currentHighScore ? .yellow : .white.opacity(0.5))

            VStack(spacing: 15) {
                Button {
                    vm.hasStarted = false // Go back to difficulty menu
                } label: {
                    Text("Play Again").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 16).background(LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)).foregroundColor(.white).cornerRadius(16)
                }
                
                Button { dismiss() } label: {
                    Text("Main Menu").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 16).background(.ultraThinMaterial).foregroundColor(.white).cornerRadius(16).overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.2), lineWidth: 1))
                }
            }
        }
        .padding(40)
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.4))
        .cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(.white.opacity(0.2), lineWidth: 1))
        .padding(.horizontal, 30)
        .onAppear {
            saveHighScore()
            statsVM.saveNewSession(
                mode: .tapFrenzy,
                score: vm.score,
                lat: locationService.latitude,
                lon: locationService.longitude
            )
        }
    }

    func saveHighScore() {
        switch vm.difficulty {
        case .easy: if vm.score > highScoreEasy { highScoreEasy = vm.score }
        case .medium: if vm.score > highScoreMedium { highScoreMedium = vm.score }
        case .hard: if vm.score > highScoreHard { highScoreHard = vm.score }
        }
    }
}
