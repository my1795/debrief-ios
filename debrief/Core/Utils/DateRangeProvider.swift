//
//  DateRangeProvider.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 20/01/2026.
//

import Foundation

// MARK: - Date Range Provider Protocol

/// Protocol for different week calculation strategies
protocol DateRangeProvider {
    /// Returns the start and end dates for the current week
    func currentWeekRange() -> (start: Date, end: Date)
    
    /// Returns the start and end dates for the current month
    func currentMonthRange() -> (start: Date, end: Date)
    
    /// Display name for UI
    var displayName: String { get }
}

// MARK: - Stats Week Provider (Sunday → Sunday)

/// Calendar-based week: Sunday 00:00 → Saturday 23:59
struct StatsWeekProvider: DateRangeProvider {
    private let calendar: Calendar
    
    init(calendar: Calendar = .current) {
        var cal = calendar
        cal.firstWeekday = 1 // Sunday = 1
        self.calendar = cal
    }
    
    var displayName: String { "Stats Week (Sun-Sun)" }
    
    func currentWeekRange() -> (start: Date, end: Date) {
        let now = Date()
        
        // Find Sunday of current week
        let weekday = calendar.component(.weekday, from: now)
        let daysFromSunday = weekday - 1
        
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysFromSunday, to: now),
              let startOfDay = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: startOfWeek)),
              let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfDay),
              let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endOfWeek)
        else {
            return (now, now)
        }
        
        return (startOfDay, endOfDay)
    }
    
    func currentMonthRange() -> (start: Date, end: Date) {
        let now = Date()
        
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth),
              let endOfMonth = calendar.date(byAdding: .second, value: -1, to: nextMonth)
        else {
            return (now, now)
        }
        
        return (startOfMonth, endOfMonth)
    }
}

// MARK: - Billing Week Provider (Registration + 7 days)

/// Rolling week based on user registration date
struct BillingWeekProvider: DateRangeProvider {
    let registrationDate: Date
    private let calendar: Calendar
    
    init(registrationDate: Date, calendar: Calendar = .current) {
        self.registrationDate = registrationDate
        self.calendar = calendar
    }
    
    var displayName: String { "Billing Week" }
    
    func currentWeekRange() -> (start: Date, end: Date) {
        let now = Date()
        
        // Calculate how many complete weeks since registration
        let daysSinceRegistration = calendar.dateComponents([.day], from: registrationDate, to: now).day ?? 0
        let completeWeeks = daysSinceRegistration / 7
        
        // Current billing week start
        guard let currentBillingStart = calendar.date(byAdding: .day, value: completeWeeks * 7, to: registrationDate),
              let startOfDay = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: currentBillingStart)),
              let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfDay),
              let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endOfWeek)
        else {
            return (now, now)
        }
        
        return (startOfDay, endOfDay)
    }
    
    func currentMonthRange() -> (start: Date, end: Date) {
        let now = Date()
        
        // Calculate how many complete months (30-day periods) since registration
        let daysSinceRegistration = calendar.dateComponents([.day], from: registrationDate, to: now).day ?? 0
        let completeMonths = daysSinceRegistration / 30
        
        guard let currentBillingStart = calendar.date(byAdding: .day, value: completeMonths * 30, to: registrationDate),
              let startOfDay = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: currentBillingStart)),
              let endOfMonth = calendar.date(byAdding: .day, value: 29, to: startOfDay),
              let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endOfMonth)
        else {
            return (now, now)
        }
        
        return (startOfDay, endOfDay)
    }
}

// MARK: - Convenience Extensions

extension DateRangeProvider {
    /// Check if a date falls within the current week
    func isInCurrentWeek(_ date: Date) -> Bool {
        let range = currentWeekRange()
        return date >= range.start && date <= range.end
    }
    
    /// Check if a date falls within the current month
    func isInCurrentMonth(_ date: Date) -> Bool {
        let range = currentMonthRange()
        return date >= range.start && date <= range.end
    }
}
