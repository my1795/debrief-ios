//
//  DebriefFilters.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 17/01/2026.
//

import Foundation

struct DebriefFilters: Equatable {
    var contactId: String?
    var contactName: String? // Store name for display in chips/UI
    var dateRange: DateRange?
    
    var isActive: Bool {
        return contactId != nil || (dateRange != nil && dateRange != .all)
    }
    
    mutating func clear() {
        contactId = nil
        contactName = nil
        dateRange = nil
    }
}

enum DateRange: Equatable, CaseIterable {
    case today
    case thisWeek
    case thisMonth
    case all
    // Custom range can be added here if needed in future phases
    // case custom(start: Date, end: Date)
    
    var displayName: String {
        switch self {
        case .today: return "Today"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .all: return "All Time"
        }
    }
    
    // Helper to get start date for query
    var startDate: Date? {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .today:
            return calendar.startOfDay(for: now)
        case .thisWeek:
            // Last 7 days
            return calendar.date(byAdding: .day, value: -7, to: now)
        case .thisMonth:
             // Last 30 days
            return calendar.date(byAdding: .day, value: -30, to: now)
        case .all:
            return nil
        }
    }
}
