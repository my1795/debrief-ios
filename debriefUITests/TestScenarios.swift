//
//  TestScenarios.swift
//  debriefUITests
//
//  Created by Mustafa Yildirim on 21/01/2026.
//

import Foundation

/// Test scenarios that can be loaded via launch arguments
/// The app should check for these and seed appropriate mock data
enum TestScenario: String {
    // MARK: - User States

    /// New user with no debriefs, contacts, or usage
    case emptyUser = "EMPTY_USER"

    /// User with a few debriefs (5-10) and contacts
    case basicUser = "BASIC_USER"

    /// Power user with many debriefs (50+), extensive history
    case powerUser = "POWER_USER"

    /// User approaching quota limits (>80% usage)
    case nearQuotaLimit = "NEAR_QUOTA_LIMIT"

    /// User who has exceeded quota
    case quotaExceeded = "QUOTA_EXCEEDED"

    /// User with PRO subscription (unlimited)
    case proUser = "PRO_USER"

    /// User with PERSONAL subscription
    case personalUser = "PERSONAL_USER"

    // MARK: - Debrief States

    /// Has debriefs in various processing states
    case mixedDebriefStates = "MIXED_DEBRIEF_STATES"

    /// Has debrief currently processing
    case processingDebrief = "PROCESSING_DEBRIEF"

    /// Has failed debrief requiring retry
    case failedDebrief = "FAILED_DEBRIEF"

    // MARK: - Contact States

    /// Has many contacts (100+) for scroll testing
    case manyContacts = "MANY_CONTACTS"

    /// Has no device contacts (permission granted but empty)
    case noContacts = "NO_CONTACTS"

    /// Contact permission denied
    case contactPermissionDenied = "CONTACT_PERMISSION_DENIED"

    // MARK: - Edge Cases

    /// Offline mode (no network)
    case offlineMode = "OFFLINE_MODE"

    /// Slow network (simulate delays)
    case slowNetwork = "SLOW_NETWORK"

    /// Network errors
    case networkError = "NETWORK_ERROR"

    // MARK: - Stats Scenarios

    /// User with calculated stats (mostActiveDay, streak)
    case withCalculatedStats = "WITH_CALCULATED_STATS"

    /// User with top contacts ranking
    case withTopContacts = "WITH_TOP_CONTACTS"

    /// User with activity across multiple days for streak testing
    case streakScenario = "STREAK_SCENARIO"
}

/// Mock data configuration for Firebase Emulator
struct MockDataConfig {
    let scenario: TestScenario

    var debriefCount: Int {
        switch scenario {
        case .emptyUser: return 0
        case .basicUser: return 8
        case .powerUser: return 75
        case .nearQuotaLimit: return 45
        case .quotaExceeded: return 51
        default: return 10
        }
    }

    var usedMinutes: Int {
        switch scenario {
        case .emptyUser: return 0
        case .basicUser: return 15
        case .powerUser: return 120
        case .nearQuotaLimit: return 27
        case .quotaExceeded: return 35
        default: return 20
        }
    }

    var tier: String {
        switch scenario {
        case .proUser: return "PRO"
        case .personalUser: return "PERSONAL"
        default: return "FREE"
        }
    }

    var storageUsedMB: Int {
        switch scenario {
        case .nearQuotaLimit: return 450
        case .quotaExceeded: return 510
        default: return 125
        }
    }

    var contactCount: Int {
        switch scenario {
        case .noContacts: return 0
        case .manyContacts: return 150
        default: return 25
        }
    }
}

// MARK: - Emulator Seeding Script JSON

struct EmulatorSeedData: Codable {
    let userId: String
    let userPlan: UserPlanSeed
    let debriefs: [DebriefSeed]
    let contacts: [ContactSeed]
}

struct UserPlanSeed: Codable {
    let tier: String
    let billingWeekStart: Int64
    let billingWeekEnd: Int64
    let weeklyUsage: WeeklyUsageSeed
    let usedStorageMB: Int
}

struct WeeklyUsageSeed: Codable {
    let debriefCount: Int
    let totalSeconds: Int
    let actionItemsCount: Int
    let uniqueContactIds: [String]
}

struct DebriefSeed: Codable {
    let id: String
    let contactId: String
    let contactName: String
    let state: String
    let duration: Int
    let summary: String?
    let transcript: String?
    let actionItems: [String]
    let createdAt: Int64
}

struct ContactSeed: Codable {
    let id: String
    let name: String
    let handle: String?
    let company: String?
}
