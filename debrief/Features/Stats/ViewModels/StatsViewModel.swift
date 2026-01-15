//
//  StatsViewModel.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 14/01/2026.
//

import Foundation
import SwiftUI
import Combine


struct StatsDisplayData: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let subValue: String? // trend
    let isPositive: Bool? // for trend color
    let icon: String // SF Symbol
}

@MainActor
class StatsViewModel: ObservableObject {
    @Published var stats: [StatsDisplayData] = []
    @Published var overview: StatsOverview = .empty
    @Published var trends: StatsTrends = .empty // Started with empty as requested
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
        print("📊 [StatsViewModel] Starting loadData...") // LOGGING
        
        await loadWidgetData()
        await loadLegacyOverviewData()
        
        isLoading = false
    }
    
    private func loadWidgetData() async {
        do {
            let (thisWeekStart, thisWeekEnd) = weekBounds(for: Date())
            let prevWeekStart = Calendar.current.date(byAdding: .day, value: -7, to: thisWeekStart)!
            let prevWeekEnd = Calendar.current.date(byAdding: .day, value: -7, to: thisWeekEnd)!
            
            async let thisWeekDebriefs = statsService.getDebriefsCount(start: thisWeekStart, end: thisWeekEnd)
            async let prevWeekDebriefs = statsService.getDebriefsCount(start: prevWeekStart, end: prevWeekEnd)
            
            async let thisWeekCalls = statsService.getCallsCount(start: thisWeekStart, end: thisWeekEnd)
            async let prevWeekCalls = statsService.getCallsCount(start: prevWeekStart, end: prevWeekEnd)
            
            let (debCurr, debPrev, callCurr, callPrev) = try await (thisWeekDebriefs, prevWeekDebriefs, thisWeekCalls, prevWeekCalls)
            
            // Calculate trends
            let debriefTrend = calculateTrend(current: Double(debCurr), previous: Double(debPrev))
            let callTrend = calculateTrend(current: Double(callCurr), previous: Double(callPrev))
            
            let completionRate = callCurr > 0 ? Int((Double(debCurr) / Double(callCurr)) * 100) : 0
            let prevCompletionRate = callPrev > 0 ? Int((Double(debPrev) / Double(callPrev)) * 100) : 0
            let rateTrend = calculateTrend(current: Double(completionRate), previous: Double(prevCompletionRate))
            
            let estMinutes = debCurr * 3
            let prevEstMinutes = debPrev * 3
            let minTrend = calculateTrend(current: Double(estMinutes), previous: Double(prevEstMinutes))
            
            self.stats = [
                StatsDisplayData(title: "Debriefs", value: "\(debCurr)", subValue: debriefTrend, isPositive: isPositive(debCurr, debPrev), icon: "doc.text.fill"),
                StatsDisplayData(title: "Calls", value: "\(callCurr)", subValue: callTrend, isPositive: isPositive(callCurr, callPrev), icon: "phone.fill"),
                StatsDisplayData(title: "Rate", value: "\(completionRate)%", subValue: rateTrend, isPositive: isPositive(completionRate, prevCompletionRate), icon: "chart.pie.fill"),
                StatsDisplayData(title: "Mins", value: "\(estMinutes)", subValue: minTrend, isPositive: isPositive(estMinutes, prevEstMinutes), icon: "clock.fill")
            ]
            
        } catch {
            print("Widget Stats Error: \(error)")
            // Don't set global error here to allow other parts to load if partial failure
        }
    }
    
    private func loadLegacyOverviewData() async {
        do {
            let response = try await statsService.getOverview()
            
            // Map API response to UI Model
            let stats = response.allTimeStats
            self.overview = StatsOverview(
                totalDebriefs: stats.totalDebriefs,
                totalMinutes: stats.totalMinutes,
                totalActionItems: 0,
                totalContacts: 0,
                avgDebriefDuration: stats.avgMinutesPerDay ?? 0.0,
                completionRate: 0,
                mostActiveDay: "-",
                longestStreak: 0
            )
            
            if let top = stats.topContact, let name = top.name {
                self.topContacts = [
                    TopContactStat(
                        id: top.contactId ?? UUID().uuidString,
                        name: name,
                        company: "",
                        debriefs: top.debriefCount,
                        minutes: top.totalMinutes,
                        percentage: 0
                    )
                ]
            } else {
                self.topContacts = []
            }
            
        } catch {
            print("Legacy Stats Error: \(error)")
            // Fallback to empty if failed, preserve mock if we want but here let's be strict
        }
    }
    
    // MARK: - Helpers
    
    private func weekBounds(for date: Date) -> (start: Date, end: Date) {
        let cal = Calendar(identifier: .iso8601)
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        guard let monday = cal.date(from: components),
              let nextMonday = cal.date(byAdding: .day, value: 7, to: monday) else {
            return (Date(), Date())
        }
        return (monday, nextMonday)
    }
    
    private func calculateTrend(current: Double, previous: Double) -> String? {
        if previous == 0 {
            return current > 0 ? "+100%" : nil
        }
        let change = ((current - previous) / previous) * 100
        return String(format: "%+.0f%%", change)
    }
    
    private func isPositive(_ current: Int, _ previous: Int) -> Bool? {
        if current == previous { return nil }
        return current > previous
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
