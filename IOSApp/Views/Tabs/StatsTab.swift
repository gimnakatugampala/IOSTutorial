//
//  StatsTab.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-08.
//

import SwiftUI
import Charts

class StatsTab: View {
    // This grabs the ViewModel from the app's environment
    @EnvironmentObject var statsVM: StatsVM
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 1. High Score Bar Chart
                VStack(alignment: .leading) {
                    Text("High Scores by Mode")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Chart {
                        BarMark(x: .value("Mode", "Tap Frenzy"), y: .value("Score", statsVM.highestScore(for: .tapFrenzy)))
                            .foregroundStyle(Color.purple)
                        BarMark(x: .value("Mode", "Light It Up"), y: .value("Score", statsVM.highestScore(for: .lightItUp)))
                            .foregroundStyle(Color.orange)
                        BarMark(x: .value("Mode", "Quiz Rush"), y: .value("Score", statsVM.highestScore(for: .quizRush)))
                            .foregroundStyle(Color.cyan)
                    }
                    .frame(height: 250)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // 2. Recent Games List
                VStack(alignment: .leading) {
                    Text("Recent Sessions (\(statsVM.sessions.count))")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if statsVM.sessions.isEmpty {
                        Text("Play a game to see your history here!")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        // Loop through all saved sessions
                        ForEach(statsVM.sessions) { session in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(session.mode.rawValue)
                                        .font(.headline)
                                    Text(session.timestamp, format: .dateTime.month().day().hour().minute())
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Text("\(session.score) pts")
                                    .font(.title3)
                                    .bold()
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                    }
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
            .environmentObject(StatsVM()) // Inject for the preview to work
    }
}
