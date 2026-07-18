//
//  QuizRushView.swift
//  sample1
//

import SwiftUI
internal import _LocationEssentials

struct QuizRushView: View {

    @Environment(SessionStore.self) private var sessionStore
    @Environment(LocationService.self) private var locationService

    @StateObject private var vm = QuizRushViewModel()
    @State private var shakeOffset: CGFloat = 0
    @State private var sessionSaved = false
    @State private var deltaOffset: CGFloat = 0
    @State private var deltaOpacity: Double = 0
    @State private var displayedScore = 0

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            switch vm.state {
            case .loading:
                loadingView
            case .failed(let msg):
                errorView(msg)
            case .playing:
                playingView
            case .finished:
                resultsView
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load() }
        .onChange(of: vm.state) { _, newState in
            if newState == .finished, !sessionSaved {
                sessionSaved = true
                let session = GameSession(
                    mode: .quizRush,
                    score: vm.score,
                    timestamp: Date(),
                    latitude: locationService.lastLocation?.coordinate.latitude ?? 0,
                    longitude: locationService.lastLocation?.coordinate.longitude ?? 0
                )
                sessionStore.add(session)
            }
            if newState == .loading { sessionSaved = false }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.orange.opacity(0.2), lineWidth: 4)
                    .frame(width: 64, height: 64)
                ProgressView()
                    .scaleEffect(1.4)
                    .tint(.orange)
            }
            Text("Loading questions…")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            Text("Something went wrong")
                .font(.title2.bold())
                .foregroundColor(.primary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                Task { await vm.load() }
            } label: {
                Text("Retry")
                    .font(.title3.bold())
                    .padding(.horizontal, 48)
                    .padding(.vertical, 16)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
    }

    // MARK: - Playing

    private var playingView: some View {
        VStack(spacing: 0) {

            // Header: timer ring + question counter + score + streak
            HStack(alignment: .center, spacing: 12) {

                timerRing

                VStack(alignment: .leading, spacing: 1) {
                    Text("QUESTION")
                        .font(.caption2.bold())
                        .tracking(1)
                        .foregroundColor(.secondary)
                    Text(vm.progressText)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                        .animation(.default, value: vm.progressText)
                }

                Spacer()

                // Score with floating delta
                ZStack(alignment: .top) {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("SCORE")
                            .font(.caption2.bold())
                            .tracking(1)
                            .foregroundColor(.secondary)
                        Text("\(vm.score)")
                            .font(.subheadline.bold())
                            .foregroundColor(.orange)
                            .contentTransition(.numericText())
                            .animation(.default, value: vm.score)
                    }

                    Text(deltaText)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(vm.lastScoreDelta >= 0 ? .green : .red)
                        .offset(y: deltaOffset)
                        .opacity(deltaOpacity)
                }

                // Streak pill
                if vm.streak > 0 {
                    HStack(spacing: 3) {
                        Text("🔥")
                            .font(.subheadline)
                        Text("\(vm.streak)")
                            .font(.subheadline.bold())
                            .foregroundColor(.orange)
                            .contentTransition(.numericText())
                            .animation(.default, value: vm.streak)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Capsule())
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.35), value: vm.streak > 0)
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemFill))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(colors: [.orange, .red],
                                           startPoint: .leading,
                                           endPoint: .trailing)
                        )
                        .frame(width: geo.size.width * CGFloat(vm.currentIndex + 1) / 10.0)
                        .animation(.easeInOut(duration: 0.4), value: vm.currentIndex)
                }
                .frame(height: 5)
            }
            .frame(height: 5)
            .padding(.horizontal, 20)
            .padding(.top, 14)

            Spacer()

            // Question card
            VStack(spacing: 0) {
                Text(vm.decodedQuestion)
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(24)
                    .frame(maxWidth: .infinity)
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        vm.timedOut ? Color.red.opacity(0.7) : Color.orange.opacity(0.25),
                        lineWidth: vm.timedOut ? 2 : 1
                    )
                    .animation(.easeInOut(duration: 0.2), value: vm.timedOut)
            )
            .overlay(alignment: .bottom) {
                if vm.timedOut {
                    Text("⏰ Time's up!")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 14)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .offset(y: 12)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3), value: vm.timedOut)
            .padding(.horizontal, 20)
            .offset(x: shakeOffset)
            .onChange(of: vm.tappedAnswer) { _, newVal in
                guard newVal != nil else { return }
                showScoreDelta()
                if let t = newVal, t != vm.decodedCorrectAnswer {
                    triggerShake()
                }
            }
            .onChange(of: vm.timedOut) { _, isTimedOut in
                guard isTimedOut else { return }
                triggerShake()
            }

            Spacer()

            // 2×2 answer grid
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(Array(vm.shuffledAnswers.enumerated()), id: \.offset) { index, answer in
                    answerButton(answer, letter: ["A", "B", "C", "D"][index])
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
    }

    // MARK: - Timer Ring

    private var timerRing: some View {
        let fraction = CGFloat(vm.timeRemaining) / CGFloat(vm.totalTime)
        return ZStack {
            Circle()
                .stroke(timerRingColor.opacity(0.2), lineWidth: 4)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(timerRingColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: vm.timeRemaining)
            Text("\(vm.timeRemaining)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(timerRingColor)
                .contentTransition(.numericText())
                .animation(.default, value: vm.timeRemaining)
        }
        .frame(width: 48, height: 48)
    }

    private var timerRingColor: Color {
        vm.timeRemaining >= 7 ? .green : (vm.timeRemaining >= 4 ? .orange : .red)
    }

    // MARK: - Answer Button

    private func answerButton(_ answer: String, letter: String) -> some View {
        let hasAnswered = vm.tappedAnswer != nil || vm.timedOut
        let isTapped = vm.tappedAnswer == answer
        let isCorrect = answer == vm.decodedCorrectAnswer

        let bg: Color = {
            guard hasAnswered else { return Color(.secondarySystemBackground) }
            if isCorrect { return .green.opacity(0.12) }
            if isTapped  { return .red.opacity(0.12) }
            return Color(.secondarySystemBackground).opacity(0.5)
        }()

        let border: Color = {
            guard hasAnswered else { return Color(.separator) }
            if isCorrect { return .green }
            if isTapped  { return .red }
            return Color(.separator).opacity(0.3)
        }()

        let letterBg: Color = {
            guard hasAnswered else { return .orange }
            if isCorrect { return .green }
            if isTapped  { return .red }
            return Color(.systemGray4)
        }()

        return Button {
            vm.answer(answer)
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(letterBg)
                        .frame(width: 30, height: 30)
                    if hasAnswered && isCorrect {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    } else if hasAnswered && isTapped && !isCorrect {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text(letter)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: hasAnswered)

                Text(answer)
                    .font(.subheadline.bold())
                    .foregroundColor(hasAnswered && !isCorrect && !isTapped ? .secondary : .primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(3)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(border, lineWidth: 1.5)
            )
            .animation(.easeInOut(duration: 0.25), value: hasAnswered)
        }
        .buttonStyle(.plain)
        .disabled(hasAnswered)
    }

    // MARK: - Results

    private var resultsView: some View {
        ScrollView {
            VStack(spacing: 24) {

                // Grade
                let grade = gradeBadge
                VStack(spacing: 10) {
                    Text(grade.emoji)
                        .font(.system(size: 72))
                    Text(grade.label)
                        .font(.caption.bold())
                        .tracking(2)
                        .foregroundColor(grade.color)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(grade.color.opacity(0.12))
                        .clipShape(Capsule())
                }

                if vm.isNewRecord {
                    Text("NEW RECORD!")
                        .font(.title3.bold())
                        .foregroundColor(.orange)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.15))
                        .clipShape(Capsule())
                }

                // Score (count-up)
                VStack(spacing: 4) {
                    Text("FINAL SCORE")
                        .font(.caption.bold())
                        .tracking(2)
                        .foregroundColor(.secondary)
                    Text("\(displayedScore)")
                        .font(.system(size: 84, weight: .heavy, design: .rounded))
                        .foregroundColor(.orange)
                        .contentTransition(.numericText())
                        .animation(.default, value: displayedScore)
                }
                .task(id: vm.score) {
                    displayedScore = 0
                    let target = vm.score
                    guard target > 0 else { return }
                    let steps = min(target, 50)
                    let stepSize = max(1, target / steps)
                    var current = 0
                    while current < target {
                        current = min(current + stepSize, target)
                        withAnimation { displayedScore = current }
                        try? await Task.sleep(nanoseconds: 30_000_000)
                    }
                    displayedScore = target
                }

                // Stats card
                HStack(spacing: 0) {
                    statItem(value: "\(vm.correctCount)", label: "CORRECT",
                             icon: "checkmark.circle.fill", color: .green)
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(width: 1, height: 44)
                    statItem(value: "\(vm.wrongCount)", label: "WRONG",
                             icon: "xmark.circle.fill", color: .red)
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(width: 1, height: 44)
                    statItem(value: "\(vm.accuracy)%", label: "ACCURACY",
                             icon: "target", color: .orange)
                }
                .padding(.vertical, 16)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Personal best
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PERSONAL BEST")
                            .font(.caption2.bold())
                            .tracking(1)
                            .foregroundColor(.secondary)
                        Text("\(vm.bestScore)")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Actions
                VStack(spacing: 12) {
                    Button {
                        Task { await vm.restart() }
                    } label: {
                        Label("Play Again", systemImage: "arrow.clockwise")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    ShareLink(item: "I scored \(vm.score) in Quiz Rush — beat that! 🧠") {
                        Label("Share Score", systemImage: "square.and.arrow.up")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.systemFill))
                            .foregroundColor(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 28)
            .padding(.bottom, 40)
        }
    }

    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.primary)
            Text(label)
                .font(.caption2.bold())
                .tracking(1)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var gradeBadge: (emoji: String, label: String, color: Color) {
        switch vm.accuracy {
        case 90...100: return ("🏆", "LEGENDARY", .yellow)
        case 70..<90:  return ("🥇", "EXCELLENT", .orange)
        case 50..<70:  return ("🥈", "GOOD JOB", .teal)
        case 1..<50:   return ("🥉", "KEEP GOING", .indigo)
        default:       return ("💪", "PRACTICE!", .purple)
        }
    }

    // MARK: - Helpers

    private var deltaText: String {
        let d = vm.lastScoreDelta
        if d > 10 { return "+\(d) 🔥" }
        if d > 0  { return "+\(d)" }
        if d < 0  { return "\(d)" }
        return ""
    }

    private func triggerShake() {
        withAnimation(.linear(duration: 0.05).repeatCount(8, autoreverses: true)) {
            shakeOffset = 7
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            shakeOffset = 0
        }
    }

    private func showScoreDelta() {
        guard vm.lastScoreDelta != 0 else { return }
        deltaOffset = 0
        deltaOpacity = 1
        withAnimation(.easeOut(duration: 0.8)) {
            deltaOffset = -30
            deltaOpacity = 0
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack { QuizRushView() }
        .environment(SessionStore())
        .environment(LocationService())
}
