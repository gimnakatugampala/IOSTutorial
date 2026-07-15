//
//  StatsTab.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-08.
//
//  Redesigned to match the rest of the app's dark AppTheme instead of
//  default system colors, and to surface more than just a bar chart:
//  an at-a-glance overview, tappable per-mode filter cards, a chart
//  filterable by date range + metric, richer session rows, a proper
//  zero-state, ambient background glow to match Home, and small reward
//  touches (streak badge, top-mode crown) so the page feels alive.

import SwiftUI
import Charts

struct StatsTab: View {
    @EnvironmentObject var statsVM: StatsVM

    /// Tapping a mode card filters the session list below it. Tapping the
    /// same one again (or "Clear") resets to showing everything.
    @State private var selectedMode: GameMode? = nil
    @State private var selectedDateRange: StatsDateRange = .allTime
    @State private var selectedMetric: StatsMetric = .highScore

    // Entrance + ambient animation state — mirrors HomeTab's pattern so
    // this tab feels part of the same app rather than a bolted-on screen.
    @State private var appeared = false
    @State private var animateGlow = false

    private var totalGamesPlayed: Int { statsVM.sessions.count }
    private var totalScore: Int { statsVM.sessions.reduce(0) { $0 + $1.score } }

    private var filteredSessions: [GameSession] {
        guard let mode = selectedMode else { return statsVM.sessions }
        return statsVM.sessions.filter { $0.mode == mode }
    }

    /// Sessions within the currently selected date range — feeds only the chart,
    /// so the overview cards and full session list above/below still show everything.
    private var chartSessions: [GameSession] {
        statsVM.sessions.filter { selectedDateRange.contains($0.timestamp) }
    }

    /// Consecutive days (ending today or yesterday) with at least one session —
    /// a small "keep it going" signal, same spirit as a workout-app streak.
    private var currentStreak: Int {
        let calendar = Calendar.current
        let playedDays = Set(statsVM.sessions.map { calendar.startOfDay(for: $0.timestamp) })
        guard !playedDays.isEmpty else { return 0 }

        var cursor = calendar.startOfDay(for: Date())
        if !playedDays.contains(cursor) {
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }

        var streak = 0
        while playedDays.contains(cursor) {
            streak += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        return streak
    }

    /// Whichever mode currently holds the single highest score across all
    /// sessions — gets a small crown badge on its overview card.
    private var topMode: GameMode? {
        let ranked = GameMode.allCases.map { ($0, statsVM.highestScore(for: $0)) }
        guard let best = ranked.max(by: { $0.1 < $1.1 }), best.1 > 0 else { return nil }
        return best.0
    }

    var body: some View {
        ZStack {
            backgroundGlow
            AppTheme.background.ignoresSafeArea()

            if statsVM.sessions.isEmpty {
                fullEmptyState
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        overviewSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)
                            .animation(.easeOut(duration: 0.45), value: appeared)

                        highScoreChartSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)
                            .animation(.easeOut(duration: 0.45).delay(0.08), value: appeared)

                        recentSessionsSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)
                            .animation(.easeOut(duration: 0.45).delay(0.16), value: appeared)
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationTitle("Statistics")
        .onAppear {
            appeared = true
            animateGlow = true
        }
    }

    // MARK: - Ambient Background
    // Same blurred-circle language as HomeTab, kept much lower-opacity here
    // since this screen is text/data-dense and needs to stay readable.

    var backgroundGlow: some View {
        ZStack {
            Circle()
                .fill(AppTheme.brand.opacity(0.16))
                .frame(width: 280, height: 280)
                .blur(radius: 110)
                .offset(x: animateGlow ? 120 : -110, y: animateGlow ? -260 : -220)
                .animation(.easeInOut(duration: 10).repeatForever(autoreverses: true), value: animateGlow)

            Circle()
                .fill(AppTheme.lightItUp.opacity(0.12))
                .frame(width: 240, height: 240)
                .blur(radius: 100)
                .offset(x: animateGlow ? -110 : 110, y: animateGlow ? 320 : 360)
                .animation(.easeInOut(duration: 12).repeatForever(autoreverses: true), value: animateGlow)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Section Header Helper
    // One consistent icon+title treatment reused by the chart and session
    // list headers instead of each rolling its own plain Text.

    func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AppTheme.brand)
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
        }
    }

    // MARK: - Full Empty State
    // Shown only when there are truly zero sessions ever recorded — replaces
    // the old look of an overview full of zeroes plus three separate
    // "no data" placeholders stacked on top of each other.

    var fullEmptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(colors: [AppTheme.brand, AppTheme.lightItUp], startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: AppTheme.brand.opacity(0.4), radius: 16)

            VStack(spacing: 8) {
                Text("No Stats Yet")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                Text("Play a round of any game and your scores, streaks, and history will show up here.")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.5), value: appeared)
    }

    // MARK: - Overview

    var overviewSection: some View {
        VStack(spacing: 14) {
            HStack {
                sectionHeader(title: "Overview", icon: "chart.pie.fill")
                Spacer()
                if currentStreak > 0 {
                    streakBadge
                }
            }
            .padding(.horizontal)

            HStack(spacing: 12) {
                overviewStat(title: "Games Played", value: "\(totalGamesPlayed)", icon: "gamecontroller.fill", color: AppTheme.brand)
                overviewStat(title: "Total Score", value: "\(totalScore)", icon: "star.fill", color: AppTheme.warning)
            }
            .padding(.horizontal)

            HStack(spacing: 12) {
                ForEach(GameMode.allCases, id: \.self) { mode in
                    modeCard(mode)
                }
            }
            .padding(.horizontal)
        }
    }

    var streakBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 11, weight: .bold))
            Text("\(currentStreak) day\(currentStreak == 1 ? "" : "s")")
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(AppTheme.warning)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(AppTheme.warning.opacity(0.15))
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(AppTheme.warning.opacity(0.35), lineWidth: 1)
        )
    }

    func overviewStat(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(color.opacity(0.18)).frame(width: 46, height: 46)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18, weight: .bold))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial.opacity(0.5))
        .cornerRadius(AppTheme.radiusCard)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusCard)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
    }

    func modeCard(_ mode: GameMode) -> some View {
        let isSelected = selectedMode == mode
        let color = mode.themeColor
        let played = statsVM.sessions.filter { $0.mode == mode }.count
        let isTop = topMode == mode

        return Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.spring(response: 0.3)) {
                selectedMode = isSelected ? nil : mode
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(isSelected ? 0.3 : 0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: mode.icon)
                            .foregroundColor(color)
                            .font(.system(size: 15, weight: .bold))
                    }

                    Text("\(statsVM.highestScore(for: mode))")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)

                    Text(mode.shortLabel.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)

                    Text(played == 1 ? "1 game" : "\(played) games")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(AppTheme.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isSelected ? color.opacity(0.14) : Color.white.opacity(0.03))
                .cornerRadius(AppTheme.radiusButton)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusButton)
                        .stroke(isSelected ? color.opacity(0.7) : AppTheme.cardBorder, lineWidth: isSelected ? 1.5 : 1)
                )

                if isTop {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.black)
                        .padding(5)
                        .background(AppTheme.warning)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(AppTheme.background, lineWidth: 2))
                        .offset(x: 6, y: -6)
                }
            }
        }
        .buttonStyle(PressableStyle())
    }

    private func metricValue(for mode: GameMode) -> Int {
        let modeSessions = chartSessions.filter { $0.mode == mode }
        guard !modeSessions.isEmpty else { return 0 }

        switch selectedMetric {
        case .highScore:
            return modeSessions.map { $0.score }.max() ?? 0
        case .gamesPlayed:
            return modeSessions.count
        case .averageScore:
            return modeSessions.reduce(0) { $0 + $1.score } / modeSessions.count
        case .totalScore:
            return modeSessions.reduce(0) { $0 + $1.score }
        }
    }

    // MARK: - Chart

    var highScoreChartSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader(title: "\(selectedMetric.rawValue) by Mode", icon: "chart.bar.xaxis")

                Spacer()

                Menu {
                    ForEach(StatsMetric.allCases) { metric in
                        Button {
                            withAnimation(.spring(response: 0.3)) { selectedMetric = metric }
                        } label: {
                            Label(metric.rawValue, systemImage: metric.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: selectedMetric.icon)
                        Text(selectedMetric.rawValue)
                        Image(systemName: "chevron.down")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.brand)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.brand.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal)

            // Date range filter
            SegmentedFilterBar(
                options: StatsDateRange.allCases,
                selection: $selectedDateRange,
                label: { $0.rawValue },
                tint: AppTheme.brand
            )
            .padding(.horizontal)

            if chartSessions.isEmpty {
                emptyChartState
            } else {
                Chart {
                    ForEach(GameMode.allCases, id: \.self) { mode in
                        BarMark(
                            x: .value(selectedMetric.rawValue, metricValue(for: mode)),
                            y: .value("Mode", mode.shortLabel)
                        )
                        .foregroundStyle(mode.themeColor.gradient)
                        .cornerRadius(8)
                        .annotation(position: .trailing) {
                            Text("\(metricValue(for: mode))")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(AppTheme.cardBorder)
                        AxisValueLabel().foregroundStyle(AppTheme.textMuted)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel().foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .frame(height: 180)
                .padding()
                .background(.ultraThinMaterial.opacity(0.5))
                .cornerRadius(AppTheme.radiusCard)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusCard)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                )
                .padding(.horizontal)
                .animation(.easeInOut(duration: 0.25), value: selectedMetric)
                .animation(.easeInOut(duration: 0.25), value: selectedDateRange)
            }
        }
    }

    var emptyChartState: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 32))
                .foregroundColor(AppTheme.textMuted)
            Text("No sessions in this range")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(.ultraThinMaterial.opacity(0.3))
        .cornerRadius(AppTheme.radiusCard)
        .padding(.horizontal)
    }

    // MARK: - Recent Sessions

    var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader(
                    title: selectedMode == nil ? "Recent Sessions" : "\(selectedMode!.rawValue) Sessions",
                    icon: "clock.arrow.circlepath"
                )

                Text("\(filteredSessions.count)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.textMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(AppTheme.card)
                    .clipShape(Capsule())

                Spacer()

                if selectedMode != nil {
                    Button {
                        withAnimation { selectedMode = nil }
                    } label: {
                        Text("Clear")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.brand)
                    }
                }
            }
            .padding(.horizontal)

            if filteredSessions.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(filteredSessions) { session in
                        sessionRow(session)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    func sessionRow(_ session: GameSession) -> some View {
        let color = session.mode.themeColor

        return HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 4, height: 44)

            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 40, height: 40)
                Image(systemName: session.mode.icon)
                    .foregroundColor(color)
                    .font(.system(size: 15, weight: .bold))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(session.mode.rawValue)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Text(session.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textMuted)

                if let detail = session.detailText {
                    Text(detail)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(color.opacity(0.85))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(session.score)")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(color)
                Text("pts")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(AppTheme.textMuted)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial.opacity(0.4))
        .cornerRadius(AppTheme.radiusButton)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusButton)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
    }

    var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.textMuted)
            Text(selectedMode == nil ? "No games yet" : "No \(selectedMode!.rawValue) sessions yet")
                .font(.headline)
                .foregroundColor(AppTheme.textSecondary)
            Text("Play a round to see your stats appear here!")
                .font(.subheadline)
                .foregroundColor(AppTheme.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 30)
        .background(.ultraThinMaterial.opacity(0.3))
        .cornerRadius(AppTheme.radiusCard)
        .padding(.horizontal)
    }
}

// MARK: - Filter enums
// icon/color/shortLabel per mode now live on GameMode itself (GameMode.swift),
// shared by Stats, Map, and Home tabs — nothing per-mode is redeclared here.

enum StatsDateRange: String, CaseIterable, Identifiable {
    case today = "Today"
    case week = "7 Days"
    case month = "30 Days"
    case allTime = "All Time"

    var id: String { rawValue }

    func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        switch self {
        case .today:
            return calendar.isDateInToday(date)
        case .week:
            let cutoff = calendar.date(byAdding: .day, value: -7, to: Date()) ?? .distantPast
            return date >= cutoff
        case .month:
            let cutoff = calendar.date(byAdding: .day, value: -30, to: Date()) ?? .distantPast
            return date >= cutoff
        case .allTime:
            return true
        }
    }
}

enum StatsMetric: String, CaseIterable, Identifiable {
    case highScore = "High Score"
    case gamesPlayed = "Games Played"
    case averageScore = "Avg Score"
    case totalScore = "Total Score"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .highScore: return "trophy.fill"
        case .gamesPlayed: return "number"
        case .averageScore: return "chart.bar.fill"
        case .totalScore: return "sum"
        }
    }
}

#Preview {
    NavigationStack {
        StatsTab()
            .environmentObject(StatsVM())
    }
}
