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
    @Published var quota: StatsQuota = .empty
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
    private var cancellables = Set<AnyCancellable>()
    
    init(statsService: StatsServiceProtocol = StatsService()) {
        self.statsService = statsService
    }
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        print("📊 [StatsViewModel] Starting loadData...") // LOGGING
        
        // Start Real-time Quota Observation
        if let userId = AuthSession.shared.user?.id {
            startObservingQuota(userId: userId)
        }
        
        await loadWidgetData()
        await loadOverviewData()
        
        isLoading = false
    }
    
    private func startObservingQuota(userId: String) {
        FirestoreService.shared.observeQuota(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    print("❌ [StatsViewModel] Quota observation error: \(error)")
                    // Keep existing quota or show error state if needed
                }
            }, receiveValue: { [weak self] newQuota in
                print("⚡️ [StatsViewModel] Received real-time quota update")
                // Map UserQuota (Domain Model) to StatsQuota (View Model) 
                // Currently StatsQuota seems to be a separate struct in StatsModels.
                // We need to map it. Assuming UserQuota properties match mostly.
                // Let's create a mapper or manual map.
                self?.quota = self?.mapToStatsQuota(newQuota) ?? .mock
            })
            .store(in: &cancellables)
    }
    
    // Helper to map Domain UserQuota to View Model StatsQuota
    private func mapToStatsQuota(_ userQuota: UserQuota) -> StatsQuota {
        // Assuming UserQuota has similar fields. If UserQuota definition isn't visible, 
        // I'll infer based on typical naming.
        // Debug Log
        print("🔍 [StatsViewModel] Mapping Quota - Seconds: \(userQuota.usedRecordingSeconds) -> Minutes: \(userQuota.usedRecordingMinutes)")
        
        return StatsQuota(
            tier: userQuota.subscriptionTier,
            recordingsThisMonth: userQuota.usedDebriefs,
            recordingsLimit: userQuota.weeklyDebriefs,
            minutesThisMonth: userQuota.usedRecordingMinutes,
            minutesLimit: userQuota.weeklyRecordingMinutes,
            storageUsedMB: userQuota.usedStorageMB,
            storageLimitMB: userQuota.storageLimitMB
        )
    }
    private func loadWidgetData() async {
        do {
            let (thisWeekStart, thisWeekEnd) = weekBounds(for: Date())
            let prevWeekStart = Calendar.current.date(byAdding: .day, value: -7, to: thisWeekStart)!
            let prevWeekEnd = Calendar.current.date(byAdding: .day, value: -7, to: thisWeekEnd)!
            
            // We need USER ID to fetch data
            // Assuming we can get it from AuthSession or injected. 
            // Since this is a ViewModel, we might need to inject it or fetch from AuthSession singleton if unavoidable.
            // Ideally passing it in loadData is better, but for now lets try to get it from where StatsService gets it?
            // Wait, StatsService doesn't store userId. 
            // Fix: We must access AuthSession.shared or inject it.
            // For now, assuming we can get current user ID. 
            guard let userId = AuthSession.shared.user?.id else { return }

            // Fetch actual documents to allow flexible calculation (Minutes, Unique Contacts)
            // Fetch Consolidated Stats
            async let thisWeekStats = FirestoreService.shared.getWeeklyStats(userId: userId, start: thisWeekStart, end: thisWeekEnd)
            async let prevWeekStats = FirestoreService.shared.getWeeklyStats(userId: userId, start: prevWeekStart, end: prevWeekEnd)
            
            let (curr, prev) = try await (thisWeekStats, prevWeekStats)
            
            // --- 1. Debriefs Count ---
            let debCurr = curr.count
            let debPrev = prev.count
            let debriefTrend = calculateTrend(current: Double(debCurr), previous: Double(debPrev))
            
            // --- 2. Action Items Count ---
            let actionItemsCurr = curr.actionItems
            let actionItemsPrev = prev.actionItems
            let actionItemsTrend = calculateTrend(current: Double(actionItemsCurr), previous: Double(actionItemsPrev))
            
            // --- 3. Unique Contacts ---
            let uniqueContactsCurr = curr.uniqueContacts
            let uniqueContactsPrev = prev.uniqueContacts
            let contactsTrend = calculateTrend(current: Double(uniqueContactsCurr), previous: Double(uniqueContactsPrev))
            
            // --- 4. Total Duration ---
            let totalSecsCurr = curr.duration
            let totalSecsPrev = prev.duration
            let minTrend = calculateTrend(current: Double(totalSecsCurr), previous: Double(totalSecsPrev))
            
            // Formatting: Duration
            let durationValue: String
            if totalSecsCurr < 60 {
                durationValue = "\(totalSecsCurr) sec"
            } else {
                durationValue = "\(Int(ceil(Double(totalSecsCurr) / 60.0))) min"
            }
            
            self.stats = [
                StatsDisplayData(title: "Total Debriefs", value: "\(debCurr)", subValue: debriefTrend, isPositive: isPositive(debCurr, debPrev), icon: "mic.fill"),
                StatsDisplayData(title: "Duration per Week", value: durationValue, subValue: minTrend, isPositive: isPositive(totalSecsCurr, totalSecsPrev), icon: "clock.fill"),
                StatsDisplayData(title: "Action Items", value: "\(actionItemsCurr)", subValue: actionItemsTrend, isPositive: isPositive(actionItemsCurr, actionItemsPrev), icon: "checklist"),
                StatsDisplayData(title: "Active Contacts", value: "\(uniqueContactsCurr)", subValue: contactsTrend, isPositive: isPositive(uniqueContactsCurr, uniqueContactsPrev), icon: "person.2.fill")
            ]
            
        } catch {
            print("Widget Stats Error: \(error)")
        }
    }
    
    private func loadOverviewData() async {
        do {
            print("🔄 [StatsViewModel] Loading overview data...")
            // Fetch ALL debriefs for accurate client-side stats
            // Firestore caching handles efficiency for subsequent loads
            guard let userId = AuthSession.shared.user?.id else {
                 print("⚠️ [StatsViewModel] No User ID found in session")
                 return
            }
            
            // By fetching all, we can calculate everything accurately without strict backend dependency
            let allDebriefs = try await FirestoreService.shared.fetchDebriefs(userId: userId)
            print("✅ [StatsViewModel] Fetched \(allDebriefs.count) debriefs for stats")

            let stats = calculateStats(from: allDebriefs)
            self.overview = stats
            
            // Update Widgets with real data derived from all debriefs if needed, 
            // or keep using Weekly Stats as is (which fetches range separately).
            // For efficiency, we COUDLD reuse `allDebriefs` for widgets too if we filter locally.
            // But let's leave loadWidgetData separate for now to avoid huge refactor risk, 
            // focusing on "Quick Stats" correctness first. 

        } catch {
            print("❌ Overview Stats Error: \(error)")
        }
    }
    
    private func calculateStats(from allDebriefs: [Debrief]) -> StatsOverview {
        if allDebriefs.isEmpty { return .empty }
        
        // Filter for Current Week (Sunday to Sunday)
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // 1 = Sunday
        
        let now = Date()
        // Get start of the current week (Sunday at 00:00)
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        
        let weeklyDebriefs = allDebriefs.filter { $0.occurredAt >= startOfWeek }
        
        // 1. Total Counts (Weekly)
        let totalDebriefs = weeklyDebriefs.count
        let totalSeconds = weeklyDebriefs.reduce(0) { $0 + $1.duration }
        let totalMinutes = Int(totalSeconds / 60)
        let totalActionItems = weeklyDebriefs.reduce(0) { $0 + ($1.actionItems?.count ?? 0) }
        
        // 2. Unique Contacts (Weekly)
        let uniqueContacts = Set(weeklyDebriefs.compactMap { $0.contactId.isEmpty ? nil : $0.contactId }).count
        
        // 3. Average Duration (Weekly)
        let avgSeconds = totalDebriefs > 0 ? totalSeconds / Double(totalDebriefs) : 0.0
        
        // 4. Most Active Day (Weekly - although less meaningful for just 1 week, it shows the active day of THIS week)
        // If user wants general pattern, All-Time is better. But requested "Weekly" to avoid huge processing.
        // Let's stick to Weekly as requested to avoid all-time iteration if list is huge.
        var dayCounts: [Int: Int] = [:] 
        for d in weeklyDebriefs {
            let weekday = Calendar.current.component(.weekday, from: d.occurredAt)
            dayCounts[weekday, default: 0] += 1
        }
        let maxDay = dayCounts.max(by: { $0.value < $1.value })?.key
        let mostActiveDayStr = dayCounts.isEmpty ? "-" : dayName(for: maxDay)
        
        // 5. Longest Streak (Consecutive Hours)
        // Streak inherently needs history to be meaningful. 
        // If we strictly limit to 7 days, a 100-day streak becomes 7 days. 
        // We will calculate streak on the FETCHED dataset (which user previously agreed could be limited or all-time).
        // For now, we use `allDebriefs` for streak to be accurate, as streak is usually an "All Time" bragging right.
        // If "All Time" fetch is banned, we can't show true streak. 
        // Assuming we fetched all, we calculate streak on all. 
        let streak = calculateHourlyStreak(debriefs: allDebriefs)
        
        return StatsOverview(
            totalDebriefs: totalDebriefs,
            totalMinutes: totalMinutes,
            totalActionItems: totalActionItems,
            totalContacts: uniqueContacts,
            avgDebriefDuration: avgSeconds, // Weekly Average
            mostActiveDay: mostActiveDayStr,
            longestStreak: streak // All-time Streak based on fetched data
        )
    }
    
    private func calculateHourlyStreak(debriefs: [Debrief]) -> Int {
        // defined as: sequence of consecutive hours having >=1 debrief
        // Strategy: 
        // 1. Get Set of unique "Hour-Buckets" (e.g. Timestamp of the hour or just Int(timeInterval/3600))
        // 2. Sort them.
        // 3. Iterate to find longest sequence (current == prev + 1)
        
        let hours = debriefs.map { Int($0.occurredAt.timeIntervalSince1970 / 3600) }
        let uniqueHours = Array(Set(hours)).sorted()
        
        if uniqueHours.isEmpty { return 0 }
        
        var maxStreak = 1
        var currentStreak = 1
        
        for i in 1..<uniqueHours.count {
            if uniqueHours[i] == uniqueHours[i-1] + 1 {
                currentStreak += 1
            } else {
                maxStreak = max(maxStreak, currentStreak)
                currentStreak = 1
            }
        }
        maxStreak = max(maxStreak, currentStreak) // Check last run
        
        return maxStreak
    }
    
    private func dayName(for weekday: Int?) -> String {
        guard let w = weekday else { return "-" }
        // Calendar weekday: 1=Sun
        switch w {
        case 1: return "Sunday"
        case 2: return "Monday"
        case 3: return "Tuesday"
        case 4: return "Wednesday"
        case 5: return "Thursday"
        case 6: return "Friday"
        case 7: return "Saturday"
        default: return "-"
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
