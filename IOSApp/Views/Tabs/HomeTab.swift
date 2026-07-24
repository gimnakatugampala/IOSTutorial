//
//  HomeTab.swift
//  IOSApp
//

import SwiftUI

struct HomeTab: View {
    @EnvironmentObject private var statsVM: StatsVM

    @State private var appeared = false
    @State private var glowPulse = false

    @AppStorage("tapFrenzyHighScore") private var tapFrenzyHighScore = 0
    @AppStorage("lightItUpHighScore") private var lightItUpHighScore = 0
    @AppStorage("quizRushHighScore") private var quizRushHighScore = 0

    @AppStorage("quizRushVoiceControlEnabled")
    private var voiceControlEnabled = false

    @StateObject private var voiceCommand = VoiceCommandService()
    @StateObject private var voicePrompt = QuizVoiceService()
    @State private var navigateToVoiceQuiz = false

    private let marqueeLetters = Array("GAME CENTER")
    private let marqueeColors: [Color] = [
        AppTheme.tapFrenzy,
        AppTheme.warning,
        AppTheme.lightItUp,
        AppTheme.brand
    ]

    private var totalGamesPlayed: Int {
        statsVM.sessions.count
    }

    // Until the player has history, Quiz Rush remains the featured game.
    private var featuredMode: GameMode {
        statsVM.topMode ?? .quizRush
    }

    private var featuredLabel: String {
        statsVM.topMode == nil ? "FEATURED GAME" : "MOST PLAYED"
    }

    private var shiftLabel: String {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 0..<12:
            return "MORNING SHIFT"
        case 12..<17:
            return "AFTERNOON RUN"
        default:
            return "NIGHT ARCADE"
        }
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            backdropGlow

            ScrollView {
                VStack(spacing: 22) {
                    marqueeHeader
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : -12)
                        .animation(
                            .easeOut(duration: 0.45),
                            value: appeared
                        )

                    playerTicket
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 14)
                        .animation(
                            .easeOut(duration: 0.45).delay(0.08),
                            value: appeared
                        )

                    featuredGameCard
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)
                        .animation(
                            .easeOut(duration: 0.48).delay(0.13),
                            value: appeared
                        )

                    voiceLaunchCard
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 14)
                        .animation(
                            .easeOut(duration: 0.45).delay(0.17),
                            value: appeared
                        )

                    otherGames
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 18)
                        .animation(
                            .easeOut(duration: 0.5).delay(0.21),
                            value: appeared
                        )

                    footerNote
                        .opacity(appeared ? 1 : 0)
                        .animation(
                            .easeOut(duration: 0.5).delay(0.3),
                            value: appeared
                        )

                    Spacer(minLength: 10)
                }
                .padding(.top, 22)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            appeared = true
            glowPulse = true
        }
        .onDisappear {
            voicePrompt.stop()
            voiceCommand.stopListening()
        }
        .navigationDestination(isPresented: $navigateToVoiceQuiz) {
            QuizRushView(autoStart: true)
        }
    }

    // MARK: - Featured full-width game

    private var featuredGameCard: some View {
        let mode = featuredMode

        return NavigationLink(destination: destination(for: mode)) {
            ZStack(alignment: .bottomLeading) {
                featuredBackground(for: mode)

                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Label(
                            featuredLabel,
                            systemImage: statsVM.topMode == nil
                                ? "sparkles"
                                : "flame.fill"
                        )
                        .font(
                            .system(
                                size: 9,
                                weight: .black,
                                design: .monospaced
                            )
                        )
                        .tracking(1.6)
                        .foregroundColor(.white.opacity(0.8))

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(.white)
                            .frame(width: 34, height: 34)
                            .background(.white.opacity(0.14))
                            .clipShape(Circle())
                    }

                    Spacer()

                    HStack(alignment: .bottom, spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.14))
                                .frame(width: 62, height: 62)

                            Circle()
                                .stroke(
                                    .white.opacity(0.25),
                                    style: StrokeStyle(
                                        lineWidth: 1,
                                        dash: [3, 4]
                                    )
                                )
                                .frame(width: 52, height: 52)

                            Image(systemName: mode.icon)
                                .font(.system(size: 25, weight: .black))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(mode.rawValue.uppercased())
                                .font(
                                    .system(
                                        size: 25,
                                        weight: .black,
                                        design: .rounded
                                    )
                                )
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)

                            Text(subtitle(for: mode))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                        }

                        Spacer(minLength: 4)

                        VStack(alignment: .trailing, spacing: 3) {
                            Text("HIGH SCORE")
                                .font(
                                    .system(
                                        size: 8,
                                        weight: .black,
                                        design: .monospaced
                                    )
                                )
                                .tracking(1.1)
                                .foregroundColor(.white.opacity(0.65))

                            Text(scoreText(for: mode))
                                .font(
                                    .system(
                                        size: 27,
                                        weight: .black,
                                        design: .monospaced
                                    )
                                )
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(18)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 190)
            .clipShape(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            }
            .overlay(alignment: .leading) {
                Circle()
                    .fill(AppTheme.background)
                    .frame(width: 18, height: 18)
                    .offset(x: -9)
            }
            .overlay(alignment: .trailing) {
                Circle()
                    .fill(AppTheme.background)
                    .frame(width: 18, height: 18)
                    .offset(x: 9)
            }
            .shadow(
                color: mode.themeColor.opacity(0.38),
                radius: 24,
                y: 12
            )
        }
        .buttonStyle(PressableStyle())
        .padding(.horizontal, 20)
        .accessibilityLabel(
            "\(featuredLabel), \(mode.rawValue), high score \(scoreText(for: mode))"
        )
        .accessibilityHint("Double tap to play")
    }

    private func featuredBackground(for mode: GameMode) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    mode.themeColor.opacity(0.95),
                    mode.themeColor.opacity(0.52),
                    AppTheme.background
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .stroke(.white.opacity(0.1), lineWidth: 22)
                .frame(width: 180, height: 180)
                .offset(x: 130, y: -65)

            Circle()
                .fill(.white.opacity(0.07))
                .frame(width: 110, height: 110)
                .offset(x: -145, y: 82)

            VStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { _ in
                    HStack(spacing: 6) {
                        ForEach(0..<9, id: \.self) { _ in
                            Circle()
                                .fill(.white.opacity(0.08))
                                .frame(width: 3, height: 3)
                        }
                    }
                }
            }
            .rotationEffect(.degrees(-12))
            .offset(x: 115, y: 50)
        }
    }

    // MARK: - Voice launch

    @ViewBuilder
    private var voiceLaunchCard: some View {
        if voiceControlEnabled {
            Button {
                triggerVoiceLaunch()
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                (
                                    voiceCommand.isListening
                                        ? AppTheme.danger
                                        : AppTheme.quizRush
                                ).opacity(0.2)
                            )
                            .frame(width: 46, height: 46)

                        Image(
                            systemName: voiceCommand.isListening
                                ? "waveform"
                                : "mic.fill"
                        )
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(
                            voiceCommand.isListening
                                ? AppTheme.danger
                                : AppTheme.quizRush
                        )
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(
                            voiceCommand.isListening
                                ? "Listening…"
                                : "Start Quiz Rush by Voice"
                        )
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                        Text(
                            voiceCommand.isListening
                                ? "Say “Quiz Rush” now"
                                : "Tap, then say “Quiz Rush”"
                        )
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textSecondary)
                    }

                    Spacer(minLength: 0)
                }
                .padding(14)
                .background(.ultraThinMaterial.opacity(0.55))
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: AppTheme.radiusCard,
                        style: .continuous
                    )
                )
                .overlay {
                    RoundedRectangle(
                        cornerRadius: AppTheme.radiusCard,
                        style: .continuous
                    )
                    .stroke(AppTheme.quizRush.opacity(0.4), lineWidth: 1)
                }
            }
            .buttonStyle(PressableStyle())
            .disabled(voiceCommand.isListening)
            .padding(.horizontal, 20)
            .accessibilityLabel("Start Quiz Rush by voice")
            .accessibilityHint(
                "Double tap, then say Quiz Rush to launch the game hands-free"
            )
        }
    }

    private func triggerVoiceLaunch() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        voicePrompt.announce("Listening. Say Quiz Rush to start.") {
            voiceCommand.listenOnce { heard in
                guard let heard, heard.contains("quiz") else {
                    voicePrompt.announce(
                        "Sorry, I didn't catch that. Tap the button to try again."
                    )
                    return
                }

                navigateToVoiceQuiz = true
            }
        }
    }

    // MARK: - Background

    private var backdropGlow: some View {
        Circle()
            .fill(AppTheme.brand.opacity(0.3))
            .frame(width: 320, height: 320)
            .blur(radius: 120)
            .offset(y: -280)
            .scaleEffect(glowPulse ? 1.1 : 0.9)
            .animation(
                .easeInOut(duration: 5).repeatForever(autoreverses: true),
                value: glowPulse
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }

    // MARK: - Header

    private var marqueeHeader: some View {
        VStack(spacing: 14) {
            Text(shiftLabel)
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .tracking(3)
                .foregroundColor(AppTheme.textMuted)

            HStack(spacing: 1) {
                ForEach(
                    Array(marqueeLetters.enumerated()),
                    id: \.offset
                ) { index, letter in
                    Text(String(letter))
                        .font(
                            .system(
                                size: 32,
                                weight: .black,
                                design: .rounded
                            )
                        )
                        .foregroundColor(
                            letter == " "
                                ? .clear
                                : marqueeColors[index % marqueeColors.count]
                        )
                }
            }
            .shadow(color: AppTheme.brand.opacity(0.5), radius: 14)

            chasingBulbRow
        }
        .padding(.top, 4)
    }

    private var chasingBulbRow: some View {
        TimelineView(.periodic(from: .now, by: 0.16)) { context in
            let tick = Int(
                context.date.timeIntervalSinceReferenceDate / 0.16
            )

            HStack(spacing: 7) {
                ForEach(0..<14, id: \.self) { index in
                    let isLit = index == tick % 14

                    Circle()
                        .fill(
                            isLit
                                ? AppTheme.warning
                                : AppTheme.cardBorder
                        )
                        .frame(
                            width: isLit ? 7 : 5,
                            height: isLit ? 7 : 5
                        )
                        .shadow(
                            color: isLit
                                ? AppTheme.warning.opacity(0.8)
                                : .clear,
                            radius: 5
                        )
                }
            }
        }
    }

    // MARK: - Player ticket

    private var playerTicket: some View {
        HStack(spacing: 0) {
            ticketStat(
                value: "\(totalGamesPlayed)",
                label: totalGamesPlayed == 1 ? "GAME" : "GAMES",
                tint: AppTheme.brand
            )

            perforationDivider

            ticketStat(
                value: "\(statsVM.currentStreak)",
                label: statsVM.currentStreak == 1 ? "DAY" : "DAYS",
                tint: AppTheme.warning
            )

            perforationDivider

            ticketStat(
                value: statsVM.topMode?.shortLabel ?? "—",
                label: "TOP MODE",
                tint: statsVM.topMode?.themeColor ?? AppTheme.textMuted
            )
        }
        .padding(.vertical, 16)
        .background(.ultraThinMaterial.opacity(0.55))
        .clipShape(
            RoundedRectangle(
                cornerRadius: AppTheme.radiusCard,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: AppTheme.radiusCard,
                style: .continuous
            )
            .stroke(AppTheme.cardBorder, lineWidth: 1)
        }
        .padding(.horizontal, 20)
    }

    private func ticketStat(
        value: String,
        label: String,
        tint: Color
    ) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(
                    .system(
                        size: 20,
                        weight: .black,
                        design: .monospaced
                    )
                )
                .foregroundColor(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(label)
                .font(.system(size: 9, weight: .bold))
                .tracking(1)
                .foregroundColor(AppTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private var perforationDivider: some View {
        VStack(spacing: 3) {
            ForEach(0..<6, id: \.self) { _ in
                Circle()
                    .fill(AppTheme.cardBorder)
                    .frame(width: 3, height: 3)
            }
        }
        .frame(width: 1)
    }

    // MARK: - Remaining games

    private var otherGames: some View {
        VStack(spacing: 20) {
            if featuredMode != .tapFrenzy {
                gameTicket(
                    mode: .tapFrenzy,
                    tilt: -2.5
                )
            }

            if featuredMode != .lightItUp {
                gameTicket(
                    mode: .lightItUp,
                    tilt: 2
                )
            }

            if featuredMode != .quizRush {
                gameTicket(
                    mode: .quizRush,
                    tilt: -1.5
                )
            }
        }
        .padding(.horizontal, 20)
    }

    private func gameTicket(
        mode: GameMode,
        tilt: Double
    ) -> some View {
        NavigationLink(destination: destination(for: mode)) {
            HStack(spacing: 0) {
                ticketIconPanel(mode: mode)

                ticketPerforation
                    .padding(.horizontal, 10)

                VStack(alignment: .leading, spacing: 6) {
                    Text(mode.rawValue.uppercased())
                        .font(
                            .system(
                                size: 16,
                                weight: .black,
                                design: .rounded
                            )
                        )
                        .foregroundColor(AppTheme.textPrimary)

                    Text(subtitle(for: mode))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(2)

                    Spacer(minLength: 5)

                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("HIGH SCORE")
                                .font(
                                    .system(
                                        size: 8,
                                        weight: .black,
                                        design: .monospaced
                                    )
                                )
                                .tracking(1.2)
                                .foregroundColor(AppTheme.textMuted)

                            Text(scoreText(for: mode))
                                .font(
                                    .system(
                                        size: 19,
                                        weight: .black,
                                        design: .monospaced
                                    )
                                )
                                .foregroundColor(mode.themeColor)
                        }

                        Spacer()

                        HStack(spacing: 6) {
                            Text("PLAY")
                            Image(systemName: "arrow.right")
                        }
                        .font(
                            .system(
                                size: 9,
                                weight: .black,
                                design: .monospaced
                            )
                        )
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(mode.themeColor)
                        .clipShape(Capsule())
                        .shadow(
                            color: mode.themeColor.opacity(0.45),
                            radius: 7,
                            y: 3
                        )
                    }
                }
                .padding(.vertical, 14)
                .padding(.trailing, 15)
            }
            .frame(height: 112)
            .background {
                ZStack {
                    RoundedRectangle(
                        cornerRadius: 22,
                        style: .continuous
                    )
                    .fill(.ultraThinMaterial)

                    LinearGradient(
                        colors: [
                            mode.themeColor.opacity(0.11),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 22,
                            style: .continuous
                        )
                    )
                }
            }
            .environment(\.colorScheme, .dark)
            .clipShape(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        mode.themeColor.opacity(0.45),
                        lineWidth: 1.3
                    )
            }
            .overlay(alignment: .leading) {
                Circle()
                    .fill(AppTheme.background)
                    .frame(width: 15, height: 15)
                    .offset(x: -7.5)
            }
            .overlay(alignment: .trailing) {
                Circle()
                    .fill(AppTheme.background)
                    .frame(width: 15, height: 15)
                    .offset(x: 7.5)
            }
            .shadow(
                color: mode.themeColor.opacity(0.22),
                radius: 15,
                y: 8
            )
            .rotationEffect(.degrees(tilt))
        }
        .buttonStyle(PressableStyle())
    }

    private func ticketIconPanel(mode: GameMode) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    mode.themeColor.opacity(0.8),
                    mode.themeColor.opacity(0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .stroke(Color.white.opacity(0.18), lineWidth: 9)
                .frame(width: 75, height: 75)
                .offset(x: -25, y: -38)

            VStack(spacing: 8) {
                Image(systemName: mode.icon)
                    .font(.system(size: 25, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: mode.themeColor, radius: 8)

                Text("ARCADE")
                    .font(
                        .system(
                            size: 7,
                            weight: .black,
                            design: .monospaced
                        )
                    )
                    .tracking(1.5)
                    .foregroundColor(.white.opacity(0.75))
            }
        }
        .frame(width: 82)
        .frame(maxHeight: .infinity)
        .clipShape(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
        )
        .padding(6)
    }

    private var ticketPerforation: some View {
        VStack(spacing: 4) {
            ForEach(0..<9, id: \.self) { _ in
                Circle()
                    .fill(AppTheme.cardBorder)
                    .frame(width: 3, height: 3)
            }
        }
        .frame(width: 3)
    }

    // MARK: - Game data

    private func subtitle(for mode: GameMode) -> String {
        switch mode {
        case .tapFrenzy:
            return "Chase the moving target"
        case .lightItUp:
            return "Tap the glowing cards fast"
        case .quizRush:
            return "Answer live trivia against the clock"
        }
    }

    private func highScore(for mode: GameMode) -> Int {
        switch mode {
        case .tapFrenzy:
            return tapFrenzyHighScore
        case .lightItUp:
            return lightItUpHighScore
        case .quizRush:
            return quizRushHighScore
        }
    }

    private func scoreText(for mode: GameMode) -> String {
        let score = highScore(for: mode)
        return score > 0 ? "\(score)" : "—"
    }

    private func destination(for mode: GameMode) -> AnyView {
        switch mode {
        case .tapFrenzy:
            return AnyView(TapFrenzyView())
        case .lightItUp:
            return AnyView(LightItUpView())
        case .quizRush:
            return AnyView(QuizRushView())
        }
    }

    // MARK: - Footer

    private var footerNote: some View {
        Text("Insert coin. Pick a machine. Beat your best.")
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(AppTheme.textMuted)
            .padding(.top, 2)
    }
}

#Preview {
    NavigationStack {
        HomeTab()
            .environmentObject(StatsVM())
    }
}
