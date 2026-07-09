//
//  GameSession.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-08.
//

import Foundation

struct GameSession: Identifiable, Codable {
    var id = UUID()
    let mode: GameMode
    let score: Int
    let timestamp: Date
    let latitude: Double
    let longitude: Double
}
