//
//  ReminderService.swift
//  debrief
//
//  Apple Reminders Integration using EventKit
//

import Foundation
import EventKit

/// Service for creating reminders in Apple Reminders app
final class ReminderService {
    static let shared = ReminderService()
    
    private let eventStore = EKEventStore()
    
    private init() {}
    
    // MARK: - Authorization
    
    /// Request access to Reminders
    func requestAccess() async -> Bool {
        do {
            if #available(iOS 17.0, *) {
                return try await eventStore.requestFullAccessToReminders()
            } else {
                return try await eventStore.requestAccess(to: .reminder)
            }
        } catch {
            Logger.error("Failed to request access: \(error)")
            return false
        }
    }
    
    /// Check current authorization status
    var authorizationStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .reminder)
    }
    
    var isAuthorized: Bool {
        let status = authorizationStatus
        if #available(iOS 17.0, *) {
            return status == .fullAccess
        } else {
            return status == .authorized
        }
    }
    
    // MARK: - Create Reminders
    
    /// Create a single reminder
    /// - Parameters:
    ///   - title: Reminder title (action item text)
    ///   - dueDate: Optional due date
    ///   - notes: Optional notes (e.g., "From Debrief with John")
    /// - Returns: True if created successfully
    @discardableResult
    func createReminder(title: String, dueDate: Date?, notes: String? = nil) async -> Bool {
        if !isAuthorized {
            let granted = await requestAccess()
            if !granted {
                Logger.warning("Reminder access not granted")
                return false
            }
        }
        
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.notes = notes
        reminder.calendar = eventStore.defaultCalendarForNewReminders()
        
        // Set due date with alarm
        if let dueDate = dueDate {
            let dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: dueDate
            )
            reminder.dueDateComponents = dueDateComponents
            
            // Add alarm at due time
            let alarm = EKAlarm(absoluteDate: dueDate)
            reminder.addAlarm(alarm)
        }
        
        do {
            try eventStore.save(reminder, commit: true)
            Logger.success("Created reminder: \(title)")
            return true
        } catch {
            Logger.error("Failed to save reminder: \(error)")
            return false
        }
    }
    
    /// Create multiple reminders at once
    /// - Parameters:
    ///   - items: Array of action item texts
    ///   - dueDate: Shared due date for all items
    ///   - contactName: Contact name for notes context
    /// - Returns: Number of successfully created reminders
    func createReminders(items: [String], dueDate: Date?, contactName: String) async -> Int {
        if !isAuthorized {
            let granted = await requestAccess()
            if !granted { return 0 }
        }
        
        var successCount = 0
        let notes = "From Debrief with \(contactName)"
        
        for item in items {
            let success = await createReminder(title: item, dueDate: dueDate, notes: notes)
            if success { successCount += 1 }
        }
        
        Logger.success("Created \(successCount)/\(items.count) reminders")
        return successCount
    }
}
