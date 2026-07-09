//
//  StatsTab.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-08.
//

import SwiftUI
import Charts

struct StatsTab: View {
    // We will link this to StatsVM to pull real GameSession data later
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // SwiftUI Charts Requirement
                VStack(alignment: .leading) {
                    Text("High Scores by Mode")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Chart {
                        // Dummy data for the template - StatsVM will populate this
                        BarMark(x: .value("Mode", "Tap Frenzy"), y: .value("Score", 150))
                            .foregroundStyle(Color.purple)
                        BarMark(x: .value("Mode", "Light It Up"), y: .value("Score", 85))
                            .foregroundStyle(Color.orange)
                        BarMark(x: .value("Mode", "Quiz Rush"), y: .value("Score", 120))
                            .foregroundStyle(Color.cyan)
                    }
                    .frame(height: 250)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Recent Games List Area
                VStack(alignment: .leading) {
                    Text("Recent Sessions")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    List {
                        Text("GameSession data will appear here")
                            .foregroundColor(.gray)
                    }
                    .frame(minHeight: 300)
                    .listStyle(.plain)
                }
            }
            .padding(.top)
        }
        .navigationTitle("Statistics")
    }
}

#Preview {
    NavigationStack {
        StatsTab()
    }
}
