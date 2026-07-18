//
//  ContentView.swift
//  sample1
//
//  Created by Pasindu Eranga on 2026-06-10.
//

import SwiftUI
internal import CoreData
internal import Combine
internal import _LocationEssentials

// MARK: - Game constants
private enum GameConfig {
    static let gameDuration  = 30        // seconds per round
    static let comboWindow   = 0.5       // seconds to sustain combo
    static let moveInterval  = 2.0       // seconds between button jumps
}

// MARK: - ContentView
struct ContentView: View {

    // MARK: Environment
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(SessionStore.self) private var sessionStore
    @Environment(LocationService.self) private var locationService

    @State private var highScore      = 0
    @State private var isNewRecord    = false

    // MARK: Core game state
    @State private var score          = 0
    @State private var timeRemaining  = GameConfig.gameDuration
    @State private var gameActive     = false
    @State private var gameOver       = false

    // MARK: Challenge 1 – Combo System
    @State private var comboMultiplier = 1
    @State private var lastTapTime: Date = .distantPast

    // MARK: Challenge 3 – Moving Target
    @State private var buttonOffset: CGSize = .zero

    // MARK: Timers
    let countdownTimer = Timer.publish(every: 1,  on: .main, in: .common).autoconnect()
    let moveTimer      = Timer.publish(every: GameConfig.moveInterval,
                                       on: .main, in: .common).autoconnect()

    // MARK: - Body
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            if gameOver {
                gameOverView
            } else if !gameActive {
                startView
            } else {
                playingView
            }
        }
        .onAppear { loadHighScore() }
    }

    // MARK: - Start screen
    private var startView: some View {
        VStack(spacing: 32) {
            Text("Tap Frenzy")
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundColor(.primary)

            // High score badge
            if highScore > 0 {
                VStack(spacing: 4) {
                    Text("BEST")
                        .font(.caption.bold())
                        .foregroundColor(.yellow.opacity(0.7))
                    Text("\(highScore)")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundColor(.yellow)
                }
            }

            Text("Tap as fast as you can!\nKeep combos alive within 0.5 s\nButton jumps every 2 s")
                .multilineTextAlignment(.center)
                .font(.body)
                .foregroundColor(.secondary)

            Button(action: startGame) {
                Text("Start Game")
                    .font(.title2.bold())
                    .padding(.horizontal, 48)
                    .padding(.vertical, 18)
                    .background(Color.indigo)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
    }

    // MARK: - Playing screen
    private var playingView: some View {
        VStack(spacing: 0) {

            // 1. Title
            Text("Tap Frenzy")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(.primary)
                .padding(.top, 48)

            // 2. Score + combo row
            HStack(spacing: 24) {
                VStack {
                    Text("SCORE")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    Text("\(score)")
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                }

                if comboMultiplier > 1 {
                    VStack {
                        Text("COMBO")
                            .font(.caption.bold())
                            .foregroundColor(.orange.opacity(0.7))
                        Text("×\(comboMultiplier)")
                            .font(.system(size: 52, weight: .heavy, design: .rounded))
                            .foregroundColor(.orange)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(.top, 24)
            .animation(.spring(response: 0.3), value: comboMultiplier)

            // 3. Tap button area – fills remaining space so offset works
            GeometryReader { geo in
                tapButton
                    .offset(buttonOffset)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear { randomiseOffset(in: geo.size) }
                    .onChange(of: buttonOffset) { _ in }   // keeps geo live
            }

            // 4. Timer bar at the bottom
            Text("\(timeRemaining)s")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.top, 8)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemFill))
                    RoundedRectangle(cornerRadius: 8)
                        .fill(timerColor)
                        .frame(width: geo.size.width
                               * CGFloat(timeRemaining)
                               / CGFloat(GameConfig.gameDuration))
                        .animation(.linear(duration: 0.9), value: timeRemaining)
                }
                .frame(height: 12)
                .padding(.horizontal, 32)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 40)
            .padding(.bottom, 32)
        }
        .onReceive(countdownTimer) { _ in tickCountdown() }
        .onReceive(moveTimer)      { _ in moveButton()    }
    }

    // MARK: - Tap button (Challenge 3 uses offset; Challenge 1 uses timing)
    private var tapButton: some View {
        Button(action: handleTap) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.indigo, Color.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 140, height: 140)
                .overlay(
                    VStack(spacing: 4) {
                        Text("TAP")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        if comboMultiplier > 1 {
                            Text("×\(comboMultiplier)")
                                .font(.caption.bold())
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                )
                .shadow(color: .purple.opacity(0.6), radius: 20)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Game over screen
    private var gameOverView: some View {
        VStack(spacing: 28) {
            Text("Time's Up!")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundColor(.primary)

            if isNewRecord {
                Text("NEW RECORD!")
                    .font(.title3.bold())
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.yellow.opacity(0.2))
                    .clipShape(Capsule())
            }

            VStack(spacing: 8) {
                Text("SCORE")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                Text("\(score)")
                    .font(.system(size: 80, weight: .heavy, design: .rounded))
                    .foregroundColor(.yellow)
            }

            VStack(spacing: 4) {
                Text("BEST")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                Text("\(highScore)")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundColor(.primary)
            }

            Button(action: startGame) {
                Text("Play Again")
                    .font(.title2.bold())
                    .padding(.horizontal, 48)
                    .padding(.vertical, 18)
                    .background(Color.indigo)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }

            ShareLink(item: "I just scored \(score) in Tap Frenzy — beat that! 🎮") {
                Label("Share Score", systemImage: "square.and.arrow.up")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color(.systemFill))
                    .foregroundColor(.primary)
                    .clipShape(Capsule())
            }
        }
        .padding()
    }

    // MARK: - Helpers

    private var timerColor: Color {
        switch timeRemaining {
        case 11...: return .green
        case 6...10: return .orange
        default: return .red
        }
    }

    private func startGame() {
        score             = 0
        timeRemaining     = GameConfig.gameDuration
        comboMultiplier   = 1
        lastTapTime       = .distantPast
        buttonOffset      = .zero
        gameOver          = false
        gameActive        = true
    }

    private func tickCountdown() {
        guard gameActive else { return }
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            gameActive = false
            saveHighScoreIfNeeded()
            gameOver   = true
        }
    }

    /// Challenge 1 – Combo System
    private func handleTap() {
        let now     = Date()
        let elapsed = now.timeIntervalSince(lastTapTime)

        if elapsed <= GameConfig.comboWindow {
            comboMultiplier += 1
        } else {
            comboMultiplier = 1
        }
        lastTapTime = now
        score      += comboMultiplier
    }

    /// Challenge 3 – Moving Target
    private func moveButton() {
        guard gameActive else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            buttonOffset = CGSize(
                width:  CGFloat.random(in: -120...120),
                height: CGFloat.random(in: -160...120)
            )
        }
    }

    // MARK: - Core Data helpers

    private func loadHighScore() {
        let request = NSFetchRequest<HighScoreEntity>(entityName: "HighScore")
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(keyPath: \HighScoreEntity.value, ascending: false)]
        highScore = Int((try? viewContext.fetch(request).first?.value) ?? 0)
    }

    private func saveHighScoreIfNeeded() {
        if score > highScore {
            isNewRecord = true
            highScore   = score

            let request = NSFetchRequest<HighScoreEntity>(entityName: "HighScore")
            let existing = (try? viewContext.fetch(request)) ?? []
            let record   = existing.first ?? HighScoreEntity(context: viewContext)
            record.value = Int32(score)
            try? viewContext.save()
        } else {
            isNewRecord = false
        }

        let session = GameSession(
            mode: .tapFrenzy,
            score: score,
            timestamp: Date(),
            latitude: locationService.lastLocation?.coordinate.latitude ?? 0,
            longitude: locationService.lastLocation?.coordinate.longitude ?? 0
        )
        sessionStore.add(session)
    }

    private func randomiseOffset(in size: CGSize) {
        let hw = size.width  / 2 - 70
        let hh = size.height / 2 - 70
        buttonOffset = CGSize(
            width:  CGFloat.random(in: -hw...hw),
            height: CGFloat.random(in: -hh...hh)
        )
    }
}


// MARK: - Preview
#Preview {
    ContentView()
        .environment(\.managedObjectContext,
                     PersistenceController.shared.container.viewContext)
        .environment(SessionStore())
        .environment(LocationService())
}
