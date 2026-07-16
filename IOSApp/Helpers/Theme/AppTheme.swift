//
//  AppTheme.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-10.
//
//  Single source of truth for color across the app. Every game mode reads
//  from here instead of hardcoding its own Color(...) literals, so retuning
//  the palette is a one-file edit instead of a hunt through every view.

import SwiftUI

// MARK: - Accent Options
// User-selectable presets for AppTheme.brand. Kept deliberately small and
// curated (rather than a full color wheel) so every option still reads well
// against the app's dark background and doesn't collide with the fixed
// semantic colors (success/danger/warning) below.
enum AccentOption: String, CaseIterable, Identifiable {
    case violet, blue, rose, teal, orange, indigo

    static let storageKey = "selectedAccentColor"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .violet: return Color("AccentColor")   // original asset-backed default
        case .blue:   return Color(red: 0.25, green: 0.47, blue: 0.95)
        case .rose:   return Color(red: 0.88, green: 0.28, blue: 0.52)
        case .teal:   return Color(red: 0.15, green: 0.70, blue: 0.65)
        case .orange: return Color(red: 0.95, green: 0.55, blue: 0.20)
        case .indigo: return Color(red: 0.40, green: 0.38, blue: 0.90)
        }
    }

    var displayName: String {
        switch self {
        case .violet: return "Violet"
        case .blue: return "Blue"
        case .rose: return "Rose"
        case .teal: return "Teal"
        case .orange: return "Orange"
        case .indigo: return "Indigo"
        }
    }
}

enum AppTheme {

    // MARK: - Theme color
    // Now a computed property instead of a stored static let, so it always
    // reflects whatever the user last picked in Settings rather than being
    // cached at first access.
    static var brand: Color {
        let saved = UserDefaults.standard.string(forKey: AccentOption.storageKey) ?? AccentOption.violet.rawValue
        return (AccentOption(rawValue: saved) ?? .violet).color
    }

    // MARK: - Surfaces
    static let background = Color(red: 0.043, green: 0.043, blue: 0.071)   // page bg
    static let card = Color.white.opacity(0.05)                            // resting card fill
    static let cardElevated = Color.white.opacity(0.08)                    // hovered/selected card fill
    static let cardBorder = Color.white.opacity(0.1)                       // resting border
    static let cardBorderStrong = Color.white.opacity(0.22)                // selected/emphasized border

    // MARK: - Text
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textMuted = Color.white.opacity(0.4)

    // MARK: - Semantic feedback
    // These mean the same thing everywhere they appear — never repurpose them
    // for decoration.
    static let success = Color(red: 0.20, green: 0.78, blue: 0.35)   // correct answer, safe
    static let danger  = Color(red: 1.00, green: 0.23, blue: 0.19)   // wrong answer, life lost
    static let warning = Color(red: 1.00, green: 0.62, blue: 0.04)   // streak, caution, mid-risk

    // MARK: - Per-mode identity
    // One hue per game mode so each screen reads as itself at a glance.
    static let tapFrenzy = Color(red: 0.88, green: 0.14, blue: 0.37)   // pink-red
    static let lightItUp = Color(red: 0.20, green: 0.68, blue: 0.90)   // cyan-blue
    // Computed (not stored) since it just mirrors brand.
    static var quizRush: Color { brand }

    // MARK: - Difficulty ramp
    // Cool → hot as stakes rise. Used by Light It Up's level progression and
    // shared with anything else that needs an escalating-intensity scale.
    static let rampStops: [Color] = [
        success,                                    // L1 — calm
        lightItUp,                                   // L2
        Color(red: 1.00, green: 0.84, blue: 0.04),   // L3 — amber
        warning,                                      // L4
        danger                                        // overdrive — max intensity
    ]

    static func ramp(_ index: Int) -> Color {
        rampStops[min(max(index, 0), rampStops.count - 1)]
    }

    // MARK: - Genre palette (Quiz Rush category chips)
    // A fixed, curated set so every genre pulls from the same family of hues
    // instead of arbitrary system colors. Cycled by index, not hand-picked
    // per case, so adding a genre never requires choosing a new color.
    // Computed (not stored) since the first entry depends on the live brand color.
    static var genrePalette: [Color] {
        [
            brand,
            Color(red: 0.94, green: 0.54, blue: 0.20),   // amber
            Color(red: 0.90, green: 0.30, blue: 0.55),   // rose
            success,
            lightItUp,
            Color(red: 0.80, green: 0.55, blue: 0.25),   // bronze
            danger,
            Color(red: 0.45, green: 0.75, blue: 0.35),   // olive green
            Color(red: 0.40, green: 0.55, blue: 0.95),   // blue
            warning,
            Color(red: 0.60, green: 0.60, blue: 0.66),   // slate
            Color(red: 0.95, green: 0.45, blue: 0.15),   // burnt orange
            Color(red: 0.30, green: 0.80, blue: 0.75)    // teal
        ]
    }

    static func genreColor(at index: Int) -> Color {
        let palette = genrePalette
        return palette[index % palette.count]
    }

    // MARK: - Metrics
    // Shared corner radii keep every card/pill/button in the app visually consistent.
    static let radiusCard: CGFloat = 18
    static let radiusPill: CGFloat = 20
    static let radiusButton: CGFloat = 16

    // MARK: - Gradients
    /// Universal brand gradient for main CTA buttons and hero text.
    /// Computed (not stored) so it updates the instant the accent changes.
    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [AppTheme.brand, Color(red: 0.6, green: 0.3, blue: 0.9)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Explosive pink/red gradient for Tap Frenzy UI
    static let tapFrenzyGradient = LinearGradient(
        colors: [AppTheme.tapFrenzy, Color(red: 1.0, green: 0.4, blue: 0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Neon cyan/blue gradient for Light It Up UI
    static let lightItUpGradient = LinearGradient(
        colors: [AppTheme.lightItUp, Color(red: 0.4, green: 0.9, blue: 1.0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Shared button style
/// A slight scale-down + dim on press, used on every tappable card and CTA
/// so tap feedback feels the same across all three game modes.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
