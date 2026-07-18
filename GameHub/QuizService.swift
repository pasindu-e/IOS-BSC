//
//  QuizService.swift
//  sample1
//

import Foundation

enum QuizServiceError: Error {
    case badResponseCode
}

struct QuizService {
    private static let endpoint = URL(string: "https://opentdb.com/api.php?amount=10&type=multiple")!

    static func fetch() async throws -> [TriviaQuestion] {
        let (data, _) = try await URLSession.shared.data(from: endpoint)
        let response = try JSONDecoder().decode(TriviaResponse.self, from: data)
        guard response.responseCode == 0 else { throw QuizServiceError.badResponseCode }
        return response.results
    }
}
