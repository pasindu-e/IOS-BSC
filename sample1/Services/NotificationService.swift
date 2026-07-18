//
//  NotificationService.swift
//  sample1
//

import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])) ?? false
    }

    func scheduleDailyChallenge(at time: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily.challenge"])

        let content = UNMutableNotificationContent()
        content.title = "Daily Challenge"
        content.body = "Your daily challenge is ready — can you beat your best score?"
        content.sound = .default

        var comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        comps.second = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        center.add(UNNotificationRequest(identifier: "daily.challenge",
                                         content: content,
                                         trigger: trigger))
    }

    func cancel() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["daily.challenge"])
    }
}
