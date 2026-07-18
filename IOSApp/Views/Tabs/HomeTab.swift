//
//  HomeTab.swift
//  IOSApp
//
//  Redesigned around an "arcade ticket booth" identity instead of the
//  generic dark-glass-cards-over-blurred-blobs look: a marquee title with
//  chasing bulb lights, a single perforated "player ticket" summarizing
//  stats, and each game presented as its own die-cut ticket stub (icon
//  panel + tear-perforation + title/best score), gently fanned like a
//  handful of real tickets rather than stacked as uniform identical cards.
//

import SwiftUI

struct HomeTab: View {
    @EnvironmentObject var statsVM: StatsVM

    // Entrance + ambient motion state
    @State private var appeared = false
    @State private var glowPulse = false

    // High Score Persistence — same keys Settings' "Reset All High Scores" clears
    @AppStorage("tapFrenzyHighScore") private var tapFrenzyHighScore = 0
    @AppStorage("lightItUpHighScore") private var lightItUpHighScore = 0
    @AppStorage("quizRushHighScore") private var quizRushHighScore = 0

    private var totalGamesPlayed: Int { statsVM.sessions.count }

    /// Arcade-flavored stand-in for a plain "Good morning" — still time-aware,
    /// just voiced like a booth attendant instead of a generic dashboard.
    private var shiftLabel: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "MORNING SHIFT"
        case 12..<17: return "AFTERNOON RUN"
        default: return "NIGHT ARCADE"
        }
    }

    private let marqueeLetters: [Character] = Array("GAME CENTER")
    private let marqueeColors: [Color] = [AppTheme.tapFrenzy, AppTheme.warning, AppTheme.lightItUp, AppTheme.brand]

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            backdropGlow

            ScrollView {
                VStack(spacing: 22) {
                    marqueeHeader
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : -12)
                        .animation(.easeOut(duration: 0.45), value: appeared)

                    playerTicket
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 14)
                        .animation(.easeOut(duration: 0.45).delay(0.1), value: appeared)

                    VStack(spacing: 20) {
                        gameTicket(
                            mode: .tapFrenzy,
                            subtitle: "Chase the moving target",
                            best: tapFrenzyHighScore,
                            tilt: -2.5,
                            destination: AnyView(TapFrenzyView())
                        )
                        gameTicket(
                            mode: .lightItUp,
                            subtitle: "Tap the glowing cards fast",
                            best: lightItUpHighScore,
                            tilt: 2,
                            destination: AnyView(LightItUpView())
                        )
                        gameTicket(
                            mode: .quizRush,
                            subtitle: "Answer live trivia against the clock",
                            best: quizRushHighScore,
                            tilt: -1.5,
                            destination: AnyView(QuizRushView())
                        )
                    }
                    .padding(.horizontal, 20)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 18)
                    .animation(.easeOut(duration: 0.5).delay(0.18), value: appeared)

                    footerNote
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.3), value: appeared)

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
    }

    // MARK: - Backdrop
    // One soft glow behind the marquee, breathing slowly — a quieter, more
    // deliberate alternative to two roaming blurred blobs.

    var backdropGlow: some View {
        Circle()
            .fill(AppTheme.brand.opacity(0.3))
            .frame(width: 320, height: 320)
            .blur(radius: 120)
            .offset(y: -280)
            .scaleEffect(glowPulse ? 1.1 : 0.9)
            .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: glowPulse)
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }

    // MARK: - Marquee Header

    var marqueeHeader: some View {
        VStack(spacing: 14) {
            Text(shiftLabel)
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .tracking(3)
                .foregroundColor(AppTheme.textMuted)

            HStack(spacing: 1) {
                ForEach(Array(marqueeLetters.enumerated()), id: \.offset) { index, letter in
                    Text(String(letter))
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(letter == " " ? .clear : marqueeColors[index % marqueeColors.count])
                }
            }
            .shadow(color: AppTheme.brand.opacity(0.5), radius: 14)

            chasingBulbRow
        }
        .padding(.top, 4)
    }

    /// A row of small "marquee bulbs" where one lights up at a time in
    /// sequence — the page's one real motion signature, driven by
    /// TimelineView instead of a manually managed Timer/Combine pipeline.
    var chasingBulbRow: some View {
        TimelineView(.periodic(from: .now, by: 0.16)) { context in
            let tick = Int(context.date.timeIntervalSinceReferenceDate / 0.16)
            HStack(spacing: 7) {
                ForEach(0..<14, id: \.self) { i in
                    let isLit = i == tick % 14
                    Circle()
                        .fill(isLit ? AppTheme.warning : AppTheme.cardBorder)
                        .frame(width: isLit ? 7 : 5, height: isLit ? 7 : 5)
                        .shadow(color: isLit ? AppTheme.warning.opacity(0.8) : .clear, radius: 5)
                }
            }
        }
    }

    // MARK: - Player Ticket (stats summary)
    // Replaces the old "quick stats strip + 3 score badges" pile with a
    // single perforated stat ticket — the same die-cut language used below
    // for each game, so the summary reads as part of the same idea rather
    // than a different kind of dashboard bolted on top.

    var playerTicket: some View {
        HStack(spacing: 0) {
            ticketStat(value: "\(totalGamesPlayed)", label: totalGamesPlayed == 1 ? "GAME" : "GAMES", tint: AppTheme.brand)
            perforationDivider
            ticketStat(value: "\(statsVM.currentStreak)", label: statsVM.currentStreak == 1 ? "DAY" : "DAYS", tint: AppTheme.warning)
            perforationDivider
            ticketStat(value: statsVM.topMode?.shortLabel ?? "—", label: "TOP MODE", tint: statsVM.topMode?.themeColor ?? AppTheme.textMuted)
        }
        .padding(.vertical, 16)
        .background(.ultraThinMaterial.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    func ticketStat(value: String, label: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .black, design: .monospaced))
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

    /// A short dotted tear-line, standing in for a punch-hole perforation —
    /// reused between the stat columns above and inside each game ticket
    /// below, so the same visual grammar carries the whole screen.
    var perforationDivider: some View {
        VStack(spacing: 3) {
            ForEach(0..<6, id: \.self) { _ in
                Circle().fill(AppTheme.cardBorder).frame(width: 3, height: 3)
            }
        }
        .frame(width: 1)
    }

    // MARK: - Game Ticket Card
    // Each mode is its own die-cut ticket: a tinted icon stub on the left,
    // a tear-perforation, then title/subtitle/best score — tilted a couple
    // degrees per card so the three read as tickets dropped on a counter
    // rather than three identical rows in a list.

    func gameTicket(mode: GameMode, subtitle: String, best: Int, tilt: Double, destination: AnyView) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 0) {
                stubPanel(mode: mode)

                perforationDivider
                    .padding(.horizontal, 10)

                VStack(alignment: .leading, spacing: 6) {
                    Text(mode.rawValue.uppercased())
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)

                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 6)

                    HStack(spacing: 6) {
                        Text("BEST")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1)
                            .foregroundColor(AppTheme.textMuted)
                        Text(best > 0 ? "\(best)" : "—")
                            .font(.system(size: 15, weight: .black, design: .monospaced))
                            .foregroundColor(mode.themeColor)
                        Spacer()
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(mode.themeColor.opacity(0.85))
                    }
                }
                .padding(.vertical, 14)
                .padding(.trailing, 16)
            }
            .frame(height: 100)
            .background(.ultraThinMaterial.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                    .stroke(mode.themeColor.opacity(0.45), lineWidth: 1.4)
            )
            .shadow(color: mode.themeColor.opacity(0.25), radius: 14, y: 8)
            .rotationEffect(.degrees(tilt))
        }
    }

    func stubPanel(mode: GameMode) -> some View {
        ZStack {
            LinearGradient(
                colors: [mode.themeColor.opacity(0.4), mode.themeColor.opacity(0.14)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 8) {
                Image(systemName: mode.icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Text("PLAY")
                    .font(.system(size: 8, weight: .black))
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.75))
                    .rotationEffect(.degrees(-90))
                    .fixedSize()
            }
        }
        .frame(width: 76)
        .frame(maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard - 4, style: .continuous))
        .padding(6)
    }

    // MARK: - Footer

    var footerNote: some View {
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
