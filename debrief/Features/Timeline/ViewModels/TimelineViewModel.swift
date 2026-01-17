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
    @Published var searchText = ""
    @Published var filters = DebriefFilters()
    @Published var recentContacts: [Contact] = []
    
    // Grouped for UI
    @Published var groupedDebriefs: [String: [Debrief]] = [:]
    @Published var sortedSectionHeaders: [String] = []
    
    // Pagination State
    private var lastDocument: DocumentSnapshot?
    private var hasMore = true
    private let pageSize = 20
    private var isFetching = false // Lock to prevent duplicate calls
    
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
    // Stats
    struct DailyStats {
        var todayDebriefs: Int = 0
        var todayCalls: Int = 0
        var todayMins: Int = 0
    }
    @Published var dailyStats = DailyStats()
    
    // Dependencies
    private let statsService = StatsService()
    private let contactStoreService = ContactStoreService()
    
    // ...
    
    // Load local stats (efficient server-side)
    func loadDailyStats(userId: String) async {
        let now = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        async let debriefsCount = statsService.getDebriefsCount(start: startOfDay, end: endOfDay)
        async let callsCount = statsService.getCallsCount(start: startOfDay, end: endOfDay)
        async let durationTotal = firestoreService.getTotalDuration(userId: userId, start: startOfDay, end: endOfDay)
        
        do {
            let (dCount, cCount, durationSec) = try await (debriefsCount, callsCount, durationTotal)
             let durationVal: Double
            if let dSec = durationSec as? Int {
                 durationVal = Double(dSec)
            } else {
                 durationVal = Double(truncating: durationSec as! NSNumber)
            }
            
            // Wait, firestoreService.getTotalDuration returns Int.
            let durationMins = Int(ceil(Double(durationVal) / 60))
            
            await MainActor.run {
                self.dailyStats = DailyStats(
                    todayDebriefs: dCount,
                    todayCalls: cCount,
                    todayMins: durationMins
                )
            }
        } catch {
            print("❌ [TimelineViewModel] Failed to load daily stats: \(error)")
        }
    }
    
    // MARK: - Pagination Logic
    
    func applyFilters(_ newFilters: DebriefFilters, userId: String) async {
        self.filters = newFilters
        await loadData(userId: userId, refresh: true)
    }
    
    func loadData(userId: String, refresh: Bool = false) async {
        if refresh {
            lastDocument = nil
            hasMore = true
            debriefs = []
            groupedDebriefs = [:]
            sortedSectionHeaders = []
        }
        
        guard hasMore && !isFetching else { return }
        
        isFetching = true
        if debriefs.isEmpty { isLoading = true }
        
        do {
            let result = try await firestoreService.fetchDebriefs(
                userId: userId,
                filters: filters,
                limit: pageSize,
                startAfter: lastDocument
            )
            
            // Resolve Names locally (Address Book lookup)
            let resolvedDebriefs = await resolveNames(for: result.debriefs)
            
            // Extract recent contacts from the *first page* if we are refreshing and no filters active
            if refresh && !filters.isActive {
                await extractRecentContacts(from: resolvedDebriefs)
            }
            
            if refresh {
                self.debriefs = resolvedDebriefs
            } else {
                self.debriefs.append(contentsOf: resolvedDebriefs)
            }
            
            self.lastDocument = result.lastDocument
            self.hasMore = result.debriefs.count == pageSize
            
            self.groupDebriefsByDate()
            
        } catch {
            print("❌ [TimelineViewModel] Failed to load data: \(error)")
        }
        
        isLoading = false
        isFetching = false
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
                totalDebriefs: 0 // Not critical here
            )
            contacts.append(contact)
            if contacts.count >= 10 { break }
        }
        self.recentContacts = contacts
    }
    
    // Helper: Address Book Lookup
    private func resolveNames(for debriefs: [Debrief]) async -> [Debrief] {
        var resolved: [Debrief] = []
        for debrief in debriefs {
            var finalDebrief = debrief
            if !debrief.contactId.isEmpty {
                if let localName = await contactStoreService.getContactName(for: debrief.contactId) {
                    // Create copy with new name
                    finalDebrief = Debrief(
                        id: debrief.id,
                        userId: debrief.userId,
                        contactId: debrief.contactId,
                        contactName: localName,
                        occurredAt: debrief.occurredAt,
                        duration: debrief.duration,
                        status: debrief.status,
                        summary: debrief.summary,
                        transcript: debrief.transcript,
                        actionItems: debrief.actionItems,
                        audioUrl: debrief.audioUrl,
                        audioStoragePath: debrief.audioStoragePath
                    )
                }
            }
            resolved.append(finalDebrief)
        }
        return resolved
    }
    
    func loadMoreIfNeeded(currentItem: Debrief, userId: String) {
        guard let index = debriefs.firstIndex(where: { $0.id == currentItem.id }) else { return }
        
        let thresholdIndex = debriefs.count - 5
        if index >= thresholdIndex {
            Task {
                await loadData(userId: userId)
            }
        }
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
