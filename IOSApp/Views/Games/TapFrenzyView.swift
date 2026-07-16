import SwiftUI
import Combine

struct TapFrenzyView: View {
    @StateObject private var vm = TapFrenzyVM()

    @EnvironmentObject var statsVM: StatsVM
    @EnvironmentObject var locationService: LocationService

    // Purely presentational state — where the target sits and how big it is.
    // Game rules (scoring, timing, penalties) all live in TapFrenzyVM.
    @State private var buttonPosition = CGPoint(x: 200, y: 400)
    @State private var buttonSize: CGFloat = 200

    @AppStorage("tapFrenzyHighScore_easy") private var highScoreEasy = 0
    @AppStorage("tapFrenzyHighScore_medium") private var highScoreMedium = 0
    @AppStorage("tapFrenzyHighScore_hard") private var highScoreHard = 0

    @Environment(\.dismiss) private var dismiss

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
                // Background — matches the rest of the app's dark base + mode-tinted glow
                LinearGradient(
                    colors: [AppTheme.background, AppTheme.tapFrenzy.opacity(0.35)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .onTapGesture {
                    vm.backgroundTapped()
                }

                if !vm.hasStarted {
                    difficultySelectionMenu(in: geometry)
                } else if !vm.isGameOver {
                    VStack {
                        hudView
                        Spacer()
                    }
                    .padding(.top)

                    targetButton
                        .position(buttonPosition)
                } else {
                    gameOverMenu(in: geometry)
                }
            }
            .navigationBarBackButtonHidden(true)
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

    // MARK: - HUD

    var hudView: some View {
        HStack(spacing: 15) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white.opacity(0.8), .ultraThinMaterial)
            }

            ScoreBadge(title: "Score", score: vm.score, color: AppTheme.tapFrenzy)
            ScoreBadge(title: "Time", score: vm.timeRemaining, color: AppTheme.lightItUp)
        }
        .padding(.horizontal)
    }

    // MARK: - Target Button

    var targetButton: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            vm.targetTapped()

            withAnimation(.spring()) {
                if buttonSize > 50 { buttonSize -= 10 }
            }
        } label: {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppTheme.tapFrenzy, AppTheme.brand.opacity(0.85)],
                        center: .topLeading,
                        startRadius: 10,
                        endRadius: buttonSize
                    )
                )
                .overlay(
                    Circle().strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.6), .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 4
                    )
                )
                .overlay(
                    Text("TAP")
                        .font(.system(size: 50, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, y: 2)
                        .scaleEffect(buttonSize / 200)
                        .fixedSize()
                )
                .frame(width: buttonSize, height: buttonSize)
                .shadow(color: AppTheme.tapFrenzy.opacity(0.6), radius: 20, y: 10)
        }
        .buttonStyle(PressableStyle())
    }

    // MARK: - Difficulty Selection

    @ViewBuilder
    func difficultySelectionMenu(in geometry: GeometryProxy) -> some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text("Tap Frenzy")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                Text("Pick a difficulty to start the round")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textMuted)
            }

            VStack(spacing: 16) {
                ForEach(GameDifficulty.allCases) { diff in
                    Button {
                        locationService.fetchLocation()
                        buttonPosition = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        vm.selectDifficulty(diff)
                    } label: {
                        GameMenuButton(
                            title: diff.rawValue,
                            icon: icon(for: diff),
                            gradientColors: [color(for: diff), color(for: diff).opacity(0.4)]
                        )
                    }
                    .buttonStyle(PressableStyle())
                }
            }

            Button { dismiss() } label: {
                Text("Back to Main Menu")
                    .font(.subheadline).bold()
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(.top, 4)
        }
        .padding(28)
        .background(.ultraThinMaterial)
        .cornerRadius(AppTheme.radiusCard)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusCard)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
        .padding(30)
    }

    func icon(for diff: GameDifficulty) -> String {
        switch diff {
        case .easy: return "tortoise.fill"
        case .medium: return "hare.fill"
        case .hard: return "bolt.fill"
        }
    }

    func color(for diff: GameDifficulty) -> Color {
        switch diff {
        case .easy: return AppTheme.success
        case .medium: return AppTheme.warning
        case .hard: return AppTheme.danger
        }
    }

    // MARK: - Game Over

    @ViewBuilder
    func gameOverMenu(in geometry: GeometryProxy) -> some View {
        VStack(spacing: 22) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 64))
                .foregroundStyle(LinearGradient(colors: [AppTheme.warning, AppTheme.tapFrenzy], startPoint: .top, endPoint: .bottom))
                .shadow(color: AppTheme.tapFrenzy.opacity(0.5), radius: 10)

            Text("GAME OVER")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)

            Text("Difficulty: \(vm.difficulty.rawValue)")
                .font(.subheadline).bold()
                .foregroundColor(color(for: vm.difficulty))
                .padding(.vertical, 6).padding(.horizontal, 14)
                .background(color(for: vm.difficulty).opacity(0.15))
                .cornerRadius(AppTheme.radiusPill)

            VStack(spacing: 4) {
                Text("Final Score")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                Text("\(vm.score)")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
            }

            Text(vm.score >= currentHighScore ? "🏆 New High Score!" : "Best (\(vm.difficulty.rawValue)): \(currentHighScore)")
                .font(.headline)
                .foregroundColor(vm.score >= currentHighScore ? AppTheme.warning : AppTheme.textMuted)

            VStack(spacing: 14) {
                Button {
                    vm.hasStarted = false
                } label: {
                    Text("Play Again")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(LinearGradient(colors: [AppTheme.success, AppTheme.lightItUp], startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(.white)
                        .cornerRadius(AppTheme.radiusButton)
                }
                .buttonStyle(PressableStyle())

                Button { dismiss() } label: {
                    Text("Main Menu")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.ultraThinMaterial)
                        .foregroundColor(AppTheme.textPrimary)
                        .cornerRadius(AppTheme.radiusButton)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusButton)
                                .stroke(AppTheme.cardBorderStrong, lineWidth: 1)
                        )
                }
                .buttonStyle(PressableStyle())
            }
        }
        .padding(36)
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.4))
        .cornerRadius(AppTheme.radiusCard)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusCard)
                .stroke(AppTheme.cardBorderStrong, lineWidth: 1)
        )
        .padding(.horizontal, 30)
        .onAppear {
            saveHighScore()
            locationService.awaitLocation { lat, lon in
                statsVM.saveNewSession(
                    mode: .tapFrenzy,
                    score: vm.score,
                    lat: lat,
                    lon: lon,
                    difficulty: vm.difficulty.rawValue
                )
            }
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

#Preview {
    NavigationStack {
        TapFrenzyView()
            .environmentObject(StatsVM())
            .environmentObject(LocationService())
    }
}
