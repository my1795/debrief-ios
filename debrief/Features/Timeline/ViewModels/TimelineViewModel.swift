//
//  TimelineViewModel.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 17/01/2026.
//

import Foundation
import FirebaseFirestore
import Combine

@MainActor
class TimelineViewModel: ObservableObject {
    @Published var debriefs: [Debrief] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var searchText = ""
    @Published var filters = DebriefFilters()
    @Published var recentContacts: [Contact] = []
    @Published var error: AppError? = nil  // For user-facing errors
    @Published var isFromCache = false  // Indicates if data is from local cache

    // Grouped for UI
    @Published var groupedDebriefs: [String: [Debrief]] = [:]
    @Published var sortedSectionHeaders: [String] = []

    // Snapshot Listener State
    private var debriefsCancellable: AnyCancellable?
    private var dailyStatsCancellable: AnyCancellable?
    private var currentLimit = 50  // Start with 50, increase on "load more"
    private var hasMore = true
    private var currentUserId: String?

    private let firestoreService = FirestoreService.shared
    private var cancellables = Set<AnyCancellable>()

    // Shared Formatter for performance
    private static let sectionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter
    }()

    init() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.groupDebriefsByDate()
            }
            .store(in: &cancellables)

        // Observe pending uploads (Offline First)
        // Debounce to prevent thrashing on rapid updates (progress etc)
        DebriefUploadManager.shared.$pendingDebriefs
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.groupDebriefsByDate()
            }
            .store(in: &cancellables)
    }

    deinit {
        // Clean up listeners when ViewModel is deallocated
        debriefsCancellable?.cancel()
        dailyStatsCancellable?.cancel()
    }
    // Stats
    struct DailyStats {
        var todayDebriefs: Int = 0
        var todayCalls: Int = 0
        var todayDuration: TimeInterval = 0
    }
    @Published var dailyStats = DailyStats()

    // Dependencies (removed unused ones)
    private let statsService = StatsService()

    // MARK: - Snapshot Listener Based Loading

    /// Starts observing debriefs with real-time updates.
    /// Data is cached locally by Firestore - instant load on subsequent opens.
    func startObserving(userId: String) {
        guard currentUserId != userId else { return } // Already observing
        currentUserId = userId

        // Reset state
        currentLimit = 50
        hasMore = true
        isLoading = true

        setupDebriefListener(userId: userId)
        setupDailyStatsListener(userId: userId)
    }

    /// Sets up the debriefs snapshot listener
    private func setupDebriefListener(userId: String) {
        // Cancel previous listener
        debriefsCancellable?.cancel()

        debriefsCancellable = firestoreService.observeDebriefs(
            userId: userId,
            filters: filters,
            limit: currentLimit
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("Debriefs listener failed: \(error)")
                    self?.error = AppError.from(error)
                    self?.isLoading = false
                }
            },
            receiveValue: { [weak self] result in
                guard let self = self else { return }

                Task { @MainActor in
                    // Resolve names locally (Address Book lookup)
                    let resolvedDebriefs = await self.resolveNames(for: result.debriefs)

                    self.debriefs = resolvedDebriefs
                    self.hasMore = result.hasMore
                    self.isFromCache = result.isFromCache
                    self.isLoading = false
                    self.isLoadingMore = false

                    // Extract recent contacts from first load if no filters active
                    if !self.filters.isActive && self.recentContacts.isEmpty {
                        await self.extractRecentContacts(from: resolvedDebriefs)
                    }

                    self.groupDebriefsByDate()

                    Logger.success("Updated with \(resolvedDebriefs.count) debriefs (cache: \(result.isFromCache))")
                }
            }
        )
    }

    /// Sets up the daily stats snapshot listener
    private func setupDailyStatsListener(userId: String) {
        // Cancel previous listener
        dailyStatsCancellable?.cancel()

        dailyStatsCancellable = firestoreService.observeDailyStats(userId: userId, date: Date())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        Logger.error("Daily stats listener failed: \(error)")
                    }
                },
                receiveValue: { [weak self] stats in
                    self?.dailyStats = DailyStats(
                        todayDebriefs: stats.debriefsCount,
                        todayCalls: stats.callsCount,
                        todayDuration: TimeInterval(stats.totalDurationSec)
                    )
                }
            )

        // Fetch calls count separately (one-shot, different collection)
        Task {
            await loadCallsCount(userId: userId)
        }
    }

    /// Fetches calls count (separate collection, one-shot query)
    private func loadCallsCount(userId: String) async {
        do {
            let (startOfDay, endOfDay) = DateCalculator.dayBounds(for: Date())
            let count = try await firestoreService.getCallsCount(userId: userId, start: startOfDay, end: endOfDay)
            self.dailyStats.todayCalls = count
        } catch {
            Logger.warning("Failed to load calls count: \(error)")
        }
    }

    // MARK: - Filter & Load More

    func applyFilters(_ newFilters: DebriefFilters, userId: String) async {
        self.filters = newFilters
        self.currentLimit = 50 // Reset limit
        self.recentContacts = [] // Clear recent contacts when filtering

        // Restart listener with new filters
        setupDebriefListener(userId: userId)
    }

    /// Legacy loadData method - now starts snapshot listener
    func loadData(userId: String, refresh: Bool = false) async {
        if refresh {
            currentLimit = 50
            recentContacts = []
        }
        startObserving(userId: userId)
    }

    /// Load more debriefs by increasing the limit and restarting the listener
    func loadMore(userId: String) {
        guard hasMore, !isLoadingMore else { return }

        isLoadingMore = true
        currentLimit += 50 // Increase limit by 50

        Logger.info("Loading more... new limit: \(currentLimit)")

        // Restart listener with new limit
        setupDebriefListener(userId: userId)
    }

    private func extractRecentContacts(from debriefs: [Debrief]) async {
        var seenIds = Set<String>()
        var contacts: [Contact] = []

        for debrief in debriefs {
            guard !debrief.contactId.isEmpty, !seenIds.contains(debrief.contactId) else { continue }
            seenIds.insert(debrief.contactId)

            let name = debrief.contactName.isEmpty ? "Unknown" : debrief.contactName
            // Note: We use existing Debrief info. Real app might fetch full Contact obj.
            let contact = Contact(
                id: debrief.contactId,
                name: name,
                handle: nil,
                totalDebriefs: 0, // Not critical here
                phoneNumbers: [],
                emailAddresses: []
            )
            contacts.append(contact)
            if contacts.count >= 10 { break }
        }
        self.recentContacts = contacts
    }

    // Helper: Address Book Lookup (now uses shared ContactResolver)
    private func resolveNames(for debriefs: [Debrief]) async -> [Debrief] {
        return await ContactResolver.shared.resolveDebriefs(debriefs)
    }

    /// Called when user scrolls near the bottom - triggers load more
    func loadMoreIfNeeded(currentItem: Debrief, userId: String) {
        guard let index = debriefs.firstIndex(where: { $0.id == currentItem.id }) else { return }

        let thresholdIndex = debriefs.count - 5
        if index >= thresholdIndex && hasMore && !isLoadingMore {
            loadMore(userId: userId)
        }
    }

    // Legacy method for backwards compatibility
    func loadDailyStats(userId: String) async {
        // Now handled by snapshot listener, but keep for initial load
        await loadCallsCount(userId: userId)
    }
    
    // Sections Struct for Clean UI
    struct TimelineSection: Identifiable {
        let id: String
        let title: String
        let date: Date // For sorting
        let debriefs: [Debrief]
    }
    
    @Published var sections: [TimelineSection] = []
    
    private func groupDebriefsByDate() {
        let calendar = Calendar.current
        
        // MERGE: Pending Uploads + Fetched Debriefs (Offline First)
        // Pending items from UploadManager (local drafts) + Fetched items from Firestore
        let pending = DebriefUploadManager.shared.pendingDebriefs
        let uniquePending = pending.filter { p in !debriefs.contains(where: { $0.id == p.id }) }
        let allDebriefs = uniquePending + debriefs
        
        // Local Filter
        let filtered = searchText.isEmpty ? allDebriefs : allDebriefs.filter {
            $0.contactName.localizedCaseInsensitiveContains(searchText) ||
            ($0.summary?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            ($0.transcript?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
        
        let grouped = Dictionary(grouping: filtered) { (debrief) -> Date in
            return calendar.startOfDay(for: debrief.occurredAt)
        }
        
        // ... (rest is same)
        let sortedDates = grouped.keys.sorted(by: >)
        
        self.sections = sortedDates.map { date in
            let title: String
            if calendar.isDateInToday(date) {
                title = "Today"
            } else if calendar.isDateInYesterday(date) {
                title = "Yesterday"
            } else {
                let formatter = Self.sectionDateFormatter
                title = formatter.string(from: date)
            }
            
            // Ensure debriefs within section are sorted desc
            let sectionDebriefs = grouped[date]?.sorted(by: { $0.occurredAt > $1.occurredAt }) ?? []
            
            return TimelineSection(id: title, title: title, date: date, debriefs: sectionDebriefs)
        }
    }
}
