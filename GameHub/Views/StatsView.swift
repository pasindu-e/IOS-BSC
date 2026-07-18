//
//  StatsView.swift
//  sample1
//

import SwiftUI
import Charts

struct StatsView: View {
    @Environment(SessionStore.self) private var store

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            if store.sessions.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        summaryGrid
                        chartSection
                        recentSection
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No games played yet")
                .font(.title3.bold())
                .foregroundColor(.secondary)
            Text("Complete a game to see your stats here.")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
        }
    }

    // MARK: - Summary cards

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(GameMode.allCases, id: \.self) { mode in
                let modeSessions = store.sessions.filter { $0.mode == mode }
                let best = modeSessions.map(\.score).max() ?? 0

                VStack(alignment: .leading, spacing: 8) {
                    Label(mode.rawValue, systemImage: mode.icon)
                        .font(.caption.bold())
                        .foregroundColor(mode.accentColor)
                        .lineLimit(1)
                    Text("\(modeSessions.count)")
                        .font(.title.bold())
                        .foregroundColor(.primary)
                    Text("games played")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if best > 0 {
                        Text("Best: \(best)")
                            .font(.caption.bold())
                            .foregroundColor(mode.accentColor)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // MARK: - Chart

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Score History")
                .font(.headline.bold())
                .foregroundColor(.primary)

            Chart {
                ForEach(Array(store.sessions.enumerated()), id: \.offset) { index, session in
                    BarMark(
                        x: .value("Game", index + 1),
                        y: .value("Score", session.score)
                    )
                    .foregroundStyle(session.mode.accentColor)
                    .cornerRadius(4)
                }
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.secondary)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine()
                        .foregroundStyle(Color(UIColor.separator))
                    AxisValueLabel()
                        .foregroundStyle(Color.secondary)
                }
            }

            // Legend
            HStack(spacing: 16) {
                ForEach(GameMode.allCases, id: \.self) { mode in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(mode.accentColor)
                            .frame(width: 8, height: 8)
                        Text(mode.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Recent games

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Games")
                .font(.headline.bold())
                .foregroundColor(.primary)

            ForEach(store.sessions.suffix(10).reversed()) { session in
                HStack(spacing: 12) {
                    Image(systemName: session.mode.icon)
                        .foregroundColor(session.mode.accentColor)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.mode.rawValue)
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)
                        Text(session.timestamp, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("\(session.score)")
                        .font(.title3.bold())
                        .foregroundColor(session.mode.accentColor)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NavigationStack { StatsView() }
        .environment(SessionStore())
}
