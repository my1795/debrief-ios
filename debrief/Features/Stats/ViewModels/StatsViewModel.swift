//
//  StatsViewModel.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 14/01/2026.
//

import Foundation
import SwiftUI
import Combine

class StatsViewModel: ObservableObject {
    @Published var overview: StatsOverview = .mock
    @Published var trends: StatsTrends = .mock
    @Published var quota: StatsQuota = .mock
    @Published var topContacts: [TopContactStat] = TopContactStat.mocks
    
    // Recent Activity Chart Data (Mocking specific days for the chart)
    @Published var recentActivity: [UsageEvent] = [
        UsageEvent(id: "1", date: Date().addingTimeInterval(-6*86400), count: 3),
        UsageEvent(id: "2", date: Date().addingTimeInterval(-5*86400), count: 5),
        UsageEvent(id: "3", date: Date().addingTimeInterval(-4*86400), count: 2),
        UsageEvent(id: "4", date: Date().addingTimeInterval(-3*86400), count: 0),
        UsageEvent(id: "5", date: Date().addingTimeInterval(-2*86400), count: 1),
        UsageEvent(id: "6", date: Date().addingTimeInterval(-86400), count: 4),
        UsageEvent(id: "7", date: Date(), count: 2)
    ]
    
    // Computed Properties for Quota Percentages
    var recordingsQuotaPercent: Double {
        Double(quota.recordingsThisMonth) / Double(quota.recordingsLimit)
    }
    
    var minutesQuotaPercent: Double {
        Double(quota.minutesThisMonth) / Double(quota.minutesLimit)
    }
    
    var storageQuotaPercent: Double {
        Double(quota.storageUsedMB) / Double(quota.storageLimitMB)
    }
}
