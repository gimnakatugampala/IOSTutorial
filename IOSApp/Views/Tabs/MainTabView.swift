//
//  MainTabView.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-09.
//

import SwiftUI

struct MainTabView: View {

    @State private var selectedTab: AppTab = .home
    @Namespace private var tabAnimation

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
            customTabBar
        }
    }

    // MARK: - Custom tab bar

    private var customTabBar: some View {
        HStack(spacing: 8) {
            ForEach(AppTab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(8)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule()
                        .fill(Color.black.opacity(0.12))
                }
                .overlay {
                    Capsule()
                        .stroke(
                            Color.white.opacity(0.15),
                            lineWidth: 1
                        )
                }
                .shadow(
                    color: Color.black.opacity(0.3),
                    radius: 20,
                    x: 0,
                    y: 10
                )
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    private func tabButton(
        for tab: AppTab
    ) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            UIImpactFeedbackGenerator(style: .light)
                .impactOccurred()

            withAnimation(
                .spring(
                    response: 0.38,
                    dampingFraction: 0.75
                )
            ) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 7) {
                Image(
                    systemName: isSelected
                        ? tab.selectedIcon
                        : tab.icon
                )
                .font(
                    .system(
                        size: 18,
                        weight: .bold
                    )
                )
                .symbolEffect(
                    .bounce,
                    value: isSelected
                )

                if isSelected {
                    Text(tab.title)
                        .font(
                            .system(
                                size: 13,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .lineLimit(1)
                        .transition(
                            .asymmetric(
                                insertion:
                                    .opacity.combined(
                                        with: .move(
                                            edge: .leading
                                        )
                                    ),
                                removal: .opacity
                            )
                        )
                }
            }
            .foregroundStyle(
                isSelected
                    ? Color.white
                    : Color.secondary
            )
            .frame(
                maxWidth: isSelected
                    ? .infinity
                    : nil
            )
            .padding(.horizontal, isSelected ? 15 : 12)
            .padding(.vertical, 12)
            .background {
                if isSelected {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    tab.color,
                                    tab.color.opacity(0.65)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .matchedGeometryEffect(
                            id: "ACTIVE_TAB",
                            in: tabAnimation
                        )
                        .shadow(
                            color: tab.color.opacity(0.45),
                            radius: 10,
                            x: 0,
                            y: 4
                        )
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(
            isSelected ? .isSelected : []
        )
    }
}

// MARK: - Tabs

private enum AppTab:
    String,
    CaseIterable,
    Identifiable {

    case home
    case stats
    case map
    case settings

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .home:
            return "Home"

        case .stats:
            return "Stats"

        case .map:
            return "Map"

        case .settings:
            return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home:
            return "gamecontroller"

        case .stats:
            return "chart.bar"

        case .map:
            return "map"

        case .settings:
            return "gearshape"
        }
    }

    var selectedIcon: String {
        switch self {
        case .home:
            return "gamecontroller.fill"

        case .stats:
            return "chart.bar.fill"

        case .map:
            return "map.fill"

        case .settings:
            return "gearshape.fill"
        }
    }

    var color: Color {
        switch self {
        case .home:
            return .purple

        case .stats:
            return .blue

        case .map:
            return .green

        case .settings:
            return .orange
        }
    }
}

#Preview {
    MainTabView()
}
