//
//  StatsModels.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 14/01/2026.
//

import Foundation

// MARK: - Domain Models

struct StatsOverview {
    let totalDebriefs: Int
    let totalMinutes: Int
    let totalActionItems: Int
    let totalContacts: Int
    let avgDebriefDuration: Double
    let completionRate: Int
    let mostActiveDay: String
    let longestStreak: Int
}

struct StatsTrends {
    let debriefsChangePercent: Double
    let minutesChangePercent: Double
    let actionItemsChangePercent: Double
}

struct StatsQuota {
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

// MARK: - Mock Data

extension StatsOverview {
    static let mock = StatsOverview(
        totalDebriefs: 156,
        totalMinutes: 892,
        totalActionItems: 234,
        totalContacts: 12,
        avgDebriefDuration: 5.7,
        completionRate: 87,
        mostActiveDay: "Monday",
        longestStreak: 7
    )
}

extension StatsTrends {
    static let mock = StatsTrends(
        debriefsChangePercent: -20.0,
        minutesChangePercent: 5.6,
        actionItemsChangePercent: 21.4
    )
}

extension StatsQuota {
    static let mock = StatsQuota(
        tier: "Pro",
        recordingsThisMonth: 42,
        recordingsLimit: 100,
        minutesThisMonth: 245,
        minutesLimit: 500,
        storageUsedMB: 1250,
        storageLimitMB: 5000
    )
}

extension TopContactStat {
    static let mocks: [TopContactStat] = [
        TopContactStat(id: "1", name: "John Doe", company: "Acme Corp", debriefs: 24, minutes: 142, percentage: 35),
        TopContactStat(id: "2", name: "Jane Smith", company: "Tech Inc", debriefs: 18, minutes: 98, percentage: 25),
        TopContactStat(id: "3", name: "Bob Wilson", company: "StartupXYZ", debriefs: 15, minutes: 87, percentage: 20)
    ]
}
