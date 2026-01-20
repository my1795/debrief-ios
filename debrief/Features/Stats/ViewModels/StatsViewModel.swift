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

// MARK: - Cached Calculated Stats (6-hour TTL)
struct CalculatedStatsCache: Codable {
    let mostActiveDay: String
    let longestStreak: Int
    let cachedAt: Date
    let weekStart: Date

    var isValid: Bool {
        let sixHours: TimeInterval = 6 * 60 * 60
        return Date().timeIntervalSince(cachedAt) < sixHours
    }
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
    @Published var isLoadingWeeklyStats = false // Widget stats loading
    @Published var isLoadingQuickStats = false // Quick stats loading
    @Published var isLoadingQuota = false // Quota loading
    @Published var isLoadingCalculatedStats = false // mostActiveDay/streak loading
    @Published var error: AppError? = nil  // User-facing errors
    @Published var weeklyStatsError: Bool = false // Error loading weekly stats
    @Published var quickStatsError: Bool = false // Error loading quick stats
    @Published var quotaError: Bool = false // Error loading quota

    // Calculated stats (from debriefs snapshot with 6h cache)
    @Published var mostActiveDay: String = "-"
    @Published var longestStreak: Int = 0
    
    private let statsService: StatsServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var debriefsListenerCancellable: AnyCancellable?

    private var currentUserId: String?
    private let cacheKey = "calculated_stats_cache"

    init(statsService: StatsServiceProtocol = StatsService()) {
        self.statsService = statsService
    }

    deinit {
        cancellables.forEach { $0.cancel() }
        debriefsListenerCancellable?.cancel()
    }

    // MARK: - Snapshot Listener Based Loading

    /// Starts observing UserPlan with real-time updates.
    /// ALL stats are derived from UserPlan - no separate debrief fetches needed.
    func startObserving(userId: String) {
        guard currentUserId != userId else { return } // Already observing
        currentUserId = userId

        isLoading = true
        isLoadingQuota = true
        isLoadingWeeklyStats = true
        isLoadingQuickStats = true
        error = nil

        // Cancel previous subscriptions
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()

        // Single snapshot listener for UserPlan - provides ALL stats
        FirestoreService.shared.observeUserPlan(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let err) = completion {
                        print("❌ [StatsViewModel] UserPlan listener failed: \(err)")
                        self?.error = AppError.from(err)
                        self?.quotaError = true
                        self?.weeklyStatsError = true
                        self?.quickStatsError = true
                    }
                    self?.isLoading = false
                    self?.isLoadingQuota = false
                    self?.isLoadingWeeklyStats = false
                    self?.isLoadingQuickStats = false
                },
                receiveValue: { [weak self] plan in
                    guard let self = self else { return }

                    print("⚡️ [StatsViewModel] Real-time UserPlan update received")

                    self.userPlan = plan
                    self.updateAllStatsFromPlan(plan)

                    self.isLoading = false
                    self.isLoadingQuota = false
                    self.isLoadingWeeklyStats = false
                    self.isLoadingQuickStats = false
                    self.quotaError = false
                    self.weeklyStatsError = false
                    self.quickStatsError = false
                }
            )
            .store(in: &cancellables)

        // Top contacts still needs debrief fetch (with cache)
        loadTopContactsWithCache(userId: userId)

        // Calculated stats (mostActiveDay, longestStreak) with 6h cache
        loadCalculatedStatsWithCache(userId: userId)
    }

    /// Updates ALL stats from UserPlan data (no debrief fetch needed)
    private func updateAllStatsFromPlan(_ plan: UserPlan) {
        // 1. Quota
        let userQuota = plan.toUserQuota()
        self.quota = mapToStatsQuota(userQuota)

        // 2. Widget Stats (from weeklyUsage)
        let debriefCount = plan.weeklyUsage.debriefCount
        let totalSeconds = plan.weeklyUsage.totalSeconds
        let actionItemsCount = plan.weeklyActionItemsCount
        let uniqueContactsCount = plan.weeklyUniqueContactsCount

        let durationValue: String
        if totalSeconds < 60 {
            durationValue = "\(totalSeconds) sec"
        } else {
            durationValue = "\(Int(ceil(Double(totalSeconds) / 60.0))) min"
        }

        self.stats = [
            StatsDisplayData(title: "Total Debriefs", value: "\(debriefCount)", subValue: nil, isPositive: nil, icon: "mic.fill"),
            StatsDisplayData(title: "Duration per Week", value: durationValue, subValue: nil, isPositive: nil, icon: "clock.fill"),
            StatsDisplayData(title: "Action Items", value: "\(actionItemsCount)", subValue: nil, isPositive: nil, icon: "checklist"),
            StatsDisplayData(title: "Active Contacts", value: "\(uniqueContactsCount)", subValue: nil, isPositive: nil, icon: "person.2.fill")
        ]

        // 3. Overview Stats (from weeklyUsage + calculated stats)
        let totalMinutes = Int(ceil(Double(totalSeconds) / 60.0))
        let avgSeconds = debriefCount > 0 ? Double(totalSeconds) / Double(debriefCount) : 0.0

        self.overview = StatsOverview(
            totalDebriefs: debriefCount,
            totalMinutes: totalMinutes,
            totalActionItems: actionItemsCount,
            totalContacts: uniqueContactsCount,
            avgDebriefDuration: avgSeconds,
            mostActiveDay: self.mostActiveDay,  // From calculated stats
            longestStreak: self.longestStreak   // From calculated stats
        )

        print("✅ [StatsViewModel] All stats updated from UserPlan (offline-ready)")
    }

    // MARK: - Calculated Stats with 6-Hour Cache

    /// Loads mostActiveDay and longestStreak with 6-hour cache
    private func loadCalculatedStatsWithCache(userId: String) {
        let weekStart = statsWeekProvider.currentWeekRange().start

        // 1. Try to load from cache first
        if let cached = loadCachedCalculatedStats(userId: userId, weekStart: weekStart) {
            self.mostActiveDay = cached.mostActiveDay
            self.longestStreak = cached.longestStreak
            print("📦 [StatsViewModel] Using cached calculated stats (mostActiveDay: \(cached.mostActiveDay), streak: \(cached.longestStreak))")

            // If cache is still valid, don't fetch
            if cached.isValid {
                return
            }
            // Cache expired but we have data - fetch in background, keep showing cached values
            print("⏰ [StatsViewModel] Cache expired, fetching fresh data in background...")
        } else {
            // No cache - show loading state
            isLoadingCalculatedStats = true
        }

        // 2. Start snapshot listener for weekly debriefs
        startWeeklyDebriefsListener(userId: userId, weekStart: weekStart)
    }

    /// Starts a snapshot listener for current week's debriefs to calculate stats
    private func startWeeklyDebriefsListener(userId: String, weekStart: Date) {
        debriefsListenerCancellable?.cancel()

        let (start, end) = statsWeekProvider.currentWeekRange()

        // Create filters for current week using custom date range
        var filters = DebriefFilters()
        filters.dateOption = .custom
        filters.customStartDate = start
        filters.customEndDate = end

        debriefsListenerCancellable = FirestoreService.shared.observeDebriefs(
            userId: userId,
            filters: filters,
            limit: 200 // Get all debriefs for the week for accurate calculation
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    print("❌ [StatsViewModel] Weekly debriefs listener failed: \(error)")
                }
                self?.isLoadingCalculatedStats = false
            },
            receiveValue: { [weak self] result in
                guard let self = self else { return }

                // Calculate stats from debriefs
                let calculatedMostActiveDay = self.calculateMostActiveDay(from: result.debriefs)
                let calculatedStreak = self.calculateHourlyStreak(from: result.debriefs)

                self.mostActiveDay = calculatedMostActiveDay
                self.longestStreak = calculatedStreak
                self.isLoadingCalculatedStats = false

                // Update overview with new values
                self.overview = StatsOverview(
                    totalDebriefs: self.overview.totalDebriefs,
                    totalMinutes: self.overview.totalMinutes,
                    totalActionItems: self.overview.totalActionItems,
                    totalContacts: self.overview.totalContacts,
                    avgDebriefDuration: self.overview.avgDebriefDuration,
                    mostActiveDay: calculatedMostActiveDay,
                    longestStreak: calculatedStreak
                )

                // Save to cache
                self.saveCachedCalculatedStats(
                    userId: userId,
                    mostActiveDay: calculatedMostActiveDay,
                    longestStreak: calculatedStreak,
                    weekStart: weekStart
                )

                print("✅ [StatsViewModel] Calculated stats updated - mostActiveDay: \(calculatedMostActiveDay), streak: \(calculatedStreak) (from \(result.debriefs.count) debriefs, cache: \(result.isFromCache))")
            }
        )
    }

    // MARK: - Calculation Helpers

    private func calculateMostActiveDay(from debriefs: [Debrief]) -> String {
        guard !debriefs.isEmpty else { return "-" }

        var dayCounts: [Int: Int] = [:]
        for d in debriefs {
            let weekday = Calendar.current.component(.weekday, from: d.occurredAt)
            dayCounts[weekday, default: 0] += 1
        }

        guard let maxDay = dayCounts.max(by: { $0.value < $1.value })?.key else {
            return "-"
        }

        return dayName(for: maxDay)
    }

    private func calculateHourlyStreak(from debriefs: [Debrief]) -> Int {
        guard !debriefs.isEmpty else { return 0 }

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
        return max(maxStreak, currentStreak)
    }

    private func dayName(for weekday: Int) -> String {
        switch weekday {
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

    // MARK: - Cache Helpers

    private func loadCachedCalculatedStats(userId: String, weekStart: Date) -> CalculatedStatsCache? {
        let key = "\(cacheKey)_\(userId)"
        guard let data = UserDefaults.standard.data(forKey: key),
              let cache = try? JSONDecoder().decode(CalculatedStatsCache.self, from: data) else {
            return nil
        }

        // Check if cache is for the same week
        let calendar = Calendar.current
        guard calendar.isDate(cache.weekStart, inSameDayAs: weekStart) else {
            print("📦 [StatsViewModel] Cache is for different week, invalidating")
            return nil
        }

        return cache
    }

    private func saveCachedCalculatedStats(userId: String, mostActiveDay: String, longestStreak: Int, weekStart: Date) {
        let cache = CalculatedStatsCache(
            mostActiveDay: mostActiveDay,
            longestStreak: longestStreak,
            cachedAt: Date(),
            weekStart: weekStart
        )

        if let data = try? JSONEncoder().encode(cache) {
            let key = "\(cacheKey)_\(userId)"
            UserDefaults.standard.set(data, forKey: key)
            print("💾 [StatsViewModel] Saved calculated stats to cache")
        }
    }

    /// Legacy method - now starts snapshot listener
    func loadData() async {
        guard let userId = AuthSession.shared.user?.id else {
            isLoading = false
            return
        }

        // Ensure Firebase Auth is ready
        if Auth.auth().currentUser == nil {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard Auth.auth().currentUser != nil else {
                isLoading = false
                return
            }
        }

        startObserving(userId: userId)
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
    
    // MARK: - Helpers

    /// Stats Week Provider for consistent Sunday-Sunday week bounds
    private let statsWeekProvider = StatsWeekProvider()

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
