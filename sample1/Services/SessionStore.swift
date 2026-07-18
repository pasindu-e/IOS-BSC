//
//  SessionStore.swift
//  sample1
//

import Foundation
import Observation

@Observable
final class SessionStore {
    private(set) var sessions: [GameSession] = []

    private let key = "v1.gameSessions"

    init() { load() }

    func add(_ session: GameSession) {
        sessions.append(session)
        save()
    }

    func clearAll() {
        sessions = []
        UserDefaults.standard.removeObject(forKey: key)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([GameSession].self, from: data)
        else { return }
        sessions = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
