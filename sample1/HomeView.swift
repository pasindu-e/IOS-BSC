//
//  HomeView.swift
//  sample1
//
//  Week 2 – Navigation shell that hosts both game modes.
//

import SwiftUI
internal import CoreData

// MARK: - HomeView
struct HomeView: View {

    // Best scores shown on the home cards.
    // Tap Frenzy keeps its Core Data score; Light It Up and Quiz Rush use @AppStorage.
    @AppStorage("highScore_lightItUp") private var lightItUpBest = 0
    @AppStorage("highScore_quizRush")  private var quizRushBest  = 0

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 28) {

                // Header
                VStack(spacing: 8) {
                    Text("Arcade")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Choose a game mode")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 60)
                .padding(.bottom, 12)

                // Mode 1 – Tap Frenzy
                NavigationLink {
                    ContentView()
                } label: {
                    modeCard(
                        title: "Tap Frenzy",
                        subtitle: "Tap fast. Keep combos alive.",
                        systemImage: "hand.tap.fill",
                        colors: [.indigo, .purple],
                        best: nil
                    )
                }

                // Mode 2 – Light It Up
                NavigationLink {
                    LightItUpView()
                } label: {
                    modeCard(
                        title: "Light It Up",
                        subtitle: "Tap the lit card before it fades.",
                        systemImage: "square.grid.3x3.fill",
                        colors: [.blue, .cyan],
                        best: lightItUpBest
                    )
                }

                // Mode 3 – Quiz Rush
                NavigationLink {
                    QuizRushView()
                } label: {
                    modeCard(
                        title: "Quiz Rush",
                        subtitle: "Answer live trivia. Build streaks.",
                        systemImage: "brain.head.profile",
                        colors: [.orange, .red],
                        best: quizRushBest > 0 ? quizRushBest : nil
                    )
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Mode card
    private func modeCard(title: String,
                          subtitle: String,
                          systemImage: String,
                          colors: [Color],
                          best: Int?) -> some View {
        HStack(spacing: 18) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                if let best, best > 0 {
                    Text("Best: \(best)")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.9))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: colors,
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: colors.first?.opacity(0.5) ?? .clear, radius: 14, y: 6)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack { HomeView() }
        .environment(\.managedObjectContext,
                     PersistenceController.shared.container.viewContext)
        .environment(SessionStore())
        .environment(LocationService())
}
