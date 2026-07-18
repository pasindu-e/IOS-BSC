//
//  GameMode.swift
//  sample1
//

import SwiftUI

enum GameMode: String, Codable, CaseIterable {
    case tapFrenzy = "Tap Frenzy"
    case lightItUp = "Light It Up"
    case quizRush  = "Quiz Rush"

    var accentColor: Color {
        switch self {
        case .tapFrenzy: .purple
        case .lightItUp: .cyan
        case .quizRush:  .orange
        }
    }

    var icon: String {
        switch self {
        case .tapFrenzy: "hand.tap.fill"
        case .lightItUp: "square.grid.3x3.fill"
        case .quizRush:  "brain.head.profile"
        }
    }
}
