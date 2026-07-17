//
//  GameSession.swift
//  IOSApp
//

import Foundation

struct GameSession: Identifiable, Codable {
    var id = UUID()
    let mode: GameMode
    let score: Int
    let timestamp: Date
    let latitude: Double
    let longitude: Double

    // Mode-specific extra info — all optional so old saved sessions
    // (encoded before these existed) still decode fine as nil.
    var difficulty: String? = nil       // Tap Frenzy
    var levelReached: String? = nil     // Light It Up
    var correctAnswers: Int? = nil      // Quiz Rush
    var incorrectAnswers: Int? = nil    // Quiz Rush
    var genre: String? = nil            // Quiz Rush

    // Placeholder "player" fetched from randomuser.me the moment the session
    // is saved (see StatsVM.saveNewSession) — gives the Map tab a name and
    // face for each pin. Optional + defaulted like the fields above, so
    // sessions saved before this feature existed keep decoding fine; they
    // simply have no name/photo rather than the app crashing or backfilling
    // one retroactively.
    var playerName: String? = nil
    var playerImageURL: String? = nil

    /// One-line subtitle for the Stats list, tailored per mode.
    var detailText: String? {
        switch mode {
        case .tapFrenzy:
            guard let difficulty else { return nil }
            return "\(difficulty) difficulty"

        case .lightItUp:
            guard let levelReached else { return nil }
            let label = levelReached == "MAX" ? "Overdrive" : "Level \(levelReached)"
            return "Reached \(label)"

        case .quizRush:
            var parts: [String] = []
            if let genre { parts.append(genre) }
            if let correctAnswers, let incorrectAnswers {
                parts.append("✓\(correctAnswers) ✗\(incorrectAnswers)")
            }
            return parts.isEmpty ? nil : parts.joined(separator: "  •  ")
        }
    }
}
