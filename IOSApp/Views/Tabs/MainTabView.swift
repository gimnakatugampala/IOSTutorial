//
//  MainTabView.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-09.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        // The TabView creates the native iOS bottom navigation bar
        TabView {
            // Tab 1: Home
            NavigationStack {
                HomeTab()
            }
            .tabItem {
                Label("Home", systemImage: "gamecontroller")
            }
            
            // Tab 2: Stats
            NavigationStack {
                StatsTab()
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar")
            }
            
            // Tab 3: Map
            NavigationStack {
                MapTab()
            }
            .tabItem {
                Label("Map", systemImage: "map")
            }
            
            // Tab 4: Settings
            NavigationStack {
                SettingsTab()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        // Optional: Set a custom accent color for the selected tab icon
        .tint(.blue)
    }
}

#Preview {
    MainTabView()
}
