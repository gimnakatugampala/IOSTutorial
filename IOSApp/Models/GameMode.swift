//
//  GameMode.swift
//  IOSApp
//

import Foundation
import SwiftUI

enum GameMode: String, Codable, CaseIterable, Identifiable {
    case tapFrenzy = "Tap Frenzy"
    case lightItUp = "Light It Up"
    case quizRush = "Quiz Rush"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .tapFrenzy: return "hand.tap.fill"
        case .lightItUp: return "lightbulb.max.fill"
        case .quizRush: return "questionmark.bubble.fill"
        }
    }

    var themeColor: Color {
        switch self {
        case .tapFrenzy: return AppTheme.tapFrenzy
        case .lightItUp: return AppTheme.lightItUp
        case .quizRush: return AppTheme.quizRush
        }
    }

    var shortLabel: String {
        switch self {
        case .tapFrenzy: return "Tap"
        case .lightItUp: return "Light"
        case .quizRush: return "Quiz"
        }
    }
}
