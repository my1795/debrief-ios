//
//  StatsModels.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 14/01/2026.
//

import Foundation

// MARK: - Domain Models

// MARK: - API Response Models

struct CallCountResponse: Codable {
    let count: Int
}

struct DebriefCountResponse: Codable {
    let count: Int
}

struct OverviewResponse: Decodable {
    let allTimeStats: AllTimeStats
    // Note: API returns top-level object wrapper.
}

struct AllTimeStats: Decodable {
    let totalDebriefs: Int
    let totalMinutes: Int
    let totalWords: Int
    let avgMinutesPerDay: Double?
    let topContact: TopContactInfo?
}

struct TopContactInfo: Decodable {
    let contactId: String? // Nullable in schema?
    let name: String?
    let debriefCount: Int
    let totalMinutes: Int
}

// MARK: - Domain Models (Mapped from API)

struct StatsOverview {
    let totalDebriefs: Int
    let totalMinutes: Int
    let totalActionItems: Int // Not in OverviewResponse, might need separate call or mock for now
    let totalContacts: Int    // Not in OverviewResponse
    let avgDebriefDuration: Double
    let mostActiveDay: String
    let longestStreak: Int
}

struct StatsTrends {
    // API "TrendComparison" schema exists but is it in OverviewResponse?
    // OverviewResponse doesn't show it. We might need to fetch separate trends or calculate.
    // For now, keeping placeholders that will use 0 if not available.
    let debriefsChangePercent: Double
    let minutesChangePercent: Double
    let actionItemsChangePercent: Double
}

struct StatsQuota {
    // Not found in OverviewResponse. Will keep as Mock/Placeholder until Quota API is defined.
    let tier: String
    let recordingsThisMonth: Int
    let recordingsLimit: Int
    let minutesThisMonth: Int
    let minutesLimit: Int
    let storageUsedMB: Int
    let storageLimitMB: Int
}

struct TopContactStat: Identifiable {
    let id: String
    let name: String
    let company: String
    let debriefs: Int
    let minutes: Int
    let percentage: Double
}

struct UsageEvent: Identifiable {
    let id: String
    let date: Date
    let count: Int
}

// MARK: - Weekly Stats Aggregation

struct WeeklyStats {
    let count: Int           // Number of debriefs
    let duration: Int        // Total duration in seconds
    let actionItems: Int     // Total action items
    let uniqueContacts: Int  // Unique contacts count
}

// MARK: - Mock Data

extension StatsOverview {
    static let empty = StatsOverview(
        totalDebriefs: 0,
        totalMinutes: 0,
        totalActionItems: 0,
        totalContacts: 0,
        avgDebriefDuration: 0,
        mostActiveDay: "-",
        longestStreak: 0
    )
}

extension StatsTrends {
    static let mock = StatsTrends(
        debriefsChangePercent: -20.0,
        minutesChangePercent: 5.6,
        actionItemsChangePercent: 21.4
    )
    
    static let empty = StatsTrends(
        debriefsChangePercent: 0,
        minutesChangePercent: 0,
        actionItemsChangePercent: 0
    )
}

extension StatsQuota {
    static let mock = StatsQuota(
        tier: "Free",
        recordingsThisMonth: 8,
        recordingsLimit: 10,
        minutesThisMonth: 42,
        minutesLimit: 100,
        storageUsedMB: 125,
        storageLimitMB: 500
    )
}

extension TopContactStat {
    static let mocks: [TopContactStat] = [
        TopContactStat(id: "1", name: "John Doe", company: "Acme Corp", debriefs: 24, minutes: 142, percentage: 35),
        TopContactStat(id: "2", name: "Jane Smith", company: "Tech Inc", debriefs: 18, minutes: 98, percentage: 25),
        TopContactStat(id: "3", name: "Bob Wilson", company: "StartupXYZ", debriefs: 15, minutes: 87, percentage: 20)
    ]
}
