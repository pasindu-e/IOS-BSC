//
//  LightItUpView.swift
//  sample1
//
//  Week 2 – Whack-a-mole style game with automatic level progression.
//

import SwiftUI
internal import Combine
internal import _LocationEssentials
internal import _LocationEssentials

// MARK: - Card model
struct Card: Identifiable {
    let id: Int
    var isLit: Bool = false
}

// MARK: - Level progression (L1 → L4 inside a single round)
enum LightLevel: Int, CaseIterable {
    case l1, l2, l3, l4

    /// Pick the level based on how far into the round we are.
    static func current(forElapsed elapsed: Double) -> LightLevel {
        switch elapsed {
        case ..<15:  return .l1
        case ..<30:  return .l2
        case ..<45:  return .l3
        default:     return .l4
        }
    }

    var cardCount: Int {
        switch self {
        case .l1: return 3   // row of 3
        case .l2: return 4   // 2 × 2
        case .l3: return 6   // 2 × 3
        case .l4: return 9   // 3 × 3
        }
    }

    var columns: Int {
        switch self {
        case .l1: return 3
        case .l2: return 2
        case .l3: return 3
        case .l4: return 3
        }
    }

    /// How long a card stays lit (also the tick interval).
    var litWindow: Double {
        switch self {
        case .l1: return 1.5
        case .l2: return 1.2
        case .l3: return 1.0
        case .l4: return 0.8
        }
    }

    /// Cards lit at the same time.
    var litCount: Int { self == .l4 ? 2 : 1 }

    /// Bonus – distinct glow colour per level.
    var glow: Color {
        switch self {
        case .l1: return .green
        case .l2: return .blue
        case .l3: return .yellow
        case .l4: return .red
        }
    }

    var title: String {
        switch self {
        case .l1: return "Level 1"
        case .l2: return "Level 2"
        case .l3: return "Level 3"
        case .l4: return "Level 4"
        }
    }
}

// MARK: - LightItUpView
struct LightItUpView: View {

    @Environment(SessionStore.self) private var sessionStore
    @Environment(LocationService.self) private var locationService

    // Persist high score per mode (separate @AppStorage key).
    @AppStorage("highScore_lightItUp") private var highScore = 0

    // Round configuration
    private let roundLength: Double = 60
    private let step: Double = 0.1     // master clock resolution

    // Game state
    @State private var cards: [Card] = []
    @State private var score = 0
    @State private var roundElapsed: Double = 0
    @State private var windowElapsed: Double = 0
    @State private var level: LightLevel = .l1
    @State private var gameActive = false
    @State private var gameOver = false
    @State private var isNewRecord = false
    @State private var showLevelFlash = false

    // Single master timer; lit-window timing is derived from it.
    private let clock = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    private var timeRemaining: Int { max(0, Int(ceil(roundLength - roundElapsed))) }

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

            // Bonus – level-up flash overlay
            if showLevelFlash {
                level.glow.opacity(0.18)
                    .ignoresSafeArea()
                    .overlay(
                        Text(level.title)
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .foregroundColor(level.glow)
                    )
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(clock) { _ in onTick() }
    }

    // MARK: - Start screen
    private var startView: some View {
        VStack(spacing: 32) {
            Text("Light It Up")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundColor(.primary)

            if highScore > 0 {
                VStack(spacing: 4) {
                    Text("BEST")
                        .font(.caption.bold())
                        .foregroundColor(.cyan.opacity(0.7))
                    Text("\(highScore)")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundColor(.cyan)
                }
            }

            Text("Tap the lit card before it goes dark.\nGrid grows and speeds up over 60 s.\nMissed or wrong taps cost a point.")
                .multilineTextAlignment(.center)
                .font(.body)
                .foregroundColor(.secondary)

            Button(action: startGame) {
                Text("Start Game")
                    .font(.title2.bold())
                    .padding(.horizontal, 48)
                    .padding(.vertical, 18)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
    }

    // MARK: - Playing screen
    private var playingView: some View {
        VStack(spacing: 0) {

            // Score + level row
            HStack(spacing: 24) {
                VStack {
                    Text("SCORE")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    Text("\(score)")
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                }
                VStack {
                    Text("LEVEL")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    Text(level.title.replacingOccurrences(of: "Level ", with: "L"))
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                        .foregroundColor(level.glow)
                }
            }
            .padding(.top, 24)

            Spacer()

            // The grid
            let columns = Array(repeating: GridItem(.flexible(), spacing: 16),
                                count: level.columns)
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(cards) { card in
                    cardView(card)
                }
            }
            .padding(.horizontal, 24)
            .animation(.spring(response: 0.3), value: level)

            Spacer()

            // Timer bar
            Text("\(timeRemaining)s")
                .font(.headline)
                .foregroundColor(.secondary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemFill))
                    RoundedRectangle(cornerRadius: 8)
                        .fill(level.glow)
                        .frame(width: geo.size.width
                               * CGFloat(roundLength - roundElapsed)
                               / CGFloat(roundLength))
                }
                .frame(height: 12)
                .padding(.horizontal, 32)
            }
            .frame(height: 12)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Single card
    private func cardView(_ card: Card) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(card.isLit ? level.glow : Color(.systemGray5))
            .frame(height: 90)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.separator), lineWidth: 1)
            )
            .shadow(color: card.isLit ? level.glow.opacity(0.8) : .clear,
                    radius: card.isLit ? 18 : 0)
            .scaleEffect(card.isLit ? 1.08 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: card.isLit)
            .contentShape(RoundedRectangle(cornerRadius: 16))
            .onTapGesture { handleTap(card) }
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
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.cyan.opacity(0.2))
                    .clipShape(Capsule())
            }

            VStack(spacing: 8) {
                Text("SCORE")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                Text("\(score)")
                    .font(.system(size: 80, weight: .heavy, design: .rounded))
                    .foregroundColor(.cyan)
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
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }

            ShareLink(item: "I just scored \(score) in Light It Up — beat that! 💡") {
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

    // MARK: - Game logic

    private func startGame() {
        score         = 0
        roundElapsed  = 0
        windowElapsed = 0
        level         = .l1
        gameOver      = false
        isNewRecord   = false
        cards         = makeCards(for: .l1)
        gameActive    = true
        lightTick()
    }

    /// Master clock – advances the round and derives lit-window ticks.
    private func onTick() {
        guard gameActive else { return }

        roundElapsed += step
        if roundElapsed >= roundLength {
            endGame()
            return
        }

        // Advance the level when the round timer crosses a threshold.
        let newLevel = LightLevel.current(forElapsed: roundElapsed)
        if newLevel != level {
            level         = newLevel
            cards         = makeCards(for: newLevel)
            windowElapsed = 0
            flashLevelUp()
            lightTick()
            return
        }

        // Lit-window tick.
        windowElapsed += step
        if windowElapsed >= level.litWindow {
            windowElapsed = 0
            lightTick()
        }
    }

    /// Dim any still-lit cards (a miss) and light fresh ones.
    private func lightTick() {
        // Any card still lit was never tapped → penalty.
        if cards.contains(where: { $0.isLit }) {
            applyPenalty()
        }

        for index in cards.indices { cards[index].isLit = false }

        let pick = cards.indices.shuffled().prefix(level.litCount)
        for index in pick { cards[index].isLit = true }
    }

    private func handleTap(_ card: Card) {
        guard gameActive,
              let index = cards.firstIndex(where: { $0.id == card.id }) else { return }

        if cards[index].isLit {
            score += 1
            cards[index].isLit = false      // tapped in time, no penalty later
        } else {
            applyPenalty()
        }
    }

    private func applyPenalty() {
        score = max(0, score - 1)
    }

    private func endGame() {
        gameActive = false
        for index in cards.indices { cards[index].isLit = false }

        if score > highScore {
            highScore   = score
            isNewRecord = true
        }

        let session = GameSession(
            mode: .lightItUp,
            score: score,
            timestamp: Date(),
            latitude: locationService.lastLocation?.coordinate.latitude ?? 0,
            longitude: locationService.lastLocation?.coordinate.longitude ?? 0
        )
        sessionStore.add(session)

        gameOver = true
    }

    private func makeCards(for level: LightLevel) -> [Card] {
        (0..<level.cardCount).map { Card(id: $0) }
    }

    private func flashLevelUp() {
        withAnimation(.easeOut(duration: 0.2)) { showLevelFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeIn(duration: 0.3)) { showLevelFlash = false }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack { LightItUpView() }
        .environment(SessionStore())
        .environment(LocationService())
}
