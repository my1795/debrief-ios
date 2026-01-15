//
//  NotificationService.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 15/01/2026.
//

import UserNotifications

class NotificationService {
    static let shared = NotificationService()
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("🔔 [NotificationService] Permission granted")
            } else if let error = error {
                print("❌ [NotificationService] Permission denied: \(error)")
            }
        }
    }
    
    func scheduleDebriefPrompt() {
        let content = UNMutableNotificationContent()
        content.title = "Call Ended"
        content.body = "Would you like to record a debrief for this call?"
        content.sound = .default
        
        // Trigger immediately (time interval 1s)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ [NotificationService] Failed to schedule: \(error)")
            } else {
                print("🔔 [NotificationService] Prompt scheduled")
            }
        }
    }
}
