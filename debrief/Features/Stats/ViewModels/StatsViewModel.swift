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
    @Published var isLoadingWeeklyStats = false // Widget stats loading
    @Published var isLoadingQuickStats = false // Quick stats loading
    @Published var isLoadingQuota = false // Quota loading
    @Published var error: AppError? = nil  // User-facing errors
    @Published var weeklyStatsError: Bool = false // Error loading weekly stats
    @Published var quickStatsError: Bool = false // Error loading quick stats
    @Published var quotaError: Bool = false // Error loading quota
    
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
    
    private var currentUserId: String?

    init(statsService: StatsServiceProtocol = StatsService()) {
        self.statsService = statsService
    }

    deinit {
        cancellables.forEach { $0.cancel() }
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

        // 3. Overview Stats (from weeklyUsage)
        let totalMinutes = Int(ceil(Double(totalSeconds) / 60.0))
        let avgSeconds = debriefCount > 0 ? Double(totalSeconds) / Double(debriefCount) : 0.0

        self.overview = StatsOverview(
            totalDebriefs: debriefCount,
            totalMinutes: totalMinutes,
            totalActionItems: actionItemsCount,
            totalContacts: uniqueContactsCount,
            avgDebriefDuration: avgSeconds,
            mostActiveDay: "-", // Would need additional tracking in backend
            longestStreak: 0     // Would need additional tracking in backend
        )

        print("✅ [StatsViewModel] All stats updated from UserPlan (offline-ready)")
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
