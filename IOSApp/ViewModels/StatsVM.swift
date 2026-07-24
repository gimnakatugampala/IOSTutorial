//
//  StatsVM.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-07.
//
import SwiftUI
import Combine

class StatsVM: ObservableObject {
    // @Published means whenever this array changes, the UI automatically updates
    @Published var sessions: [GameSession] = []
    
    private let saveKey = "PlayHub_SavedSessions"
    
    init() {
        loadSessions()
    }
    
    // Load data from device memory when the app starts
    func loadSessions() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return }
        
        do {
            let decoded = try JSONDecoder().decode([GameSession].self, from: data)
            DispatchQueue.main.async {
                // Sort by newest first
                self.sessions = decoded.sorted { $0.timestamp > $1.timestamp }
            }
        } catch {
            print("Failed to decode sessions: \(error)")
        }
    }
    
    // Call this function whenever a game finishes.
    //
    // This also reaches out to RandomUserService (randomuser.me) for a
    // placeholder "player" — a name + avatar — and attaches it to the saved
    // session, so the Map tab can show who "played" each pin. That's why
    // this is now async: every call site (the three game-over screens)
    // wraps it in a `Task { await ... }`. If the lookup fails for any
    // reason, the session still saves — it just has no name/photo, exactly
    // like a session saved before this feature existed.
    @MainActor
    func saveNewSession(
        mode: GameMode,
        score: Int,
        lat: Double,
        lon: Double,
        difficulty: String? = nil,
        levelReached: String? = nil,
        correctAnswers: Int? = nil,
        incorrectAnswers: Int? = nil,
        genre: String? = nil
    ) async {
        let player = await RandomUserService.fetchRandomPlayer()

        let newSession = GameSession(
            mode: mode,
            score: score,
            timestamp: Date(),
            latitude: lat,
            longitude: lon,
            difficulty: difficulty,
            levelReached: levelReached,
            correctAnswers: correctAnswers,
            incorrectAnswers: incorrectAnswers,
            genre: genre,
            playerName: player?.name,
            playerImageURL: player?.imageURL
        )
        
        sessions.insert(newSession, at: 0)
        persistData()
    }
    
    // Encode the array into JSON and save to UserDefaults
    private func persistData() {
        do {
            let encoded = try JSONEncoder().encode(sessions)
            UserDefaults.standard.set(encoded, forKey: saveKey)
        } catch {
            print("Failed to encode sessions: \(error)")
        }
    }
    
    // Helper function for the charts: Get the highest score for a specific mode
    func highestScore(for mode: GameMode) -> Int {
        let modeSessions = sessions.filter { $0.mode == mode }
        return modeSessions.map { $0.score }.max() ?? 0
    }
    
    // Call this from Settings' "Clear All Game Data" action.
    func clearAllSessions() {
        sessions.removeAll()
        UserDefaults.standard.removeObject(forKey: saveKey)
    }
    
    
    // Consecutive days (ending today or yesterday) with at least one session —
    // shared by Home and Stats so both read the same definition of "streak."
    var currentStreak: Int {
        let calendar = Calendar.current
        let playedDays = Set(sessions.map { calendar.startOfDay(for: $0.timestamp) })
        guard !playedDays.isEmpty else { return 0 }
        
        var cursor = calendar.startOfDay(for: Date())
        if !playedDays.contains(cursor) {
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        
        var streak = 0
        while playedDays.contains(cursor) {
            streak += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        return streak
    }
    
    // Whichever mode currently holds the single highest score, if any. (Out of all the games)
    var topMode: GameMode? {
        let ranked = GameMode.allCases.map { ($0, highestScore(for: $0)) }
        guard let best = ranked.max(by: { $0.1 < $1.1 }), best.1 > 0 else { return nil }
        return best.0
    }
}
