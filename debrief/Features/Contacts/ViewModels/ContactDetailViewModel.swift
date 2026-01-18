import SwiftUI
import FirebaseFirestore
import Combine

@MainActor
class ContactDetailViewModel: ObservableObject {
    @Published var debriefs: [Debrief] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var filters: DebriefFilters
    
    // Stats
    @Published var totalDebriefsCount: Int = 0
    @Published var totalDurationMinutes: Int = 0
    @Published var lastMetString: String = "-"
    @Published var error: AppError? = nil  // User-facing errors
    
    // Pagination
    private var lastDocument: DocumentSnapshot?
    private var hasMore = true
    private var isFetching = false
    private let pageSize = 20
    private var cancellables = Set<AnyCancellable>()
    private var loadTask: Task<Void, Never>?  // For cancellation
    
    let contact: Contact
    
    var displayedDebriefs: [Debrief] {
        var result = debriefs
        
        // 1. Text Search
        if !searchText.isEmpty {
            result = result.filter { debrief in
                (debrief.summary?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (debrief.transcript?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (debrief.actionItems?.contains(where: { $0.localizedCaseInsensitiveContains(searchText) }) ?? false)
            }
        }
        
        // 2. Action Items Filter
        if filters.hasActionItems {
            result = result.filter { debrief in
                !(debrief.actionItems?.isEmpty ?? true)
            }
        }
        
        return result
    }
    
    init(contact: Contact) {
        self.contact = contact
        self.filters = DebriefFilters(contactId: contact.id)
        
        // Debounce Search & Filter changes
        Publishers.CombineLatest($searchText, $filters)
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates { prev, curr in
                prev.0 == curr.0 && prev.1 == curr.1
            }
            .sink { [weak self] (text, filters) in
                guard let self = self else { return }
                Task {
                    await self.loadData(refresh: true)
                }
            }
            .store(in: &cancellables)
    }
    
    func loadData(refresh: Bool = false) async {
        guard !isFetching else { return }
        
        if refresh {
            // Cancel any in-flight task
            loadTask?.cancel()
            isFetching = true 
            lastDocument = nil
            hasMore = true
            withAnimation { self.debriefs = [] }
            self.isLoading = true
            // Fetch stats concurrently
            async let stats = fetchStats()
            _ = await stats
        }
        
        guard hasMore else { 
            isLoading = false
            isFetching = false
            return 
        }
        
        if !refresh { isFetching = true }

        do {
            // Check for cancellation
            try Task.checkCancellation()
            let userId = AuthSession.shared.user?.id ?? ""
            guard !userId.isEmpty else { return }
            
            // Prepare Filters
            var currentFilters = filters
            // Note: DebriefFilters doesn't have a 'searchText' field yet? 
            // We usually handle search client-side for Firestore (unless using Algolia).
            // But user requested search bar. 
            // If we only have client-side search, we fetch all?
            // Firestore doesn't support substring search.
            // STRATEGY: Fetch sorted by date, then filter client side? 
            // Or better: Search is likely for "Summary contains...".
            // Since we can't do that easily in Firestore without 3rd party,
            // we will stick to Filtering by Date/Action Items for server query,
            // and maybe filter by text locally IF list is small?
            // OR: Just ignore text search for now if backend doesn't support it, 
            // but usually we implemented a basic 'prefix' search or just client filter.
            // Let's assume standard Firestore constraints.
            
            // Fetch
            let result = try await FirestoreService.shared.fetchDebriefs(
                userId: userId,
                filters: currentFilters,
                limit: pageSize,
                startAfter: lastDocument
            )
            
            var fetched = result.debriefs
            
            // Client-side text filter (if dataset is small enough or just for loaded items)
            // Ideally we shouldn't claim to search history if we can't.
            // But let's proceed with Server-side Date filtering first.
            
            // Convert to Lite Objects
            let liteDebriefs = fetched.map { d -> Debrief in
                let liteTranscript = d.transcript.map { String($0.prefix(300)) }
                let finalContactName = (d.contactName.isEmpty || d.contactName == "Unknown") ? self.contact.name : d.contactName
                
                return Debrief(
                    id: d.id,
                    userId: d.userId,
                    contactId: d.contactId,
                    contactName: finalContactName,
                    occurredAt: d.occurredAt,
                    duration: d.duration,
                    status: d.status,
                    summary: d.summary,
                    transcript: liteTranscript,
                    actionItems: d.actionItems,
                    audioUrl: d.audioUrl,
                    audioStoragePath: d.audioStoragePath
                )
            }
            
            if refresh {
                self.debriefs = liteDebriefs
            } else {
                self.debriefs.append(contentsOf: liteDebriefs)
            }
            
            self.lastDocument = result.lastDocument
            self.hasMore = result.debriefs.count == pageSize
            
        } catch is CancellationError {
            // Task was cancelled, ignore silently
            print("📛 [ContactDetailViewModel] Task cancelled")
        } catch {
            print("Error fetch: \(error)")
            self.error = AppError.from(error)
        }
        
        isLoading = false
        isFetching = false
    }
    
    private func fetchStats() async {
        guard let userId = AuthSession.shared.user?.id else { return }
        
        do {
            var baseQuery = Firestore.firestore().collection("debriefs")
                .whereField("userId", isEqualTo: userId)
                .whereField("contactId", isEqualTo: contact.id)
            
            // Apply Date Filter if present
            if let startDate = filters.startDate {
                baseQuery = baseQuery.whereField("occurredAt", isGreaterThanOrEqualTo: startDate)
            }
            if let endDate = filters.endDate {
                baseQuery = baseQuery.whereField("occurredAt", isLessThan: endDate)
            }
            
            // 1. Count
            let countQuery = baseQuery.count
            let countSnapshot = try await countQuery.getAggregation(source: .server)
            let count = Int(countSnapshot.count)
            self.totalDebriefsCount = count
            
            // 2. Last Met
            let lastMetQuery = baseQuery
                .order(by: "occurredAt", descending: true)
                .limit(to: 1)
            
            let lastMetSnapshot = try await lastMetQuery.getDocuments()
            if let lastDoc = lastMetSnapshot.documents.first,
               let debrief = try? lastDoc.data(as: Debrief.self) {
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .abbreviated
                self.lastMetString = formatter.localizedString(for: debrief.occurredAt, relativeTo: Date())
            } else {
                self.lastMetString = "-"
            }
            
            // 3. Duration
            // We fetch ALL docs to calculate duration accurately.
            // WARNING: This downloads all documents. In production with 1000+ debriefs, this should be an aggregation query.
            if count > 0 {
                let allDocs = try await baseQuery.getDocuments()
                let totalDur = allDocs.documents.reduce(0.0) { sum, doc in
                    let dur = doc.data()["duration"] as? Double 
                        ?? Double(doc.data()["duration"] as? Int ?? 0)
                        ?? (doc.data()["audioDurationSec"] as? Double ?? 0)
                    return sum + dur
                }
                
                self.totalDurationMinutes = Int(totalDur / 60)
            } else {
                self.totalDurationMinutes = 0
            }
            
        } catch {
            print("❌ [ContactDetailViewModel] Stats Error: \(error)")
            self.error = AppError.from(error)
        }
    }
    
    // Quick Filters
    func setFilter(_ option: DateRangeOption) {
        filters.dateOption = option
    }
    
    func toggleActionItemsFilter() {
        // Need to add 'hasActionItems' to DebriefFilters struct if not present
        // Checking DebriefFilters.swift...
    }
}
