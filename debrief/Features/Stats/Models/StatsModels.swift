//
//  StatsModels.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 14/01/2026.
//

import Foundation
import FirebaseFirestore

// MARK: - Domain Models

// MARK: - API Response Models

struct UserQuota: Codable {
    let userId: String
    let subscriptionTier: String // "FREE", "PERSONAL", "PRO"
    
    // Limits
    let weeklyDebriefs: Int
    let weeklyRecordingMinutes: Int
    let storageLimitMB: Int
    
    // Usage
    let usedDebriefs: Int
    let usedRecordingSeconds: Int
    let usedStorageMB: Int
    
    // Period
    // Backend sends timestamps as Int64 milliseconds (e.g. 1767225600000)
    let currentPeriodStart: Int64?
    let currentPeriodEnd: Int64?
    
    // Helper to handle optional/missing fields safely if needed (though Codable requires them if not nullable)
    // Assuming backend ALWAYS sends these. If not, we should use Optionals with defaults.
    // Based on contract, they seem required.
}

extension UserQuota {
    var usedRecordingMinutes: Int {
        // Round up: 1 sec usage = 1 min quota used
        Int(ceil(Double(usedRecordingSeconds) / 60.0))
    }
    
    var periodStartDate: Date? {
        guard let ms = currentPeriodStart else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(ms) / 1000)
    }
    
    var periodEndDate: Date? {
        guard let ms = currentPeriodEnd else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(ms) / 1000)
    }
    
    var isUnlimitedDebriefs: Bool { weeklyDebriefs == Int.max }
    var isUnlimitedMinutes: Bool { weeklyRecordingMinutes == Int.max }
    var isUnlimitedStorage: Bool { storageLimitMB == Int.max }
}

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

struct TopContactStat: Identifiable, Codable {
    let id: String
    let name: String
    let company: String
    let debriefs: Int
    let minutes: Int
    let percentage: Double
}

struct TopContactsCache: Codable {
    let timestamp: Date
    let weekStart: Date
    let stats: [TopContactStat]
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
    static let empty = StatsQuota(
        tier: "-",
        recordingsThisMonth: 0,
        recordingsLimit: 10,
        minutesThisMonth: 0,
        minutesLimit: 100,
        storageUsedMB: 0,
        storageLimitMB: 500
    )

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

// MARK: - NEW v2 Billing System
//
// READ STRATEGY: Use Firestore snapshots directly (no backend API calls for reads)
// - user_plans collection → Billing/quota info via FirestoreService.observeUserPlan()
// - debriefs collection → Stats aggregation via FirestoreService.getWeeklyStats()
//
// This reduces backend load and enables real-time updates via Firestore listeners.

// MARK: - Firestore Document Model (user_plans collection)

struct UserPlan: Codable {
    @DocumentID var planId: String? // Document ID (same as userId)
    let userId: String
    let tier: String               // FREE, PERSONAL, PRO
    let billingWeekStart: Int64
    let billingWeekEnd: Int64
    let weeklyUsage: UserPlanWeeklyUsage
    let usedStorageMB: Int
    let subscriptionEnd: Int64?
    let createdAt: Int64
    let updatedAt: Int64
}

struct UserPlanWeeklyUsage: Codable {
    let debriefCount: Int
    let totalSeconds: Int
    let actionItemsCount: Int?      // NEW: Total action items this billing week
    let uniqueContactIds: [String]? // NEW: Unique contact IDs this billing week

    // Computed property for unique contacts count
    var uniqueContactsCount: Int {
        uniqueContactIds?.count ?? 0
    }

    // Safe accessors with defaults
    var safeActionItemsCount: Int {
        actionItemsCount ?? 0
    }
}

extension UserPlan {
    var billingWeekStartDate: Date {
        Date(timeIntervalSince1970: TimeInterval(billingWeekStart) / 1000)
    }

    var billingWeekEndDate: Date {
        Date(timeIntervalSince1970: TimeInterval(billingWeekEnd) / 1000)
    }

    var usedMinutes: Int {
        Int(ceil(Double(weeklyUsage.totalSeconds) / 60.0))
    }

    // NEW: Direct access to weekly stats from user_plans (no debrief fetch needed)
    var weeklyActionItemsCount: Int {
        weeklyUsage.safeActionItemsCount
    }

    var weeklyUniqueContactsCount: Int {
        weeklyUsage.uniqueContactsCount
    }

    // Tier-based limits (matching BillingConstants.kt)
    var weeklyDebriefLimit: Int {
        switch tier.uppercased() {
        case "FREE": return 50
        case "PERSONAL", "PRO": return Int.max
        default: return 50
        }
    }

    var weeklyMinutesLimit: Int {
        switch tier.uppercased() {
        case "FREE": return 30
        case "PERSONAL": return 150
        case "PRO": return Int.max
        default: return 30
        }
    }

    var storageLimitMB: Int {
        switch tier.uppercased() {
        case "FREE": return 500
        case "PERSONAL", "PRO": return Int.max
        default: return 500
        }
    }

    var isUnlimitedDebriefs: Bool { weeklyDebriefLimit == Int.max }
    var isUnlimitedMinutes: Bool { weeklyMinutesLimit == Int.max }
    var isUnlimitedStorage: Bool { storageLimitMB == Int.max }

    /// Convert to legacy UserQuota for backward compatibility
    func toUserQuota() -> UserQuota {
        UserQuota(
            userId: userId,
            subscriptionTier: tier,
            weeklyDebriefs: weeklyDebriefLimit,
            weeklyRecordingMinutes: weeklyMinutesLimit,
            storageLimitMB: storageLimitMB,
            usedDebriefs: weeklyUsage.debriefCount,
            usedRecordingSeconds: weeklyUsage.totalSeconds,
            usedStorageMB: usedStorageMB,
            currentPeriodStart: billingWeekStart,
            currentPeriodEnd: billingWeekEnd
        )
    }
}

// MARK: - Billing Constants (matching backend BillingConstants.kt)

enum BillingConstants {
    static let maxDebriefDurationSeconds = 600  // 10 minutes
    static let maxAudioFileSizeMB = 100

    enum Tier {
        case free
        case personal
        case pro

        var weeklyDebriefLimit: Int {
            switch self {
            case .free: return 50
            case .personal, .pro: return Int.max
            }
        }

        var weeklyMinutesLimit: Int {
            switch self {
            case .free: return 30
            case .personal: return 150
            case .pro: return Int.max
            }
        }

        var storageLimitMB: Int {
            switch self {
            case .free: return 500
            case .personal, .pro: return Int.max
            }
        }
    }
}
