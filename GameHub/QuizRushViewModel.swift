//
//  QuizRushViewModel.swift
//  sample1
//

import Foundation
internal import Combine

enum QuizViewState: Equatable {
    case loading, playing, finished
    case failed(String)
}

@MainActor
final class QuizRushViewModel: ObservableObject {

    @Published private(set) var state: QuizViewState = .loading
    @Published private(set) var currentIndex = 0
    @Published private(set) var score = 0
    @Published private(set) var streak = 0
    @Published private(set) var isNewRecord = false
    @Published private(set) var shuffledAnswers: [String] = []
    @Published private(set) var decodedQuestion: String = ""
    @Published private(set) var decodedCorrectAnswer: String = ""
    @Published private(set) var tappedAnswer: String? = nil
    @Published private(set) var timeRemaining: Int = 10
    @Published private(set) var timedOut: Bool = false
    @Published private(set) var correctCount: Int = 0
    @Published private(set) var wrongCount: Int = 0
    @Published private(set) var lastScoreDelta: Int = 0

    private var questions: [TriviaQuestion] = []
    private var timerTask: Task<Void, Never>?
    let totalTime = 10

    var progressText: String {
        guard !questions.isEmpty else { return "" }
        return "\(currentIndex + 1) / \(questions.count)"
    }

    var bestScore: Int {
        UserDefaults.standard.integer(forKey: "highScore_quizRush")
    }

    var accuracy: Int {
        let total = correctCount + wrongCount
        guard total > 0 else { return 0 }
        return Int(Double(correctCount) / Double(total) * 100)
    }

    func load() async {
        state = .loading
        do {
            questions = try await QuizService.fetch()
            correctCount = 0
            wrongCount = 0
            prepare(at: 0)
            state = .playing
            startTimer()
        } catch {
            state = .failed("Could not load questions.\nCheck your connection and try again.")
        }
    }

    func answer(_ tapped: String) {
        guard case .playing = state, tappedAnswer == nil, !timedOut else { return }
        timerTask?.cancel()
        tappedAnswer = tapped

        let correct = tapped == decodedCorrectAnswer
        if correct {
            correctCount += 1
            streak += 1
            let base = streak >= 3 ? 20 : 10
            let timeBonus = timeRemaining > 5 ? 5 : 0
            lastScoreDelta = base + timeBonus
            score += lastScoreDelta
        } else {
            wrongCount += 1
            streak = 0
            lastScoreDelta = -3
            score = max(0, score - 3)
        }

        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 800_000_000)
            self?.advance()
        }
    }

    func restart() async {
        timerTask?.cancel()
        currentIndex = 0
        score = 0
        streak = 0
        isNewRecord = false
        tappedAnswer = nil
        timedOut = false
        questions = []
        shuffledAnswers = []
        decodedQuestion = ""
        decodedCorrectAnswer = ""
        correctCount = 0
        wrongCount = 0
        lastScoreDelta = 0
        await load()
    }

    private func prepare(at index: Int) {
        let q = questions[index]
        decodedQuestion = q.question.htmlDecoded
        decodedCorrectAnswer = q.correctAnswer.htmlDecoded
        shuffledAnswers = q.allAnswers.shuffled().map { $0.htmlDecoded }
        timeRemaining = totalTime
        timedOut = false
    }

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            guard let self else { return }
            while self.timeRemaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                self.timeRemaining = max(0, self.timeRemaining - 1)
            }
            if !Task.isCancelled {
                self.handleTimeout()
            }
        }
    }

    private func handleTimeout() {
        guard tappedAnswer == nil, !timedOut else { return }
        timedOut = true
        wrongCount += 1
        streak = 0
        lastScoreDelta = 0
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 950_000_000)
            self?.advance()
        }
    }

    private func advance() {
        timerTask?.cancel()
        tappedAnswer = nil
        timedOut = false
        let next = currentIndex + 1
        if next >= questions.count {
            finalise()
        } else {
            currentIndex = next
            prepare(at: next)
            startTimer()
        }
    }

    private func finalise() {
        let best = UserDefaults.standard.integer(forKey: "highScore_quizRush")
        if score > best {
            UserDefaults.standard.set(score, forKey: "highScore_quizRush")
            isNewRecord = true
        }
        state = .finished
    }
}
