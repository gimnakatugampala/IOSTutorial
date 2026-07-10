//
//  ScoreBadge.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-07.
//

import SwiftUI

struct ScoreBadge: View {
    let title: String
    let score: Int
    var color: Color = AppTheme.brand

    var body: some View {
        VStack(spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppTheme.textSecondary)

            Text("\(score)")
                .font(.headline).bold()
                .foregroundColor(score > 0 ? color : AppTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial.opacity(0.5))
        .cornerRadius(AppTheme.radiusButton - 4)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusButton - 4)
                .stroke(color.opacity(score > 0 ? 0.5 : 0.15), lineWidth: 1)
        )
    }
}

#Preview {
    ScoreBadge(title: "HIGH SCORE", score: 42, color: AppTheme.tapFrenzy)
}
