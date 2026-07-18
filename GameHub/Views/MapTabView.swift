//
//  MapTabView.swift
//  sample1
//

import SwiftUI
import MapKit

struct MapTabView: View {
    @Environment(SessionStore.self) private var store
    @State private var selected: GameSession? = nil

    private var mappableSessions: [GameSession] {
        store.sessions.filter { $0.latitude != 0 || $0.longitude != 0 }
    }

    var body: some View {
        ZStack {
            if mappableSessions.isEmpty {
                Color(.systemBackground).ignoresSafeArea()
                VStack(spacing: 16) {
                    Image(systemName: "map")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No locations recorded yet")
                        .font(.title3.bold())
                        .foregroundColor(.secondary)
                    Text("Complete a game with location access to see pins here.")
                        .font(.subheadline)
                        .foregroundColor(.secondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            } else {
                Map {
                    ForEach(mappableSessions) { session in
                        Annotation(
                            "",
                            coordinate: CLLocationCoordinate2D(
                                latitude: session.latitude,
                                longitude: session.longitude
                            )
                        ) {
                            pinView(for: session)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.35)) {
                                        selected = (selected?.id == session.id) ? nil : session
                                    }
                                }
                        }
                    }
                }
                .ignoresSafeArea(edges: .bottom)
            }

            if let session = selected {
                VStack {
                    Spacer()
                    sessionCard(session)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationTitle("Map")
        .navigationBarTitleDisplayMode(.large)
        .animation(.spring(response: 0.35), value: selected?.id)
    }

    private func pinView(for session: GameSession) -> some View {
        ZStack {
            Circle()
                .fill(session.mode.accentColor)
                .frame(width: 40, height: 40)
                .shadow(color: session.mode.accentColor.opacity(0.5), radius: 6)
            Image(systemName: session.mode.icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
        .scaleEffect(selected?.id == session.id ? 1.2 : 1.0)
    }

    private func sessionCard(_ session: GameSession) -> some View {
        HStack(spacing: 16) {
            Image(systemName: session.mode.icon)
                .font(.title2)
                .foregroundColor(session.mode.accentColor)
            VStack(alignment: .leading, spacing: 4) {
                Text(session.mode.rawValue)
                    .font(.headline.bold())
                    .foregroundColor(.primary)
                Text(session.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("\(session.score)")
                .font(.title.bold())
                .foregroundColor(session.mode.accentColor)
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 8)
    }
}

#Preview {
    NavigationStack { MapTabView() }
        .environment(SessionStore())
}
