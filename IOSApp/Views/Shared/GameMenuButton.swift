//
//  GameMenuButton.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-07.
//

import SwiftUI

struct GameMenuButton: View {
    let title: String
    let icon: String
    let gradientColors: [Color]
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon).font(.title).foregroundColor(.white)
            Text(title).font(.title2).bold().foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.right.circle.fill").font(.title2).foregroundColor(.white.opacity(0.8))
        }
        .padding(22)
        .background(.ultraThinMaterial)
        .cornerRadius(25)
        .overlay(RoundedRectangle(cornerRadius: 25).stroke(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5).opacity(0.8))
    }
}


#Preview {
    GameMenuButton(title: "Tap Frenzy", icon: "hand.tap.fill", gradientColors: [.blue, .purple])
}
