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
    var dateOption: DateRangeOption = .all
    
    // Custom Range properties
    var customStartDate: Date = Date()
    var customEndDate: Date = Date()
    
    var isActive: Bool {
        return contactId != nil || dateOption != .all
    }
    
    mutating func clear() {
        contactId = nil
        contactName = nil
        dateOption = .all
        customStartDate = Date()
        customEndDate = Date()
    }
    
    // Computed properties for query consumption
    var startDate: Date? {
        let calendar = Calendar.current
        let now = Date()
        
        switch dateOption {
        case .today:
            return calendar.startOfDay(for: now)
        case .thisWeek: // Last 7 days
            return calendar.date(byAdding: .day, value: -7, to: now)
        case .thisMonth: // Last 30 days
            return calendar.date(byAdding: .day, value: -30, to: now)
        case .custom:
            return calendar.startOfDay(for: customStartDate)
        case .all:
            return nil
        }
    }
    
    var endDate: Date? {
        switch dateOption {
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
