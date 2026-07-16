//
//  ThemeManager.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-16.
//

//
//  ThemeManager.swift
//  IOSApp
//
//  AppTheme stays a plain static namespace (so AppTheme.brand keeps working
//  everywhere without threading an environment object through every view),
//  but nothing observes UserDefaults on its own. This tiny object's
//  @Published property lets the *root* view force an immediate refresh the
//  instant the user picks a new accent in Settings, instead of the rest of
//  the app only picking up the change next time something else redraws it.

import SwiftUI
import Combine

final class ThemeManager: ObservableObject {
    @Published var accent: AccentOption {
        didSet {
            UserDefaults.standard.set(accent.rawValue, forKey: AccentOption.storageKey)
        }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: AccentOption.storageKey) ?? AccentOption.violet.rawValue
        self.accent = AccentOption(rawValue: saved) ?? .violet
    }
}
