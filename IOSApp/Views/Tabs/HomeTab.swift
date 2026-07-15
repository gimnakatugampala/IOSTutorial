//
//  HomeTab.swift
//  IOSApp
//

import SwiftUI

struct HomeTab: View {
    @EnvironmentObject var statsVM: StatsVM

    // Animation States
    @State private var animateBackground = false
    @State private var floatIcon = false
    @State private var showButtons = false
    @State private var appeared = false

    // High Score Persistence
    @AppStorage("tapFrenzyHighScore") private var tapFrenzyHighScore = 0
    @AppStorage("lightItUpHighScore") private var lightItUpHighScore = 0
    @AppStorage("quizRushHighScore") private var quizRushHighScore = 0

    private var totalGamesPlayed: Int { statsVM.sessions.count }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            // Animated Background — anchored to the app's theme + Light It Up accent
            ZStack {
                Circle().fill(AppTheme.brand.opacity(0.55)).frame(width: 350, height: 350).blur(radius: 120)
                    .offset(x: animateBackground ? 100 : -150, y: animateBackground ? -150 : 100)
                    .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: animateBackground)

                Circle().fill(AppTheme.lightItUp.opacity(0.45)).frame(width: 300, height: 300).blur(radius: 100)
                    .offset(x: animateBackground ? -150 : 150, y: animateBackground ? 150 : -150)
                    .animation(.easeInOut(duration: 9).repeatForever(autoreverses: true), value: animateBackground)
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 26) {
                    // Hero Section
                    VStack(spacing: 16) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(LinearGradient(colors: [AppTheme.lightItUp, AppTheme.brand, AppTheme.tapFrenzy], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .shadow(color: AppTheme.brand.opacity(0.6), radius: 20, x: 0, y: 10)
                            .offset(y: floatIcon ? -15 : 10)
                            .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: floatIcon)

                        VStack(spacing: 4) {
                            Text(greeting)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppTheme.textSecondary)
                            Text("Game Center")
                                .font(.system(size: 42, weight: .black, design: .rounded))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                    }
                    .padding(.top, 40)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -12)
                    .animation(.easeOut(duration: 0.45), value: appeared)

                    // Quick Stats Strip — only shown once there's something to show,
                    // so a brand-new install isn't greeted with "0 games, no streak."
                    if totalGamesPlayed > 0 {
                        quickStatsStrip
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 12)
                            .animation(.easeOut(duration: 0.45).delay(0.08), value: appeared)
                    }

                    // High Score Dashboard
                    HStack(spacing: 10) {
                        ScoreBadge(title: "Tap", score: tapFrenzyHighScore, color: AppTheme.tapFrenzy)
                        ScoreBadge(title: "Light", score: lightItUpHighScore, color: AppTheme.lightItUp)
                        ScoreBadge(title: "Quiz", score: quizRushHighScore, color: AppTheme.quizRush)
                    }
                    .padding(.horizontal)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(.easeOut(duration: 0.45).delay(0.14), value: appeared)

                    // Game Buttons
                    VStack(spacing: 16) {
                        NavigationLink(destination: TapFrenzyView()) {
                            gameCard(
                                title: "Tap Frenzy",
                                subtitle: "Chase the moving target",
                                icon: "hand.tap.fill",
                                gradientColors: [AppTheme.tapFrenzy, AppTheme.brand],
                                best: tapFrenzyHighScore
                            )
                        }
                        NavigationLink(destination: LightItUpView()) {
                            gameCard(
                                title: "Light It Up",
                                subtitle: "Tap the glowing cards fast",
                                icon: "lightbulb.max.fill",
                                gradientColors: [AppTheme.warning, AppTheme.danger, AppTheme.tapFrenzy],
                                best: lightItUpHighScore
                            )
                        }
                        NavigationLink(destination: QuizRushView()) {
                            gameCard(
                                title: "Quiz Rush",
                                subtitle: "Answer live trivia against the clock",
                                icon: "questionmark.bubble.fill",
                                gradientColors: [AppTheme.quizRush, AppTheme.lightItUp],
                                best: quizRushHighScore
                            )
                        }
                    }
                    .padding(.horizontal, 30)
                    .opacity(showButtons ? 1 : 0)
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: showButtons)

                    Spacer(minLength: 20)
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            animateBackground = true
            floatIcon = true
            showButtons = true
            appeared = true
        }
    }

    // MARK: - Quick Stats Strip

    var quickStatsStrip: some View {
        HStack(spacing: 12) {
            statChip(icon: "gamecontroller.fill", value: "\(totalGamesPlayed)", label: totalGamesPlayed == 1 ? "Game" : "Games", tint: AppTheme.brand)

            if statsVM.currentStreak > 0 {
                statChip(icon: "flame.fill", value: "\(statsVM.currentStreak)", label: statsVM.currentStreak == 1 ? "Day" : "Days", tint: AppTheme.warning)
            }

            if let top = statsVM.topMode {
                statChip(icon: "crown.fill", value: top.shortLabel, label: "Top Mode", tint: top.themeColor)
            }
        }
        .padding(.horizontal)
    }

    func statChip(icon: String, value: String, label: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(tint)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                Text(label.uppercased())
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial.opacity(0.5))
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(tint.opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: - Game Card
    // GameMenuButton kept for anywhere else it's used, but Home now shows a
    // richer card with a subtitle + inline best score, so the menu doubles
    // as a mini dashboard instead of just three plain nav rows.

    func gameCard(title: String, subtitle: String, icon: String, gradientColors: [Color], best: Int) -> some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 54, height: 54)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.65))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if best > 0 {
                VStack(spacing: 1) {
                    Text("\(best)")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("BEST")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            Image(systemName: "chevron.right.circle.fill")
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .cornerRadius(25)
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(
                    LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1.5
                )
                .opacity(0.8)
        )
    }
}

#Preview {
    NavigationStack {
        HomeTab()
            .environmentObject(StatsVM())
    }
}
