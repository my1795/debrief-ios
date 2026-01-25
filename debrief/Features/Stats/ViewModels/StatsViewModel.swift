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

// MARK: - Cached Stats Week Data (1-hour TTL)
/// Cache for Weekly Stats (Sunday-Sunday) - separate from Billing Week
struct StatsWeekCache: Codable {
    let debriefCount: Int
    let totalSeconds: Int
    let actionItemsCount: Int
    let uniqueContactsCount: Int
    let cachedAt: Date
    let weekStart: Date

    var isValid: Bool {
        let oneHour: TimeInterval = 60 * 60
        return Date().timeIntervalSince(cachedAt) < oneHour
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
    private var statsWeekListenerCancellable: AnyCancellable?

    private var currentUserId: String?
    private let cacheKey = "calculated_stats_cache"
    private let statsWeekCacheKey = "stats_week_cache"

    init(statsService: StatsServiceProtocol = StatsService()) {
        self.statsService = statsService
    }

    deinit {
        cancellables.forEach { $0.cancel() }
        debriefsListenerCancellable?.cancel()
        statsWeekListenerCancellable?.cancel()
    }

    // MARK: - Snapshot Listener Based Loading

    /// Starts observing data for Stats screen.
    /// - UserPlan listener: For Quota Usage (Billing Week)
    /// - Debriefs listener: For Weekly Stats (Stats Week: Sunday-Sunday)
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

        // 1. UserPlan listener - for Quota Usage (BILLING WEEK)
        FirestoreService.shared.observeUserPlan(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let err) = completion {
                        Logger.error("UserPlan listener failed: \(err)")
                        self?.error = AppError.from(err)
                        self?.quotaError = true
                    }
                    self?.isLoadingQuota = false
                },
                receiveValue: { [weak self] plan in
                    guard let self = self else { return }

                    Logger.sync("Real-time UserPlan update received (Billing Week quota)")

                    self.userPlan = plan
                    self.updateQuotaFromPlan(plan)  // Only update Quota (Billing Week)

                    self.isLoadingQuota = false
                    self.quotaError = false
                }
            )
            .store(in: &cancellables)

        // 2. Weekly Stats from Debriefs query (STATS WEEK: Sunday-Sunday)
        loadStatsWeekData(userId: userId)

        // 3. Top contacts (with cache)
        loadTopContactsWithCache(userId: userId)

        // 4. Calculated stats (mostActiveDay, longestStreak) with 6h cache
        loadCalculatedStatsWithCache(userId: userId)
    }

    // MARK: - Quota from Billing Week (UserPlan)

    /// Updates only Quota Usage from UserPlan (Billing Week data)
    private func updateQuotaFromPlan(_ plan: UserPlan) {
        let userQuota = plan.toUserQuota()
        self.quota = mapToStatsQuota(userQuota)
        Logger.data("Quota updated from Billing Week: \(plan.weeklyUsage.debriefCount) debriefs, \(plan.usedMinutes) min")
    }

    // MARK: - Weekly Stats from Stats Week (Debriefs Query)

    /// Loads Weekly Stats from debriefs collection using Stats Week (Sunday-Sunday)
    /// Uses 1-hour cache TTL for instant display, but always starts listener for live updates
    private func loadStatsWeekData(userId: String) {
        let (weekStart, weekEnd) = statsWeekProvider.currentWeekRange()

        // 1. Show cache immediately for fast UI (but don't return - always start listener)
        if let cached = loadStatsWeekCache(userId: userId, weekStart: weekStart), cached.isValid {
            Logger.data("Showing cached Stats Week data (age: \(Int(Date().timeIntervalSince(cached.cachedAt) / 60)) min) - actions: \(cached.actionItemsCount)")
            updateWeeklyStatsUI(
                debriefCount: cached.debriefCount,
                totalSeconds: cached.totalSeconds,
                actionItemsCount: cached.actionItemsCount,
                uniqueContactsCount: cached.uniqueContactsCount
            )
            // Don't set isLoading=false yet - listener will update with fresh data
        }

        // 2. ALWAYS start snapshot listener for live updates (even if cache exists)
        statsWeekListenerCancellable?.cancel()

        var filters = DebriefFilters()
        filters.dateOption = .custom
        filters.customStartDate = weekStart
        filters.customEndDate = weekEnd

        Logger.sync("Starting Stats Week listener (Sun-Sun): \(weekStart) to \(weekEnd)")

        statsWeekListenerCancellable = FirestoreService.shared.observeDebriefs(
            userId: userId,
            filters: filters,
            limit: 500
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("Stats Week listener failed: \(error)")
                    self?.weeklyStatsError = true
                    self?.quickStatsError = true
                }
                self?.isLoadingWeeklyStats = false
                self?.isLoadingQuickStats = false
                self?.isLoading = false
            },
            receiveValue: { [weak self] result in
                guard let self = self else { return }

                // Aggregate stats from debriefs
                let debriefs = result.debriefs
                let debriefCount = debriefs.count
                let totalSeconds = debriefs.reduce(0) { $0 + Int($1.duration) }
                // Use pre-computed actionItemsCount if available, fallback to counting array
                let actionItemsCount = debriefs.reduce(0) { $0 + ($1.actionItemsCount ?? $1.actionItems?.count ?? 0) }

                // DEBUG: Log action items detail
                Logger.debug("📊 Action Items Debug: total=\(actionItemsCount)")
                for (i, d) in debriefs.prefix(3).enumerated() {
                    Logger.debug("  Debrief[\(i)]: actionItemsCount=\(d.actionItemsCount ?? -1), actionItems.count=\(d.actionItems?.count ?? 0)")
                }
                let uniqueContacts = Set(debriefs.compactMap { $0.contactId.isEmpty ? nil : $0.contactId })
                let uniqueContactsCount = uniqueContacts.count

                self.updateWeeklyStatsUI(
                    debriefCount: debriefCount,
                    totalSeconds: totalSeconds,
                    actionItemsCount: actionItemsCount,
                    uniqueContactsCount: uniqueContactsCount
                )

                // Save to cache
                self.saveStatsWeekCache(
                    userId: userId,
                    debriefCount: debriefCount,
                    totalSeconds: totalSeconds,
                    actionItemsCount: actionItemsCount,
                    uniqueContactsCount: uniqueContactsCount,
                    weekStart: weekStart
                )

                self.isLoadingWeeklyStats = false
                self.isLoadingQuickStats = false
                self.isLoading = false
                self.weeklyStatsError = false
                self.quickStatsError = false

                Logger.success("Stats Week updated (Sun-Sun): \(debriefCount) debriefs, \(totalSeconds)s, \(actionItemsCount) actions, \(uniqueContactsCount) contacts (cache: \(result.isFromCache))")
            }
        )
    }

    /// Updates Weekly Stats UI (4 cards) - Stats Week data
    private func updateWeeklyStatsUI(debriefCount: Int, totalSeconds: Int, actionItemsCount: Int, uniqueContactsCount: Int) {
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

        // Update overview
        let totalMinutes = Int(ceil(Double(totalSeconds) / 60.0))
        let avgSeconds = debriefCount > 0 ? Double(totalSeconds) / Double(debriefCount) : 0.0

        self.overview = StatsOverview(
            totalDebriefs: debriefCount,
            totalMinutes: totalMinutes,
            totalActionItems: actionItemsCount,
            totalContacts: uniqueContactsCount,
            avgDebriefDuration: avgSeconds,
            mostActiveDay: self.mostActiveDay,
            longestStreak: self.longestStreak
        )
    }

    // MARK: - Stats Week Cache (1-hour TTL)

    private func loadStatsWeekCache(userId: String, weekStart: Date) -> StatsWeekCache? {
        let key = "\(statsWeekCacheKey)_\(userId)"
        guard let data = UserDefaults.standard.data(forKey: key),
              let cache = try? JSONDecoder().decode(StatsWeekCache.self, from: data) else {
            return nil
        }

        // Check if cache is for the same week
        let calendar = Calendar.current
        guard calendar.isDate(cache.weekStart, inSameDayAs: weekStart) else {
            Logger.data("Stats Week cache is for different week, invalidating")
            return nil
        }

        return cache
    }

    private func saveStatsWeekCache(userId: String, debriefCount: Int, totalSeconds: Int, actionItemsCount: Int, uniqueContactsCount: Int, weekStart: Date) {
        let cache = StatsWeekCache(
            debriefCount: debriefCount,
            totalSeconds: totalSeconds,
            actionItemsCount: actionItemsCount,
            uniqueContactsCount: uniqueContactsCount,
            cachedAt: Date(),
            weekStart: weekStart
        )

        if let data = try? JSONEncoder().encode(cache) {
            let key = "\(statsWeekCacheKey)_\(userId)"
            UserDefaults.standard.set(data, forKey: key)
            Logger.data("Saved Stats Week cache (1h TTL)")
        }
    }

    // MARK: - Calculated Stats with 6-Hour Cache

    /// Loads mostActiveDay and longestStreak with 6-hour cache
    private func loadCalculatedStatsWithCache(userId: String) {
        let weekStart = statsWeekProvider.currentWeekRange().start

        // 1. Try to load from cache first
        if let cached = loadCachedCalculatedStats(userId: userId, weekStart: weekStart) {
            self.mostActiveDay = cached.mostActiveDay
            self.longestStreak = cached.longestStreak
            Logger.data("Using cached calculated stats (mostActiveDay: \(cached.mostActiveDay), streak: \(cached.longestStreak))")

            // If cache is still valid, don't fetch
            if cached.isValid {
                return
            }
            // Cache expired but we have data - fetch in background, keep showing cached values
            Logger.info("Cache expired, fetching fresh data in background...")
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
                    Logger.error("Weekly debriefs listener failed: \(error)")
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

                Logger.success("Calculated stats updated - mostActiveDay: \(calculatedMostActiveDay), streak: \(calculatedStreak) (from \(result.debriefs.count) debriefs, cache: \(result.isFromCache))")
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
            Logger.data("Cache is for different week, invalidating")
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
            Logger.data("Saved calculated stats to cache")
        }
    }

    /// Entry point for StatsView - initializes stats observation with auth check
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
        Logger.debug("Mapping Quota - Seconds: \(userQuota.usedRecordingSeconds) -> Minutes: \(userQuota.usedRecordingMinutes)")
        
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
                Logger.data("Using Cached Top Contacts (Age: \(Int(age) / 60) min)")
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
                Logger.sync("Fetching Debriefs for Top Contacts (background)...")

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
                Logger.error("Failed to calculate Top Contacts: \(error)")
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
