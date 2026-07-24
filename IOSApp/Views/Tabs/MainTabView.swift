//
//  MainTabView.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-09.
//

import SwiftUI

struct MainTabView: View {

    @State private var selectedTab: AppTab = .home
    @State private var pulse = false

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeTab()
            }
            .tag(AppTab.home)
            .toolbar(.hidden, for: .tabBar)

            NavigationStack {
                StatsTab()
            }
            .tag(AppTab.stats)
            .toolbar(.hidden, for: .tabBar)

            NavigationStack {
                MapTab()
            }
            .tag(AppTab.map)
            .toolbar(.hidden, for: .tabBar)

            NavigationStack {
                SettingsTab()
            }
            .tag(AppTab.settings)
            .toolbar(.hidden, for: .tabBar)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            controlDeck
                .onAppear { pulse = true }
        }
    }

    // MARK: - Control Deck
    // A miniature version of Home's marquee (a chasing bulb strip, recolored
    // live to match whichever tab is active) sits above a row of buttons
    // styled like physical backlit arcade buttons — glossy specular
    // highlight, radial "bulb" glow, gentle powered-on pulse when selected —
    // instead of flat filled shapes. This is the same visual grammar Home
    // already established, just carried down into the chrome.

    private var controlDeck: some View {
        VStack(spacing: 6) {
            marqueeStrip
                .padding(.top, 10)

            HStack(spacing: 2) {
                ForEach(AppTab.allCases) { tab in
                    cabinetButton(for: tab)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 10)
        }
        .background(deckSurface)
        .padding(.horizontal, 18)
        .padding(.bottom, 8)
    }

    private var deckSurface: some View {
        RoundedRectangle(cornerRadius: 32, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color.black.opacity(0.2))
            }
            .overlay(alignment: .top) {
                // Faint top-edge sheen, like light catching the lip of a
                // physical control panel.
                LinearGradient(colors: [.white.opacity(0.16), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 26)
            }
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.35), radius: 22, y: 12)
    }

    // MARK: - Marquee strip
    // Same chasing-bulb technique as HomeTab.chasingBulbRow, but tinted to
    // whichever tab is currently active instead of a fixed cycling palette —
    // the deck visibly "reads" the selection.

    private var marqueeStrip: some View {
        TimelineView(.periodic(from: .now, by: 0.14)) { context in
            let tick = Int(context.date.timeIntervalSinceReferenceDate / 0.14)
            HStack(spacing: 6) {
                ForEach(0..<16, id: \.self) { i in
                    let isLit = i == tick % 16
                    Circle()
                        .fill(isLit ? selectedTab.color : Color.white.opacity(0.12))
                        .frame(width: isLit ? 4.5 : 3, height: isLit ? 4.5 : 3)
                        .shadow(color: isLit ? selectedTab.color.opacity(0.85) : .clear, radius: 4)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
        }
    }

    // MARK: - Cabinet Button

    private func cabinetButton(for tab: AppTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(tab.color.opacity(0.4))
                            .frame(width: 60, height: 60)
                            .blur(radius: 14)
                            .scaleEffect(pulse ? 1.1 : 0.92)
                            .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: pulse)
                    }

                    // Button cap — radial gradient + off-center specular
                    // highlight mimics a glossy, backlit acrylic cap rather
                    // than a flat filled circle.
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: isSelected
                                    ? [tab.color, tab.color.opacity(0.55)]
                                    : [Color.white.opacity(0.1), Color.white.opacity(0.03)],
                                center: UnitPoint(x: 0.35, y: 0.3),
                                startRadius: 1,
                                endRadius: 30
                            )
                        )
                        .frame(width: 46, height: 46)
                        .overlay(
                            Circle().strokeBorder(
                                isSelected ? Color.white.opacity(0.5) : Color.white.opacity(0.1),
                                lineWidth: 1.2
                            )
                        )
                        .overlay(
                            Ellipse()
                                .fill(Color.white.opacity(isSelected ? 0.35 : 0.08))
                                .frame(width: 15, height: 9)
                                .blur(radius: 3)
                                .offset(x: -9, y: -12)
                        )
                        .shadow(color: isSelected ? tab.color.opacity(0.6) : .clear, radius: 10, y: 4)

                    Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(isSelected ? .white : Color.white.opacity(0.45))
                        .symbolEffect(.bounce, value: isSelected)
                }
                .frame(width: 56, height: 46)

                Text(tab.title.uppercased())
                    .font(.system(size: 8.5, weight: .black))
                    .tracking(0.5)
                    .foregroundColor(tab.color)
                    .opacity(isSelected ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 62)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Tabs

private enum AppTab: String, CaseIterable, Identifiable {
    case home
    case stats
    case map
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .stats: return "Stats"
        case .map: return "Map"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: return "gamecontroller"
        case .stats: return "chart.bar"
        case .map: return "map"
        case .settings: return "gearshape"
        }
    }

    var selectedIcon: String {
        switch self {
        case .home: return "gamecontroller.fill"
        case .stats: return "chart.bar.fill"
        case .map: return "map.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var color: Color {
        switch self {
        case .home: return .purple
        case .stats: return .blue
        case .map: return .green
        case .settings: return .orange
        }
    }
}

#Preview {
    MainTabView()
}
