//
//  QuizCategory.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-10.
//

import SwiftUI

// MARK: - Open Trivia DB Categories
// IDs match opentdb.com/api_category.php — passed straight into the ?category= param.
enum QuizCategory: Int, CaseIterable, Identifiable {
    case any = 0
    case generalKnowledge = 9
    case books = 10
    case film = 11
    case music = 12
    case television = 14
    case videoGames = 15
    case scienceNature = 17
    case computers = 18
    case mythology = 20
    case sports = 21
    case geography = 22
    case history = 23
    case animals = 27

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .any: return "Any Genre"
        case .generalKnowledge: return "General Knowledge"
        case .books: return "Books"
        case .film: return "Film"
        case .music: return "Music"
        case .television: return "Television"
        case .videoGames: return "Video Games"
        case .scienceNature: return "Science & Nature"
        case .computers: return "Computers"
        case .mythology: return "Mythology"
        case .sports: return "Sports"
        case .geography: return "Geography"
        case .history: return "History"
        case .animals: return "Animals"
        }
    }

    var icon: String {
        switch self {
        case .any: return "shuffle"
        case .generalKnowledge: return "brain.head.profile"
        case .books: return "book.fill"
        case .film: return "film.fill"
        case .music: return "music.note"
        case .television: return "tv.fill"
        case .videoGames: return "gamecontroller.fill"
        case .scienceNature: return "leaf.fill"
        case .computers: return "desktopcomputer"
        case .mythology: return "bolt.fill"
        case .sports: return "sportscourt.fill"
        case .geography: return "globe.americas.fill"
        case .history: return "building.columns.fill"
        case .animals: return "pawprint.fill"
        }
    }

    /// Pulled from AppTheme.genrePalette by position, not hand-picked per case —
    /// keeps every color in the app coming from one shared source.
    var color: Color {
        if self == .any { return AppTheme.brand }
        let index = QuizCategory.allCases.firstIndex(of: self) ?? 0
        return AppTheme.genreColor(at: index)
    }

    /// Query param appended to the OpenTDB URL, empty for "Any Genre".
    var queryParam: String {
        self == .any ? "" : "&category=\(rawValue)"
    }
}
