//
//  sample1App.swift
//  sample1
//
//  Created by Pasindu Eranga on 2026-06-10.
//

import SwiftUI
internal import CoreData

@main
struct sample1App: App {
    let persistence = PersistenceController.shared
    @State private var sessionStore = SessionStore()
    @State private var locationService = LocationService()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(sessionStore)
                .environment(locationService)
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .onAppear { locationService.requestPermission() }
        }
    }
}
