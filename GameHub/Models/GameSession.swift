//
//  GameSession.swift
//  sample1
//

import Foundation

struct GameSession: Identifiable, Codable {
    var id: UUID = UUID()
    var mode: GameMode
    var score: Int
    var timestamp: Date
    var latitude: Double
    var longitude: Double
}
