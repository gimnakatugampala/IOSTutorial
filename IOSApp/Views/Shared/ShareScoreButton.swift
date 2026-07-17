//
//  ShareScoreButton.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-17.
//


//
//  One shared "Share Score" control used on every game-over screen (Tap
//  Frenzy, Light It Up, Quiz Rush) so the button looks and behaves the same
//  everywhere instead of each mode rolling its own share UI. Uses the native
//  SwiftUI ShareLink, which presents the system share sheet (Messages,
//  Mail, social apps, copy, etc.) with no extra plumbing required.

import SwiftUI

struct ShareScoreButton: View {
    /// The pre-built message to hand to the system share sheet, e.g.
    /// "I scored 42 points in Tap Frenzy! 🎮"
    let shareText: String
    var tint: Color = AppTheme.brand

    var body: some View {
        ShareLink(item: shareText) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 15, weight: .bold))
                Text("Share Score")
                Spacer()
            }
            .font(.headline)
            .foregroundColor(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            .cornerRadius(AppTheme.radiusButton)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusButton)
                    .stroke(tint.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(PressableStyle())
    }
}

#Preview {
    ShareScoreButton(shareText: "I scored 42 points in Tap Frenzy! 🎮", tint: AppTheme.tapFrenzy)
        .padding()
        .background(AppTheme.background)
}
