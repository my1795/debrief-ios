//
//  DebriefFilters.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 17/01/2026.
//

import Foundation

struct DebriefFilters: Equatable {
    var contactId: String?
    var contactName: String?
    var hasActionItems: Bool = false
    var dateOption: DateRangeOption = .all
    
    // Custom Range properties
    var customStartDate: Date = Date()
    var customEndDate: Date = Date()
    
    // Status filter (nil = all statuses)
    var status: DebriefStatus? = nil
    
    // Pagination (used internally by service, not for UI comparison)
    // Note: Excluded from Equatable to prevent pagination changes triggering reload
    var limit: Int? = nil
    
    static func == (lhs: DebriefFilters, rhs: DebriefFilters) -> Bool {
        lhs.contactId == rhs.contactId &&
        lhs.contactName == rhs.contactName &&
        lhs.hasActionItems == rhs.hasActionItems &&
        lhs.dateOption == rhs.dateOption &&
        lhs.customStartDate == rhs.customStartDate &&
        lhs.customEndDate == rhs.customEndDate &&
        lhs.status == rhs.status
    }
    
    var isActive: Bool {
        return contactId != nil || dateOption != .all || hasActionItems || status != nil
    }

    mutating func clear() {
        contactId = nil
        contactName = nil
        hasActionItems = false
        dateOption = .all
        customStartDate = Date()
        customEndDate = Date()
        status = nil
    }
    
    // Use StatsWeekProvider for consistent Sunday-Sunday week bounds
    private static let statsWeekProvider = StatsWeekProvider()

    // Computed properties for query consumption
    var startDate: Date? {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Sunday
        let now = Date()

        switch dateOption {
        case .today:
            return calendar.startOfDay(for: now)
        case .thisWeek: // Current Stats Week (Sunday to Sunday)
            // Use StatsWeekProvider for consistent week bounds across the app
            let (start, _) = Self.statsWeekProvider.currentWeekRange()
            return start
        case .thisMonth: // Current Month
            let components = calendar.dateComponents([.year, .month], from: now)
            return calendar.date(from: components)
        case .custom:
            return calendar.startOfDay(for: customStartDate)
        case .all:
            return nil
        }
    }

    var endDate: Date? {
        switch dateOption {
        case .thisWeek:
            // Use StatsWeekProvider for consistent week bounds
            let (_, end) = Self.statsWeekProvider.currentWeekRange()
            return end
        case .custom:
            // End of the selected end date
            let calendar = Calendar.current
            let nextDay = calendar.date(byAdding: .day, value: 1, to: customEndDate) ?? Date()
            return calendar.startOfDay(for: nextDay)
        default:
            return nil
        }
    }
}

enum DateRangeOption: String, Equatable, CaseIterable {
    case all
    case today
    case thisWeek
    case thisMonth
    case custom
    
    var displayName: String {
        switch self {
        case .all: return "All Time"
        case .today: return "Today"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .custom: return "Custom Range"
        }
    }
}
