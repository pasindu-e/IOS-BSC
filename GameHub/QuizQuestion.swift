//
//  QuizQuestion.swift
//  sample1
//

import Foundation
internal import UIKit

struct TriviaResponse: Codable {
    let responseCode: Int
    let results: [TriviaQuestion]

    enum CodingKeys: String, CodingKey {
        case responseCode = "response_code"
        case results
    }
}

struct TriviaQuestion: Codable, Identifiable {
    let id = UUID()
    let question: String
    let correctAnswer: String
    let incorrectAnswers: [String]

    var allAnswers: [String] { [correctAnswer] + incorrectAnswers }

    enum CodingKeys: String, CodingKey {
        case question
        case correctAnswer = "correct_answer"
        case incorrectAnswers = "incorrect_answers"
    }
}

extension String {
    // NSAttributedString HTML parsing deadlocks when called from a @MainActor async
    // context, so we decode entities manually instead.
    var htmlDecoded: String {
        guard contains("&") else { return self }
        var s = self
        for (entity, char) in String.htmlEntities {
            s = s.replacingOccurrences(of: entity, with: char)
        }
        return s
    }

    private static let htmlEntities: [(String, String)] = [
        ("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"),
        ("&quot;", "\""), ("&#039;", "'"), ("&#39;", "'"), ("&apos;", "'"),
        ("&nbsp;", " "), ("&hellip;", "…"), ("&mdash;", "—"), ("&ndash;", "–"),
        ("&ldquo;", "\u{201C}"), ("&rdquo;", "\u{201D}"),
        ("&lsquo;", "\u{2018}"), ("&rsquo;", "\u{2019}"),
        ("&eacute;", "é"), ("&egrave;", "è"), ("&ecirc;", "ê"),
        ("&agrave;", "à"), ("&acirc;", "â"), ("&auml;", "ä"),
        ("&oacute;", "ó"), ("&ouml;", "ö"), ("&ocirc;", "ô"),
        ("&uacute;", "ú"), ("&uuml;", "ü"), ("&ucirc;", "û"),
        ("&iacute;", "í"), ("&iuml;", "ï"), ("&icirc;", "î"),
        ("&ntilde;", "ñ"), ("&ccedil;", "ç"),
    ]
}
