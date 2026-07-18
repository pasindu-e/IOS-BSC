//
//  SettingsView.swift
//  sample1
//

import SwiftUI

struct SettingsView: View {
    @Environment(SessionStore.self) private var store

    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("challengeTimeInterval") private var challengeTimeInterval: Double = 0
    @AppStorage("appearanceMode") private var appearanceMode = "dark"

    @State private var challengeTime: Date = defaultChallengeTime()
    @State private var showResetConfirmation = false
    @State private var permissionDenied = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            Form {
                Section("Appearance") {
                    Picker("Theme", selection: $appearanceMode) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Toggle("Enable Daily Challenge", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, enabled in
                            handleNotificationToggle(enabled)
                        }

                    if notificationsEnabled {
                        DatePicker(
                            "Challenge Time",
                            selection: $challengeTime,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: challengeTime) { _, newTime in
                            challengeTimeInterval = newTime.timeIntervalSinceReferenceDate
                            NotificationService.shared.scheduleDailyChallenge(at: newTime)
                        }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    if permissionDenied {
                        Text("Go to Settings › sample1 to allow notifications.")
                            .foregroundColor(.red)
                    }
                }

                Section("Data") {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("Reset All Stats", systemImage: "trash")
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Modes", value: "3")
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog(
            "Reset all stats?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) { store.clearAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes all game history.")
        }
        .onAppear {
            if challengeTimeInterval != 0 {
                challengeTime = Date(timeIntervalSinceReferenceDate: challengeTimeInterval)
            }
        }
    }

    private func handleNotificationToggle(_ enabled: Bool) {
        if enabled {
            Task {
                let granted = await NotificationService.shared.requestPermission()
                if granted {
                    NotificationService.shared.scheduleDailyChallenge(at: challengeTime)
                    permissionDenied = false
                } else {
                    notificationsEnabled = false
                    permissionDenied = true
                }
            }
        } else {
            NotificationService.shared.cancel()
            permissionDenied = false
        }
    }

    private static func defaultChallengeTime() -> Date {
        Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    }
}

#Preview {
    NavigationStack { SettingsView() }
        .environment(SessionStore())
}
