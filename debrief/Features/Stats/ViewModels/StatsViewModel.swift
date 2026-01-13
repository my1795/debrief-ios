//
//  StatsViewModel.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 14/01/2026.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class StatsViewModel: ObservableObject {
    @Published var overview: StatsOverview = .empty
    @Published var trends: StatsTrends = .mock // Keep Trends mock as requested (calculating client-side is too heavy)
    @Published var quota: StatsQuota = .mock // Keep Quota mock for now
    @Published var topContacts: [TopContactStat] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Recent Activity Chart Data (Keeping mock for now as API doesn't return history yet)
    @Published var recentActivity: [UsageEvent] = [
        UsageEvent(id: "1", date: Date().addingTimeInterval(-6*86400), count: 3),
        UsageEvent(id: "2", date: Date().addingTimeInterval(-5*86400), count: 5),
        UsageEvent(id: "3", date: Date().addingTimeInterval(-4*86400), count: 2),
        UsageEvent(id: "4", date: Date().addingTimeInterval(-3*86400), count: 0),
        UsageEvent(id: "5", date: Date().addingTimeInterval(-2*86400), count: 1),
        UsageEvent(id: "6", date: Date().addingTimeInterval(-86400), count: 4),
        UsageEvent(id: "7", date: Date(), count: 2)
    ]
    
    private let statsService: StatsServiceProtocol
    
    init(statsService: StatsServiceProtocol = StatsService()) {
        self.statsService = statsService
    }
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        print("DEBUG STATS: Starting to load data...")
        
        do {
            let response = try await statsService.getOverview()
            print("DEBUG STATS: Received response: \(response)")
            
            // Map API response to UI Model
            let stats = response.allTimeStats
            self.overview = StatsOverview(
                totalDebriefs: stats.totalDebriefs,
                totalMinutes: stats.totalMinutes,
                totalActionItems: 0, // Not in API yet
                totalContacts: 0,    // Not in API yet
                avgDebriefDuration: stats.avgMinutesPerDay ?? 0.0,
                completionRate: 0,   // Not in API
                mostActiveDay: "-",  // Not in API
                longestStreak: 0     // Not in API
            )
            
            // Handle Top Contact
            if let top = stats.topContact, let name = top.name {
                self.topContacts = [
                    TopContactStat(
                        id: top.contactId ?? UUID().uuidString,
                        name: name,
                        company: "", // Not in API
                        debriefs: top.debriefCount,
                        minutes: top.totalMinutes,
                        percentage: 0 // Need total to calculate
                    )
                ]
            } else {
                self.topContacts = []
            }
            
        } catch {
            print("DEBUG STATS: Load ERROR: \(error)")
            self.errorMessage = "Failed to load stats"
            // Reset to empty on error so we don't show stale/wrong data
            self.overview = .empty
        }
        
        isLoading = false
    }
    
    // Computed Properties for Quota Percentages
    var recordingsQuotaPercent: Double {
        guard quota.recordingsLimit > 0 else { return 0 }
        return Double(quota.recordingsThisMonth) / Double(quota.recordingsLimit)
    }
    
    var minutesQuotaPercent: Double {
        guard quota.minutesLimit > 0 else { return 0 }
        return Double(quota.minutesThisMonth) / Double(quota.minutesLimit)
    }
    
    var storageQuotaPercent: Double {
        guard quota.storageLimitMB > 0 else { return 0 }
        return Double(quota.storageUsedMB) / Double(quota.storageLimitMB)
    }
}
