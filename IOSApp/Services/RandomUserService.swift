//
//  RandomUserService.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-17.
//


//  Thin wrapper around the free, key-less randomuser.me API. Used to attach
//  a placeholder "player" (a name + avatar photo) to each saved GameSession,
//  so the Map tab has a face and a name to show on every pin instead of
//  just a score and timestamp.

import Foundation

// MARK: - API Models
private struct RandomUserResponse: Codable {
    let results: [RandomUserResult]
}

private struct RandomUserResult: Codable {
    let name: RandomUserName
    let picture: RandomUserPicture
}

private struct RandomUserName: Codable {
    let first: String
    let last: String
}

private struct RandomUserPicture: Codable {
    let large: String
    let medium: String
    let thumbnail: String
}

enum RandomUserService {

    /// Fetches one random fake player to attach to a just-finished game
    /// session. Returns nil on any failure (offline, timeout, decode error)
    /// rather than throwing — a placeholder-name lookup failing should never
    /// block saving the player's actual score.
    static func fetchRandomPlayer() async -> (name: String, imageURL: String)? {
        guard let url = URL(string: "https://randomuser.me/api/") else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 8

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try JSONDecoder().decode(RandomUserResponse.self, from: data)
            guard let result = decoded.results.first else { return nil }

            let fullName = "\(result.name.first) \(result.name.last)"
            return (name: fullName, imageURL: result.picture.large)
        } catch {
            print("RandomUserService: failed to fetch a random player: \(error.localizedDescription)")
            return nil
        }
    }
}
