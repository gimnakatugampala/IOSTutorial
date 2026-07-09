//
//  GameDifficulty.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-10.
//

import Foundation

enum GameDifficulty: String, CaseIterable, Identifiable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    var id: String { self.rawValue }
}
