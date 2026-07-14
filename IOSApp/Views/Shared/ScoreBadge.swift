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

// MARK: - SegmentedFilterBar
/// A themed stand-in for `.pickerStyle(.segmented)` — the native control's
/// unselected-text color doesn't contrast against AppTheme's dark background,
/// so this draws its own pill segments using AppTheme colors instead.
struct SegmentedFilterBar<T: Hashable & Identifiable>: View {
    let options: [T]
    @Binding var selection: T
    var label: (T) -> String
    var tint: Color = AppTheme.brand

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options) { option in
                let isSelected = option == selection

                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    withAnimation(.spring(response: 0.3)) { selection = option }
                } label: {
                    Text(label(option))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isSelected ? tint : Color.clear)
                        .clipShape(Capsule())
                }
                .buttonStyle(PressableStyle())
            }
        }
        .padding(4)
        .background(.ultraThinMaterial.opacity(0.5))
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(AppTheme.cardBorder, lineWidth: 1)
        )
    }
}

#Preview("Filter Bar") {
    StatefulPreviewWrapper(StatsDateRange.allTime) { binding in
        SegmentedFilterBar(
            options: StatsDateRange.allCases,
            selection: binding,
            label: { $0.rawValue }
        )
        .padding()
        .background(AppTheme.background)
    }
}

/// Tiny helper so the preview above can hold @State for a binding —
/// #Preview macros can't declare @State directly.
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    let content: (Binding<Value>) -> Content

    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        self._value = State(initialValue: value)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}
