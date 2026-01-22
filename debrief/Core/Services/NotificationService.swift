//
//  NotificationService.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 15/01/2026.
//

import UserNotifications
import Foundation

class NotificationService {
    static let shared = NotificationService()

    // Key for user preference (matches SettingsViewModel)
    private let notificationsEnabledKey = "notificationsEnabled"

    /// Check if user has enabled notifications in app settings
    var isNotificationsEnabled: Bool {
        // Default to true if not set
        if UserDefaults.standard.object(forKey: notificationsEnabledKey) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: notificationsEnabledKey)
    }

    /// Set notification preference
    func setNotificationsEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: notificationsEnabledKey)
        Logger.info("Notifications \(enabled ? "enabled" : "disabled")")
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                Logger.info("Notification permission granted")
            } else if let error = error {
                Logger.error("Notification permission denied: \(error)")
            }
        }
    }

    func scheduleDebriefPrompt() {
        // Check user preference first
        guard isNotificationsEnabled else {
            Logger.info("Notifications disabled by user, skipping")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Call Ended"
        content.body = "Would you like to record a debrief for this call?"
        content.sound = .default

        // Trigger immediately (time interval 1s)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.error("Failed to schedule notification: \(error)")
            } else {
                Logger.info("Notification prompt scheduled")
            }
        }
    }
}
