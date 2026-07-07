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
    var body: some View {
        VStack {
            Text(title).font(.caption2).foregroundColor(.white.opacity(0.6))
            Text("\(score)").font(.headline).bold().foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial.opacity(0.5))
        .cornerRadius(12)
    }
}

#Preview {
    ScoreBadge(title: "HIGH SCORE", score: 42)
}
