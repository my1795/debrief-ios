//
//  DateCalculator.swift
//  debrief
//
//  Created for Production Refactoring
//

import Foundation

/// Centralized date calculations for consistent week/day boundaries.
/// Uses Sunday as first day of week (stats week definition).
struct DateCalculator {
    
    // MARK: - Week Bounds (Stats Week: Sunday to Sunday)
    
    /// Returns start and end of the stats week containing the given date
    /// Week starts on Sunday 00:00:00 and ends on next Sunday 00:00:00
    static func statsWeekBounds(for date: Date) -> (start: Date, end: Date) {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Sunday
        
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let weekStart = calendar.date(from: components) ?? date
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? date
        
        return (weekStart, weekEnd)
    }
    
    // MARK: - Day Bounds
    
    /// Returns start (00:00:00) and end (next day 00:00:00) of the given date
    static func dayBounds(for date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        return (startOfDay, endOfDay)
    }
    
    // MARK: - Section Titles
    
    private static let sectionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter
    }()
    
    /// Returns relative title for grouping (Today, Yesterday, or formatted date)
    static func relativeSectionTitle(for date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return sectionDateFormatter.string(from: date)
        }
    }
    
    // MARK: - Timestamp Conversions (Firestore uses milliseconds)
    
    static func toMilliseconds(_ date: Date) -> Int64 {
        return Int64(date.timeIntervalSince1970 * 1000)
    }
    
    static func fromMilliseconds(_ ms: Int64) -> Date {
        return Date(timeIntervalSince1970: TimeInterval(ms) / 1000)
    }
}
