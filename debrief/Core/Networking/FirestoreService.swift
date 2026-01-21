//
//  FirestoreService.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 15/01/2026.
//

import Foundation
import FirebaseFirestore
import Combine

class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    
    // Pagination Result Helper
    struct FetchResult {
        let debriefs: [Debrief]
        let lastDocument: DocumentSnapshot?
    }
    
    // MARK: - Cursor Pagination with Filters
    /// Fetches a page of debriefs starting after the given document cursor, optionally filtering by contact or date.
    func fetchDebriefs(userId: String, filters: DebriefFilters? = nil, limit: Int, startAfter: DocumentSnapshot?) async throws -> FetchResult {
        var query: Query = db.collection("debriefs")
            .whereField("userId", isEqualTo: userId)
        
        // Apply Contact Filter
        if let contactId = filters?.contactId, !contactId.isEmpty {
            query = query.whereField("contactId", isEqualTo: contactId)
        }
        
        // Apply Date Range Filter (Start)
        if let startDate = filters?.startDate {
            let startMs = Int64(startDate.timeIntervalSince1970 * 1000)
            query = query.whereField("occurredAt", isGreaterThanOrEqualTo: startMs)
        }
        
        // Apply Date Range Filter (End) - e.g. for Custom Range
        if let endDate = filters?.endDate {
            let endMs = Int64(endDate.timeIntervalSince1970 * 1000)
            query = query.whereField("occurredAt", isLessThan: endMs)
        }
        
        // Sorting
        // Firestore requires the first orderBy field to match the first whereField inequality
        // If we filter by occurredAt (date range), we must order by occurredAt first (which we do).
        // If we filter by contactId, we still want to sort by time.
        // Composite Index needed:
        // 1. userId + occurredAt DESC
        // 2. userId + contactId + occurredAt DESC
        
        query = query
            .order(by: "occurredAt", descending: true)
            .limit(to: limit)
            
        if let lastDoc = startAfter {
            query = query.start(afterDocument: lastDoc)
        }
        
        let snapshot = try await query.getDocuments()
        
        let debriefs = snapshot.documents.compactMap { document in
            try? document.data(as: Debrief.self)
        }
        
        // Decrypt if needed
        let decryptedDebriefs = decryptIfNeeded(debriefs, userId: userId)
        
        return FetchResult(debriefs: decryptedDebriefs, lastDocument: snapshot.documents.last)
    }
    
    // MARK: - Search Support (Fetch by IDs)
    
    /// Fetches debriefs by their IDs, typically after receiving search results from backend.
    /// Fetches in parallel and decrypts as needed.
    func fetchDebriefsByIds(_ ids: [String], userId: String) async throws -> [Debrief] {
        let isVerbose = AppConfig.shared.isVerboseLoggingEnabled
        
        guard !ids.isEmpty else { return [] }
        
        if isVerbose {
            print("🗄️ [FirestoreService.fetchDebriefsByIds] ========== FETCH ==========")
            print("🗄️ [FirestoreService.fetchDebriefsByIds] IDs to fetch: \(ids.count)")
            print("🗄️ [FirestoreService.fetchDebriefsByIds] IDs: \(ids.prefix(5).joined(separator: ", "))...")
        }
        
        // Fetch in parallel using TaskGroup
        let debriefs = try await withThrowingTaskGroup(of: Debrief?.self) { group in
            for id in ids {
                group.addTask {
                    let doc = try await self.db.collection("debriefs").document(id).getDocument()
                    return try? doc.data(as: Debrief.self)
                }
            }
            
            var results: [Debrief] = []
            for try await debrief in group {
                if let debrief = debrief {
                    results.append(debrief)
                }
            }
            return results
        }
        
        if isVerbose {
            print("🗄️ [FirestoreService.fetchDebriefsByIds] Fetched \(debriefs.count) / \(ids.count) debriefs")
            print("🗄️ [FirestoreService.fetchDebriefsByIds] Decrypting if needed...")
        }
        
        let result = decryptIfNeeded(debriefs, userId: userId)
        
        if isVerbose {
            print("✅ [FirestoreService.fetchDebriefsByIds] Complete. Returning \(result.count) decrypted debriefs")
        }
        
        return result
    }

    
    private init() {
        let settings = FirestoreSettings()
        settings.cacheSizeBytes = 100 * 1024 * 1024 // 100MB
        db.settings = settings
    }
    
    // MARK: - Debriefs Real-time Observation

    /// Snapshot listener result for debriefs - includes metadata for "load more"
    struct DebriefSnapshotResult {
        let debriefs: [Debrief]
        let hasMore: Bool
        let isFromCache: Bool
    }

    /// Observes debriefs collection with real-time updates and local caching.
    /// Uses Firestore's built-in cache for offline support and instant loading.
    ///
    /// - Parameters:
    ///   - userId: User ID for filtering
    ///   - filters: Optional filters (contact, date range)
    ///   - limit: Number of debriefs to fetch (increase for "load more")
    /// - Returns: Publisher that emits on every data change (cache or server)
    func observeDebriefs(
        userId: String,
        filters: DebriefFilters? = nil,
        limit: Int = AppConfig.shared.defaultPaginationLimit
    ) -> AnyPublisher<DebriefSnapshotResult, Error> {
        let subject = PassthroughSubject<DebriefSnapshotResult, Error>()

        var query: Query = db.collection("debriefs")
            .whereField("userId", isEqualTo: userId)

        // Apply Contact Filter
        if let contactId = filters?.contactId, !contactId.isEmpty {
            query = query.whereField("contactId", isEqualTo: contactId)
        }

        // Apply Date Range Filter (Start)
        if let startDate = filters?.startDate {
            let startMs = Int64(startDate.timeIntervalSince1970 * 1000)
            query = query.whereField("occurredAt", isGreaterThanOrEqualTo: startMs)
        }

        // Apply Date Range Filter (End)
        if let endDate = filters?.endDate {
            let endMs = Int64(endDate.timeIntervalSince1970 * 1000)
            query = query.whereField("occurredAt", isLessThan: endMs)
        }

        query = query
            .order(by: "occurredAt", descending: true)
            .limit(to: limit)

        let listener = query.addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("❌ [FirestoreService] Debriefs listener error: \(error)")
                subject.send(completion: .failure(error))
                return
            }

            guard let snapshot = snapshot else { return }

            let isFromCache = snapshot.metadata.isFromCache
            print("📡 [FirestoreService] Debriefs update - \(snapshot.documents.count) docs (cache: \(isFromCache))")

            let debriefs = snapshot.documents.compactMap { doc -> Debrief? in
                try? doc.data(as: Debrief.self)
            }

            // Decrypt if needed
            let decryptedDebriefs = self?.decryptIfNeeded(debriefs, userId: userId) ?? debriefs

            // hasMore = we got exactly the limit (might be more)
            let hasMore = snapshot.documents.count == limit

            subject.send(DebriefSnapshotResult(
                debriefs: decryptedDebriefs,
                hasMore: hasMore,
                isFromCache: isFromCache
            ))
        }

        return subject
            .handleEvents(receiveCancel: {
                print("🛑 [FirestoreService] Debriefs listener removed")
                listener.remove()
            })
            .eraseToAnyPublisher()
    }

    /// Observes daily stats with real-time updates
    func observeDailyStats(userId: String, date: Date) -> AnyPublisher<DailyStatsResult, Error> {
        let subject = PassthroughSubject<DailyStatsResult, Error>()

        let (startOfDay, endOfDay) = DateCalculator.dayBounds(for: date)
        let startMs = DateCalculator.toMilliseconds(startOfDay)
        let endMs = DateCalculator.toMilliseconds(endOfDay)

        let listener = db.collection("debriefs")
            .whereField("userId", isEqualTo: userId)
            .whereField("occurredAt", isGreaterThanOrEqualTo: startMs)
            .whereField("occurredAt", isLessThan: endMs)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    subject.send(completion: .failure(error))
                    return
                }

                guard let docs = snapshot?.documents else { return }

                // Calculate duration from debriefs
                let totalDuration = docs.reduce(0) { sum, doc in
                    let data = doc.data()
                    if let d = data["audioDurationSec"] as? Double { return sum + Int(d) }
                    if let d = data["audioDurationSec"] as? Int { return sum + d }
                    return sum
                }

                // Note: Calls count still needs separate query (different collection)
                // For simplicity, we'll fetch it once and not observe
                subject.send(DailyStatsResult(
                    debriefsCount: docs.count,
                    callsCount: 0, // Will be fetched separately
                    totalDurationSec: totalDuration
                ))
            }

        return subject
            .handleEvents(receiveCancel: {
                listener.remove()
            })
            .eraseToAnyPublisher()
    }

    // MARK: - Quota Observation (Real-time)

    /// Observes user_plans collection for real-time billing updates (NEW v2 system)
    func observeUserPlan(userId: String) -> AnyPublisher<UserPlan, Error> {
        let subject = PassthroughSubject<UserPlan, Error>()

        // user_plans document ID is the userId itself (planId == userId)
        let listener = db.collection("user_plans")
            .document(userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    subject.send(completion: .failure(error))
                    return
                }

                guard let document = snapshot, document.exists else {
                    print("⚠️ [FirestoreService] No user_plan found for \(userId)")
                    return
                }

                do {
                    let plan = try document.data(as: UserPlan.self)
                    subject.send(plan)
                } catch {
                    print("❌ [FirestoreService] Failed to decode UserPlan: \(error)")
                    subject.send(completion: .failure(error))
                }
            }

        return subject
            .handleEvents(receiveCancel: {
                listener.remove()
            })
            .eraseToAnyPublisher()
    }

    /// Legacy method - now wraps observeUserPlan for backward compatibility
    func observeQuota(userId: String) -> AnyPublisher<UserQuota, Error> {
        observeUserPlan(userId: userId)
            .map { plan in
                plan.toUserQuota()
            }
            .eraseToAnyPublisher()
    }

    /// Fetches user plan directly (NEW v2 system)
    func getUserPlan(userId: String) async throws -> UserPlan {
        let document = try await db.collection("user_plans")
            .document(userId)
            .getDocument()

        guard document.exists else {
            // Return default FREE plan if not found
            let now = Int64(Date().timeIntervalSince1970 * 1000)
            let weekEnd = now + (7 * 24 * 60 * 60 * 1000) // +7 days

            return UserPlan(
                planId: nil,
                userId: userId,
                tier: "FREE",
                billingWeekStart: now,
                billingWeekEnd: weekEnd,
                weeklyUsage: UserPlanWeeklyUsage(debriefCount: 0, totalSeconds: 0, actionItemsCount: 0, uniqueContactIds: []),
                usedStorageMB: 0,
                subscriptionEnd: nil,
                createdAt: now,
                updatedAt: now
            )
        }

        return try document.data(as: UserPlan.self)
    }

    /// Legacy method - now wraps getUserPlan for backward compatibility
    func getUserQuota(userId: String) async throws -> UserQuota {
        let plan = try await getUserPlan(userId: userId)
        return plan.toUserQuota()
    }
    // MARK: - Convenience Fetch Methods (use main fetchDebriefs internally)
    
    /// Fetch all debriefs for a user (no pagination, no filters)
    /// Use sparingly - prefer paginated fetch for large datasets
    func fetchAllDebriefs(userId: String) async throws -> [Debrief] {
        var allDebriefs: [Debrief] = []
        var lastDoc: DocumentSnapshot? = nil
        var hasMore = true
        
        while hasMore {
            let result = try await fetchDebriefs(
                userId: userId,
                filters: nil,
                limit: 100,
                startAfter: lastDoc
            )
            allDebriefs.append(contentsOf: result.debriefs)
            lastDoc = result.lastDocument
            hasMore = result.debriefs.count == 100
        }
        
        return allDebriefs
    }
    
    /// Fetch debriefs within a date range (for stats calculations)
    func fetchDebriefs(userId: String, start: Date, end: Date) async throws -> [Debrief] {
        var filters = DebriefFilters()
        filters.dateOption = .custom
        filters.customStartDate = start
        filters.customEndDate = end
        
        // Fetch all within range (no pagination limit for stats)
        var allDebriefs: [Debrief] = []
        var lastDoc: DocumentSnapshot? = nil
        var hasMore = true
        
        while hasMore {
            let result = try await fetchDebriefs(
                userId: userId,
                filters: filters,
                limit: 100,
                startAfter: lastDoc
            )
            allDebriefs.append(contentsOf: result.debriefs)
            lastDoc = result.lastDocument
            hasMore = result.debriefs.count == 100
        }
        
        return allDebriefs
    }
    
    func getDebrief(userId: String, debriefId: String) async throws -> Debrief {
        let document = try await db.collection("debriefs")
            .document(debriefId)
            .getDocument()
        
        guard let debrief = try? document.data(as: Debrief.self) else {
            throw NSError(domain: "FirestoreService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Debrief not found or decode failed"])
        }
        
        // Security check: Ensure the debrief belongs to the requesting user
        guard debrief.userId == userId else {
            throw NSError(domain: "FirestoreService", code: 403, userInfo: [NSLocalizedDescriptionKey: "Unauthorized access to debrief"])
        }
        
        // Decrypt if needed
        return decryptIfNeeded(debrief, userId: userId)
    }
    
    // MARK: - Real-time Debrief Observation
    
    func listenToDebrief(debriefId: String, completion: @escaping (Result<Debrief, Error>) -> Void) -> ListenerRegistration {
        return db.collection("debriefs")
            .document(debriefId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let document = snapshot, document.exists else {
                    completion(.failure(NSError(domain: "FirestoreService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Document does not exist"])))
                    return
                }
                
                do {
                    var debrief = try document.data(as: Debrief.self)
                    
                    // Decrypt if needed (using the debrief's userId)
                    debrief = self.decryptIfNeeded(debrief, userId: debrief.userId)
                    
                    completion(.success(debrief))
                } catch {
                    print("❌ [FirestoreService] Failed to decode debrief update: \(error)")
                    completion(.failure(error))
                }
            }
    }
    
    func getDebriefsCount(userId: String, start: Date, end: Date) async throws -> Int {
        // Backend stores times as Int64 milliseconds (e.g. 1768341426596)
        // We must query using Numbers, not Dates/Timestamps.
        let startMs = Int64(start.timeIntervalSince1970 * 1000)
        let endMs = Int64(end.timeIntervalSince1970 * 1000)
        
        let countQuery = db.collection("debriefs")
            .whereField("userId", isEqualTo: userId)
            .whereField("occurredAt", isGreaterThanOrEqualTo: startMs)
            .whereField("occurredAt", isLessThan: endMs)
            .count
        
        let snapshot = try await countQuery.getAggregation(source: AggregateSource.server)
        return Int(truncating: snapshot.count)
    }
    
    func getCallsCount(userId: String, start: Date, end: Date) async throws -> Int {
        // Backend stores times as Int64 milliseconds
        let startMs = Int64(start.timeIntervalSince1970 * 1000)
        let endMs = Int64(end.timeIntervalSince1970 * 1000)
        
        let countQuery = db.collection("calls")
            .whereField("userId", isEqualTo: userId)
            .whereField("callTimestamp", isGreaterThanOrEqualTo: startMs)
            .whereField("callTimestamp", isLessThan: endMs)
            .count
        
        let snapshot = try await countQuery.getAggregation(source: AggregateSource.server)
        return Int(truncating: snapshot.count)
    }
    // MARK: - Daily Stats (Consolidated)
    
    /// Result type for daily stats - batches 3 separate queries into 1
    struct DailyStatsResult {
        let debriefsCount: Int
        let callsCount: Int
        let totalDurationSec: Int
    }
    
    /// Fetches daily stats with a single Firestore query for debriefs + count query for calls
    /// Replaces 3 separate calls with 2 (debriefs data + calls count)
    func getDailyStats(userId: String, date: Date) async throws -> DailyStatsResult {
        let (startOfDay, endOfDay) = DateCalculator.dayBounds(for: date)
        let startMs = DateCalculator.toMilliseconds(startOfDay)
        let endMs = DateCalculator.toMilliseconds(endOfDay)
        
        // Fetch debriefs for the day (we need docs to sum duration)
        async let debriefsSnapshot = db.collection("debriefs")
            .whereField("userId", isEqualTo: userId)
            .whereField("occurredAt", isGreaterThanOrEqualTo: startMs)
            .whereField("occurredAt", isLessThan: endMs)
            .getDocuments()
        
        // Fetch calls count (separate collection)
        async let callsCountQuery = db.collection("calls")
            .whereField("userId", isEqualTo: userId)
            .whereField("callTimestamp", isGreaterThanOrEqualTo: startMs)
            .whereField("callTimestamp", isLessThan: endMs)
            .count
            .getAggregation(source: .server)
        
        let (debriefsDocs, callsAgg) = try await (debriefsSnapshot, callsCountQuery)
        
        // Calculate duration from debriefs (audioDurationSec is the backend field name)
        let totalDuration = debriefsDocs.documents.reduce(0) { sum, doc in
            let data = doc.data()
            if let d = data["audioDurationSec"] as? Double { return sum + Int(d) }
            if let d = data["audioDurationSec"] as? Int { return sum + d }
            return sum
        }
        
        return DailyStatsResult(
            debriefsCount: debriefsDocs.documents.count,
            callsCount: Int(truncating: callsAgg.count),
            totalDurationSec: totalDuration
        )
    }
    
    // MARK: - Server-Side Stats Aggregations
    
    func getTotalDuration(userId: String, start: Date, end: Date) async throws -> Int {
        let startMs = Int64(start.timeIntervalSince1970 * 1000)
        let endMs = Int64(end.timeIntervalSince1970 * 1000)
        
        let snapshot = try await db.collection("debriefs")
            .whereField("userId", isEqualTo: userId)
            .whereField("occurredAt", isGreaterThanOrEqualTo: startMs)
            .whereField("occurredAt", isLessThan: endMs)
            .getDocuments()
        
        // Manual Summation - audioDurationSec is the backend field name
        let totalSeconds = snapshot.documents.reduce(0.0) { sum, doc in
            let data = doc.data()
            var duration: Double = 0

            if let d = data["audioDurationSec"] as? Double {
                duration = d
            } else if let d = data["audioDurationSec"] as? Int {
                duration = Double(d)
            }
            
            return sum + duration
        }
        
        return Int(totalSeconds)
    }
    
    // Efficient fetch for Action Items (Client-side sum of array lengths, Server-side fetch of only array)
    func getActionItemsStats(userId: String, start: Date, end: Date) async throws -> Int {
        let startMs = Int64(start.timeIntervalSince1970 * 1000)
        let endMs = Int64(end.timeIntervalSince1970 * 1000)
        
        // Fetch only actionItems field (Using a custom projection DTO implies fetch entire doc in swift standard codable, 
        // but Dictionary decoding is safer for partial data)
        let snapshot = try await db.collection("debriefs")
            .whereField("userId", isEqualTo: userId)
            .whereField("occurredAt", isGreaterThanOrEqualTo: startMs)
            .whereField("occurredAt", isLessThan: endMs)
            .getDocuments()
            
        // "Lean" processing: We assume the SDK might still fetch the doc, but we process only what we need.
        // True "FieldMask" support in Swift SDK is limited for `getDocuments()`.
        // However, this avoids decoding the huge "transcript" string if we use dictionary access.
        
        let totalActionItems = snapshot.documents.reduce(0) { sum, doc in
            let items = doc.data()["actionItems"] as? [String] ?? []
            return sum + items.count
        }
        
        return totalActionItems
    }
    
    // Efficient fetch for Unique Contacts
    func getUniqueContactsStats(userId: String, start: Date, end: Date) async throws -> Int {
        let startMs = Int64(start.timeIntervalSince1970 * 1000)
        let endMs = Int64(end.timeIntervalSince1970 * 1000)
        
        let snapshot = try await db.collection("debriefs")
            .whereField("userId", isEqualTo: userId)
            .whereField("occurredAt", isGreaterThanOrEqualTo: startMs)
            .whereField("occurredAt", isLessThan: endMs)
            .getDocuments()
        
        let uniqueContacts = Set(snapshot.documents.compactMap { doc -> String? in
            let cid = doc.data()["contactId"] as? String
            return (cid?.isEmpty == false) ? cid : nil
        })
        
        return uniqueContacts.count
    }
    
    // MARK: - Aggregation-Only Stats (No Document Fetch)

    /// Lightweight stats struct for aggregation-only queries
    struct WeeklyStatsAggregation {
        let count: Int
        let duration: Int
    }

    /// Fetches weekly stats using ONLY Firestore aggregation (no document download)
    /// Use this for previous week trends where actionItems/contacts aren't needed
    func getWeeklyStatsAggregationOnly(userId: String, start: Date, end: Date) async throws -> WeeklyStatsAggregation {
        let startMs = Int64(start.timeIntervalSince1970 * 1000)
        let endMs = Int64(end.timeIntervalSince1970 * 1000)

        let baseQuery = db.collection("debriefs")
            .whereField("userId", isEqualTo: userId)
            .whereField("occurredAt", isGreaterThanOrEqualTo: startMs)
            .whereField("occurredAt", isLessThan: endMs)

        // Run ONLY aggregation queries - no document download
        async let countTask = baseQuery.count.getAggregation(source: .server)
        async let sumTask = baseQuery.aggregate([AggregateField.sum("audioDurationSec")]).getAggregation(source: .server)

        let (countSnapshot, sumSnapshot) = try await (countTask, sumTask)

        let count = Int(countSnapshot.count)
        let totalDuration: Int
        if let sumValue = sumSnapshot.get(AggregateField.sum("audioDurationSec")) as? NSNumber {
            totalDuration = sumValue.intValue
        } else {
            totalDuration = 0
        }

        return WeeklyStatsAggregation(count: count, duration: totalDuration)
    }

    // MARK: - Consolidated Weekly Stats

    /// Fetches weekly stats using Firestore aggregation for optimal performance
    /// - count: Uses count aggregation (no document download)
    /// - duration: Uses sum aggregation (no document download)
    /// - actionItems/uniqueContacts: Requires document fetch (minimized fields)
    func getWeeklyStats(userId: String, start: Date, end: Date) async throws -> WeeklyStats {
        let startMs = Int64(start.timeIntervalSince1970 * 1000)
        let endMs = Int64(end.timeIntervalSince1970 * 1000)

        let baseQuery = db.collection("debriefs")
            .whereField("userId", isEqualTo: userId)
            .whereField("occurredAt", isGreaterThanOrEqualTo: startMs)
            .whereField("occurredAt", isLessThan: endMs)

        // Run aggregation queries in parallel - these don't download documents
        async let countTask = baseQuery.count.getAggregation(source: .server)
        async let sumTask = baseQuery.aggregate([AggregateField.sum("audioDurationSec")]).getAggregation(source: .server)

        // For actionItems and uniqueContacts, we need document data
        // Fetch in parallel with aggregations
        async let docsTask = baseQuery.getDocuments()

        let (countSnapshot, sumSnapshot, docsSnapshot) = try await (countTask, sumTask, docsTask)

        // Extract aggregation results
        let count = Int(countSnapshot.count)
        let totalDuration: Double
        if let sumValue = sumSnapshot.get(AggregateField.sum("audioDurationSec")) as? NSNumber {
            totalDuration = sumValue.doubleValue
        } else {
            totalDuration = 0
        }

        // Process actionItems and uniqueContacts on background thread
        let (actionItems, uniqueContacts) = await Task.detached(priority: .userInitiated) {
            var totalActionItems = 0
            var contactIds = Set<String>()

            for doc in docsSnapshot.documents {
                let data = doc.data()

                if let items = data["actionItems"] as? [String] {
                    totalActionItems += items.count
                }

                if let cid = data["contactId"] as? String, !cid.isEmpty {
                    contactIds.insert(cid)
                }
            }

            return (totalActionItems, contactIds.count)
        }.value

        return WeeklyStats(
            count: count,
            duration: Int(totalDuration),
            actionItems: actionItems,
            uniqueContacts: uniqueContacts
        )
    }
    
    // MARK: - Encryption Support
    
    // MARK: - Encryption Support
    
    /// Decrypts encrypted fields in a Debrief if encryption key is available.
    /// Strict V1: Only decrypts if encryptionVersion == "v1" or encrypted == true.
    /// Does NOT sniff text content.
    func decryptIfNeeded(_ debrief: Debrief, userId: String) -> Debrief {
        // Check strict encryption flag/version
        // If data is old/legacy without version but encrypted=true, we try V1 decrypt (Base64)
        // because strict V1 EncryptionService expects valid Base64.
        let needsDecryption = debrief.encryptionVersion == "v1" || debrief.encrypted
        
        guard needsDecryption else {
            return debrief
        }
        
        // Get encryption key
        guard let key = EncryptionKeyManager.shared.getKey(userId: userId) else {
            print("⚠️ [FirestoreService] No encryption key available for decryption")
            return debrief
        }
        
        let encryptionService = EncryptionService.shared
        
        // Helper to decrypt safely
        func decrypt(_ text: String?) -> String? {
            guard let text = text, !text.isEmpty else { return nil }
            return (try? encryptionService.decrypt(text, using: key)) ?? text
        }
        
        // Decrypt fields
        let decryptedSummary = decrypt(debrief.summary)
        let decryptedTranscript = decrypt(debrief.transcript)
        let decryptedActionItems = debrief.actionItems?.map { decrypt($0) ?? $0 }
        
        // Return new Debrief with decrypted values
        return Debrief(
            id: debrief.id,
            userId: debrief.userId,
            contactId: debrief.contactId,
            contactName: debrief.contactName,
            occurredAt: debrief.occurredAt,
            duration: debrief.duration,
            status: debrief.status,
            summary: decryptedSummary,
            transcript: decryptedTranscript,
            actionItems: decryptedActionItems,
            audioUrl: debrief.audioUrl,
            audioStoragePath: debrief.audioStoragePath,
            encrypted: false, // Mark as decrypted locally
            encryptionVersion: debrief.encryptionVersion, // Keep version info
            phoneNumber: debrief.phoneNumber,
            email: debrief.email
        )
    }
    
    /// Decrypts an array of debriefs.
    func decryptIfNeeded(_ debriefs: [Debrief], userId: String) -> [Debrief] {
        return debriefs.map { decryptIfNeeded($0, userId: userId) }
    }
    
    // MARK: - Contact Name Update
    
    /// Updates the contactName field in Firebase for a debrief.
    /// Called when contact is matched by phone/email and we want to persist the resolved name.
    func updateDebriefContactName(debriefId: String, contactName: String) async throws {
        try await db.collection("debriefs")
            .document(debriefId)
            .updateData(["contactName": contactName])
        
        print("✅ [FirestoreService] Updated contactName for \(debriefId) to '\(contactName)'")
    }
    
    // MARK: - Action Items Update
    
    /// Updates action items for a debrief with encryption.
    /// - Parameters:
    ///   - debriefId: The debrief document ID
    ///   - actionItems: The new action items (plaintext)
    ///   - userId: The user ID for encryption key lookup
    func updateActionItems(debriefId: String, actionItems: [String], userId: String) async throws {
        let encryptionService = EncryptionService.shared
        
        // Get encryption key
        var finalItems = actionItems
        var isEncrypted = false
        
        if let key = EncryptionKeyManager.shared.getKey(userId: userId) {
            // Encrypt each action item strictly
            do {
                finalItems = try actionItems.map { item in
                    try encryptionService.encrypt(item, using: key)
                }
                isEncrypted = true
                print("🔐 [FirestoreService] Encrypted \(finalItems.count) action items (V1)")
            } catch {
                print("❌ [FirestoreService] Failed to encrypt action items: \(error). Aborting update.")
                throw error
            }
        } else {
            print("⚠️ [FirestoreService] No encryption key, saving plaintext")
        }
        
        // Update Firebase
        var updateData: [String: Any] = [
            "actionItems": finalItems,
            "encrypted": isEncrypted
        ]
        
        if isEncrypted {
            updateData["encryptionVersion"] = "v1"
        }
        
        try await db.collection("debriefs")
            .document(debriefId)
            .updateData(updateData)
        
        print("✅ [FirestoreService] Updated action items for \(debriefId)")
    }
}
