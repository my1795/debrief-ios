//
//  StatsViewModel.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 14/01/2026.
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth


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
    @Published var isLoadingTopContacts = false // Calc state
    @Published var error: AppError? = nil  // User-facing errors
    
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
        error = nil

        // Verify we have AuthSession user
        guard let userId = AuthSession.shared.user?.id else {
            isLoading = false
            return
        }

        // Ensure Firebase Auth is ready (prevents permission denied errors)
        if Auth.auth().currentUser == nil {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard Auth.auth().currentUser != nil else {
                isLoading = false
                return
            }
        }

        startObservingQuota(userId: userId)
        // Trigger Top Contacts Calculation (Async, non-blocking)
        loadTopContactsWithCache(userId: userId)
        
        await loadWidgetData()
        await loadOverviewData()
        
        isLoading = false
    }
    
    private func startObservingQuota(userId: String) {
        // Observe UserPlan directly for billing week info
        FirestoreService.shared.observeUserPlan(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    print("❌ [StatsViewModel] UserPlan observation error: \(error)")
                    // Keep existing quota or show error state if needed
                }
            }, receiveValue: { [weak self] plan in
                print("⚡️ [StatsViewModel] Received real-time UserPlan update")
                self?.userPlan = plan
                // Convert to legacy UserQuota, then to StatsQuota for UI
                let userQuota = plan.toUserQuota()
                self?.quota = self?.mapToStatsQuota(userQuota) ?? .mock
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
    // MARK: - Top Contacts (Client-Side Aggregation + Cache)

    private func loadTopContactsWithCache(userId: String) {
        let now = Date()
        let calendar = Calendar.current

        // 1. Determine Current Stats Week (Sunday to Sunday) using StatsWeekProvider
        let (weekStart, weekEnd) = statsWeekProvider.currentWeekRange()

        // 2. Check Cache
        if let data = UserDefaults.standard.data(forKey: "top_contacts_cache_\(userId)"),
           let cache = try? JSONDecoder().decode(TopContactsCache.self, from: data) {

            let isSameWeek = calendar.isDate(cache.weekStart, inSameDayAs: weekStart)
            let age = now.timeIntervalSince(cache.timestamp)

            if isSameWeek && age < 12 * 3600 {
                print("⚡️ [StatsViewModel] Using Cached Top Contacts (Age: \(Int(age) / 60) min)")
                self.topContacts = cache.stats
                return
            }
        }

        // 3. Fetch & Aggregate - Use detached task for heavy computation
        Task { @MainActor in
            self.isLoadingTopContacts = true
        }

        // Move heavy work to background thread
        Task.detached(priority: .userInitiated) { [weak self, weekStart, weekEnd, userId] in
            do {
                print("⚡️ [StatsViewModel] Fetching Debriefs for Top Contacts (background)...")

                // Fetch only required fields using select() for smaller payload
                let debriefs = try await FirestoreService.shared.fetchDebriefs(
                    userId: userId,
                    start: weekStart,
                    end: weekEnd
                )

                // Aggregate on background thread
                var agg: [String: (count: Int, duration: Int)] = [:]
                for d in debriefs {
                    let cid = d.contactId
                    if cid.isEmpty { continue }
                    let curr = agg[cid] ?? (0, 0)
                    agg[cid] = (curr.count + 1, curr.duration + Int(d.duration))
                }

                // Sort by Count Descending - only top 5
                let sorted = agg.sorted { $0.value.count > $1.value.count }.prefix(5)

                // Resolve names in parallel for speed
                let resolvedStats = await withTaskGroup(of: TopContactStat?.self) { group in
                    for (cid, metrics) in sorted {
                        group.addTask {
                            let name = await ContactStoreService.shared.getContactName(for: cid) ?? "Unknown Contact"
                            return TopContactStat(
                                id: cid,
                                name: name,
                                company: "External",
                                debriefs: metrics.count,
                                minutes: metrics.duration / 60,
                                percentage: 0
                            )
                        }
                    }

                    var results: [TopContactStat] = []
                    for await stat in group {
                        if let s = stat { results.append(s) }
                    }
                    // Re-sort since TaskGroup doesn't preserve order
                    return results.sorted { $0.debriefs > $1.debriefs }
                }

                // Update UI on main thread
                await MainActor.run { [weak self] in
                    self?.topContacts = resolvedStats
                    self?.isLoadingTopContacts = false

                    // Save Cache
                    let cache = TopContactsCache(timestamp: Date(), weekStart: weekStart, stats: resolvedStats)
                    if let encoded = try? JSONEncoder().encode(cache) {
                        UserDefaults.standard.set(encoded, forKey: "top_contacts_cache_\(userId)")
                    }
                }

            } catch {
                print("❌ [StatsViewModel] Failed to calculate Top Contacts: \(error)")
                await MainActor.run { [weak self] in
                    self?.isLoadingTopContacts = false
                }
            }
        }
    }
    
    private func loadWidgetData() async {
        do {
            // Use Stats Week (Sunday-Sunday) for consistent week bounds
            let (thisWeekStart, thisWeekEnd) = statsWeekProvider.currentWeekRange()
            let (prevWeekStart, prevWeekEnd) = previousWeekBounds(for: Date())
            
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
            // Fetch ONLY current week's debriefs for efficiency
            guard let userId = AuthSession.shared.user?.id else {
                 print("⚠️ [StatsViewModel] No User ID found in session")
                 return
            }

            // Use Stats Week (Sunday-Sunday) for consistent week bounds
            let (startOfWeek, endOfWeek) = statsWeekProvider.currentWeekRange()
            let now = Date()
            let fetchEnd = min(now, endOfWeek) // Don't fetch future data

            print("📅 [StatsViewModel] Stats Week: \(startOfWeek) to \(endOfWeek)")

            // Fetch only necessary range
            // NOTE: 'Streak' calculation is now limited to the fetched range (Current Week).
            // For all-time streak, we should rely on a persisted user stat in future iterations.
            let weeklyDebriefs = try await FirestoreService.shared.fetchDebriefs(userId: userId, start: startOfWeek, end: fetchEnd)
            print("✅ [StatsViewModel] Fetched \(weeklyDebriefs.count) debriefs for weekly overview")

            // Calculate stats from the limited set (Running on Main Actor is fine for < 100 items)
            let stats = calculateStats(from: weeklyDebriefs, isWeeklySet: true)
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
    
    private func calculateStats(from debriefs: [Debrief], isWeeklySet: Bool = false) -> StatsOverview {
        if debriefs.isEmpty { return .empty }
        
        // If the set came pre-filtered (isWeeklySet), use it directly.
        // Otherwise handle filtering (legacy path).
        let weeklyDebriefs: [Debrief]
        if isWeeklySet {
            weeklyDebriefs = debriefs
        } else {
             // Fallback logic if passed full array
             var calendar = Calendar.current
             calendar.firstWeekday = 1
             let now = Date()
             let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
             weeklyDebriefs = debriefs.filter { $0.occurredAt >= startOfWeek }
        }
        
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
        // Streak is calculated on the dataset available. 
        // If we only fetch weekly data, this shows 'Weekly Streak'.
        let streak = calculateHourlyStreak(debriefs: debriefs)
        
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

    /// Stats Week Provider for consistent Sunday-Sunday week bounds
    private let statsWeekProvider = StatsWeekProvider()

    /// Returns Sunday-Sunday week bounds (Stats Week - calendar based)
    private func weekBounds(for date: Date) -> (start: Date, end: Date) {
        return statsWeekProvider.currentWeekRange()
    }

    /// Returns previous week bounds (Sunday-Sunday)
    private func previousWeekBounds(for date: Date) -> (start: Date, end: Date) {
        let current = statsWeekProvider.currentWeekRange()
        let calendar = Calendar.current
        guard let prevStart = calendar.date(byAdding: .day, value: -7, to: current.start),
              let prevEnd = calendar.date(byAdding: .day, value: -7, to: current.end) else {
            return (Date(), Date())
        }
        return (prevStart, prevEnd)
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
        guard quota.recordingsLimit > 0, quota.recordingsLimit != Int.max else { return 0 }
        return Double(quota.recordingsThisMonth) / Double(quota.recordingsLimit)
    }

    var minutesQuotaPercent: Double {
        guard quota.minutesLimit > 0, quota.minutesLimit != Int.max else { return 0 }
        return Double(quota.minutesThisMonth) / Double(quota.minutesLimit)
    }

    var storageQuotaPercent: Double {
        guard quota.storageLimitMB > 0, quota.storageLimitMB != Int.max else { return 0 }
        return Double(quota.storageUsedMB) / Double(quota.storageLimitMB)
    }

    // MARK: - Billing Week Properties

    /// Current user plan for billing week info
    @Published var userPlan: UserPlan?

    /// Days remaining until billing week resets
    var billingDaysRemaining: Int {
        guard let plan = userPlan else { return 7 }
        let now = Date()
        let end = plan.billingWeekEndDate
        return max(0, Calendar.current.dateComponents([.day], from: now, to: end).day ?? 0)
    }

    /// Billing week date range string (e.g., "Jan 15 - Jan 22")
    var billingWeekRangeString: String {
        guard let plan = userPlan else { return "-" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: plan.billingWeekStartDate)
        let end = formatter.string(from: plan.billingWeekEndDate)
        return "\(start) - \(end)"
    }

    /// Stats week date range string (e.g., "Sun Jan 14 - Sat Jan 20")
    var statsWeekRangeString: String {
        let (start, end) = statsWeekProvider.currentWeekRange()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM d"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}
