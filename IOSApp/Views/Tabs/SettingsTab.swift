//
//  SettingsTab.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-08.
//

import SwiftUI

struct SettingsTab: View {
    // State to hold the user's chosen notification time
    @State private var reminderTime = Date()
    @State private var notificationsEnabled = false
    
    var body: some View {
        Form {
            Section(header: Text("Daily Challenge Reminder"), footer: Text("We will remind you to play a round every day at this time.")) {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { newValue in
                        if newValue {
                            // We will trigger NotificationService.requestPermission() here
                        }
                    }
                
                if notificationsEnabled {
                    DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .onChange(of: reminderTime) { _ in
                            // We will trigger NotificationService.scheduleDaily() here
                        }
                }
            }
            
            Section(header: Text("Data Management")) {
                Button(role: .destructive) {
                    // Logic to wipe UserDefaults GameSessions
                } label: {
                    Text("Clear All Game Data")
                }
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsTab()
    }
}
