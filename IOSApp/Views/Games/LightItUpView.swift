import SwiftUI

struct LightItUpView: View {
    // 1. MVVM Connection
    @StateObject private var vm = LightItUpVM()
    
    // 2. Global Services for Map & Stats
    @EnvironmentObject var statsVM: StatsVM
    @EnvironmentObject var locationService: LocationService

    // Round length is a global preference set in Settings; the View reads it
    // and hands it to the VM at start — the VM never touches UserDefaults directly.
    @AppStorage("lightItUpRoundLength") private var roundLength = 60

    // Overall best score (kept for the Home tab dashboard, which isn't aware of
    // round length) plus a separate best per round length so scores are only
    // ever compared against a fair baseline — same pattern as Tap Frenzy's
    // per-difficulty high scores.
    @AppStorage("lightItUpHighScore") private var highScoreOverall = 0
    @AppStorage("lightItUpHighScore_30") private var highScore30 = 0
    @AppStorage("lightItUpHighScore_60") private var highScore60 = 0
    @AppStorage("lightItUpHighScore_90") private var highScore90 = 0

    @Environment(\.dismiss) private var dismiss

    private var currentHighScore: Int {
        switch roundLength {
        case 30: return highScore30
        case 90: return highScore90
        default: return highScore60
        }
    }

    /// Message handed to the system share sheet from the game-over screen.
    private var shareText: String {
        let levelText = vm.level == .overdrive ? "Overdrive" : "Level \(vm.level.label)"
        return "I scored \(vm.score) points in Light It Up, reaching \(levelText) with a \(vm.bestStreak)x streak! ⚡️ Can you beat that?"
    }

    var body: some View {
        ZStack {
            // Background — matches the rest of the app's dark base + mode-tinted glow
            LinearGradient(
                colors: [AppTheme.background, AppTheme.lightItUp.opacity(0.28)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Panic Mode Background
            if vm.level == .overdrive {
                Color.red.opacity(vm.pulseBackground ? 0.3 : 0.05)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.3).repeatForever(), value: vm.pulseBackground)
                    .onAppear { vm.pulseBackground = true }
            }
            
            // Level Up Flash
            if vm.showLevelFlash {
                vm.level.glowColor.opacity(0.4)
                    .ignoresSafeArea()
                    .zIndex(10)
                    .transition(.opacity)

                Text(vm.level == .overdrive ? "OVERDRIVE" : "LEVEL \(vm.level.label)")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: vm.level.glowColor, radius: 20)
                    .zIndex(11)
                    .transition(.scale.combined(with: .opacity))
            }

            if vm.gameOver {
                gameOverMenu
            } else {
                VStack(spacing: 18) {
                    hudView
                    levelBar
                    cardGrid
                    Spacer()
                }
                .padding(.top)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: vm.showLevelFlash)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Start game and fetch GPS immediately!
            vm.startGame(roundLength: roundLength)
            locationService.fetchLocation()
        }
        // UI Haptics when in overdrive
        .onChange(of: vm.timeRemaining) { newValue in
            if newValue <= 10 && vm.level == .overdrive {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
        }
        .onChange(of: vm.lastTapWasGolden) { golden in
            if golden {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
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

            ScoreBadge(title: "Score", score: vm.score, color: AppTheme.lightItUp)

            livesBadge

            ScoreBadge(title: "Time", score: vm.timeRemaining, color: AppTheme.warning)
        }
        .padding(.horizontal)
    }

    var livesBadge: some View {
        VStack(spacing: 4) {
            Text("LIVES")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppTheme.textSecondary)
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < vm.lives ? "heart.fill" : "heart")
                        .foregroundColor(i < vm.lives ? AppTheme.danger : AppTheme.textMuted)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial.opacity(0.5))
        .cornerRadius(AppTheme.radiusButton - 4)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusButton - 4)
                .stroke(AppTheme.danger.opacity(vm.lives > 0 ? 0.4 : 0.15), lineWidth: 1)
        )
    }

    // MARK: - Level + Combo

    var levelBar: some View {
        HStack(spacing: 10) {
            Text(vm.level == .overdrive ? "⚠️ OVERDRIVE ⚠️" : "LEVEL \(vm.level.label)")
                .font(.system(size: 16, weight: .black, design: .monospaced))
                .foregroundColor(vm.level.glowColor)
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
                .background(.ultraThinMaterial)
                .cornerRadius(AppTheme.radiusPill)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusPill)
                        .stroke(vm.level.glowColor.opacity(0.5), lineWidth: 1)
                )

            if vm.streak >= 2 {
                Label("\(vm.streak)x", systemImage: "flame.fill")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(comboColor)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(.ultraThinMaterial)
                    .cornerRadius(AppTheme.radiusPill)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusPill)
                            .stroke(comboColor.opacity(0.5), lineWidth: 1)
                    )
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: vm.streak >= 2)
    }

    var comboColor: Color {
        switch vm.streak {
        case ..<5: return AppTheme.warning
        case 5..<10: return AppTheme.lightItUp
        default: return AppTheme.danger
        }
    }

    // MARK: - Card Grid

    var cardGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: vm.level.columns), spacing: 15) {
            ForEach(vm.cards) { card in
                cardView(card)
                    .onTapGesture {
                        vm.handleTap(card: card)
                    }
            }
        }
        .padding(.horizontal, 25)
    }

    @ViewBuilder
    func cardView(_ card: Card) -> some View {
        let isGoldLive = card.isLit && card.isGolden

        RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
            .fill(
                isGoldLive
                    ? AnyShapeStyle(LinearGradient(colors: [Color.yellow, AppTheme.warning], startPoint: .topLeading, endPoint: .bottomTrailing))
                    : AnyShapeStyle(card.isLit ? Color.white : AppTheme.card)
            )
            .frame(height: 110)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                    .stroke(card.isLit ? (isGoldLive ? Color.yellow : vm.level.glowColor) : AppTheme.cardBorder, lineWidth: card.isLit ? 4 : 1)
            )
            .overlay {
                if isGoldLive {
                    Image(systemName: "star.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.white)
                        .shadow(color: .yellow, radius: 8)
                }
            }
            .shadow(color: card.isLit ? (isGoldLive ? Color.yellow : vm.level.glowColor) : .clear, radius: card.isLit ? 15 : 0)
            .scaleEffect(card.isLit ? 1.05 : (vm.level == .overdrive ? 0.9 : 1.0))
            .animation(.spring(response: 0.25), value: card.isLit)
    }

    // MARK: - Game Over

    var gameOverMenu: some View {
        VStack(spacing: 22) {
            HStack(spacing: 10) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(LinearGradient(colors: [AppTheme.warning, AppTheme.lightItUp], startPoint: .top, endPoint: .bottom))
                    .shadow(color: AppTheme.lightItUp.opacity(0.5), radius: 10)
                gradeBadge
            }

            Text(vm.lives <= 0 ? "GAME OVER" : "TIME'S UP")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)

            VStack(spacing: 4) {
                Text("Final Score")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                Text("\(vm.score)")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
            }

            HStack(spacing: 12) {
                statPill(title: "Round", value: "\(roundLength)s")
                statPill(title: "Best Streak", value: "\(vm.bestStreak)x")
                statPill(title: "Accuracy", value: "\(Int(vm.accuracy * 100))%")
            }

            Text(vm.score >= currentHighScore ? "🏆 New High Score!" : "Best (\(roundLength)s round): \(currentHighScore)")
                .font(.headline)
                .foregroundColor(vm.score >= currentHighScore ? AppTheme.warning : AppTheme.textMuted)

            VStack(spacing: 14) {
                Button {
                    vm.startGame(roundLength: roundLength)
                    locationService.fetchLocation()
                } label: {
                    Text("Play Again")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(LinearGradient(colors: [AppTheme.lightItUp, AppTheme.success], startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(.white)
                        .cornerRadius(AppTheme.radiusButton)
                }
                .buttonStyle(PressableStyle())

                ShareScoreButton(shareText: shareText, tint: AppTheme.lightItUp)

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
        .padding(32)
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.4))
        .cornerRadius(AppTheme.radiusCard)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusCard)
                .stroke(AppTheme.cardBorderStrong, lineWidth: 1)
        )
        .padding(.horizontal, 30)
        .onAppear {
            saveHighScores()
            locationService.awaitLocation { lat, lon in
                Task {
                    await statsVM.saveNewSession(
                        mode: .lightItUp,
                        score: vm.score,
                        lat: lat,
                        lon: lon,
                        levelReached: vm.level.label
                    )
                }
            }
        }
    }

    private func saveHighScores() {
        if vm.score > highScoreOverall { highScoreOverall = vm.score }
        switch roundLength {
        case 30: if vm.score > highScore30 { highScore30 = vm.score }
        case 90: if vm.score > highScore90 { highScore90 = vm.score }
        default: if vm.score > highScore60 { highScore60 = vm.score }
        }
    }

    var gradeBadge: some View {
        Text(vm.performanceGrade)
            .font(.system(size: 22, weight: .black, design: .rounded))
            .foregroundColor(.white)
            .frame(width: 44, height: 44)
            .background(gradeColor)
            .clipShape(Circle())
            .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1))
            .shadow(color: gradeColor.opacity(0.6), radius: 8)
    }

    var gradeColor: Color {
        switch vm.performanceGrade {
        case "S": return Color.yellow
        case "A": return AppTheme.success
        case "B": return AppTheme.lightItUp
        case "C": return AppTheme.warning
        default: return AppTheme.danger
        }
    }

    func statPill(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline).bold()
                .foregroundColor(AppTheme.textPrimary)
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial.opacity(0.5))
        .cornerRadius(AppTheme.radiusButton - 4)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusButton - 4)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        LightItUpView()
            .environmentObject(StatsVM())
            .environmentObject(LocationService())
    }
}
