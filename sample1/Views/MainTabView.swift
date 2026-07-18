//
//  MainTabView.swift
//  sample1
//

import SwiftUI
internal import CoreData

struct MainTabView: View {
    @AppStorage("appearanceMode") private var appearanceMode = "dark"

    private var preferredScheme: ColorScheme? {
        switch appearanceMode {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("Home", systemImage: "gamecontroller") }

            NavigationStack { StatsView() }
                .tabItem { Label("Stats", systemImage: "chart.bar") }

            NavigationStack { MapTabView() }
                .tabItem { Label("Map", systemImage: "map") }

            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .tint(.purple)
        .preferredColorScheme(preferredScheme)
    }
}

#Preview {
    MainTabView()
        .environment(SessionStore())
        .environment(LocationService())
        .environment(\.managedObjectContext,
                     PersistenceController.shared.container.viewContext)
}
