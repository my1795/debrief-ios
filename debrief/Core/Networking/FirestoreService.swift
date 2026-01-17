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
        
        return FetchResult(debriefs: debriefs, lastDocument: snapshot.documents.last)
    }
    
    private init() {
        let settings = FirestoreSettings()
        settings.cacheSizeBytes = 100 * 1024 * 1024 // 100MB
        db.settings = settings
    }
    
    // MARK: - Quota Observation (Real-time)
    
    func observeQuota(userId: String) -> AnyPublisher<UserQuota, Error> {
        let subject = PassthroughSubject<UserQuota, Error>()
        
        let listener = db.collection("user_quotas")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    subject.send(completion: .failure(error))
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    return
                }
                
                print("🔍 [FirestoreService] Quota Document ID: \(document.documentID)")
                
                do {
                    let quota = try document.data(as: UserQuota.self)
                    subject.send(quota)
                } catch {
                    subject.send(completion: .failure(error))
                }
            }
        
        return subject
            .handleEvents(receiveCancel: {
                listener.remove()
            })
            .eraseToAnyPublisher()
    }
    
    // One-shot fetch for quota logic (e.g. checks after recording)
    func getUserQuota(userId: String) async throws -> UserQuota {
        let snapshot = try await db.collection("user_quotas")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        guard let doc = snapshot.documents.first else {
            // Return default/mock if not found
            // Correct order based on struct definition:
            // userId, subscriptionTier, weeklyDebriefs, weeklyRecordingMinutes, storageLimitMB, usedDebriefs, usedRecordingSeconds, usedStorageMB, currentPeriodStart, currentPeriodEnd
            return UserQuota(
                userId: userId,
                subscriptionTier: "Free",
                weeklyDebriefs: 5,
                weeklyRecordingMinutes: 10,
                storageLimitMB: 500,
                usedDebriefs: 0,
                usedRecordingSeconds: 0,
                usedStorageMB: 0,
                currentPeriodStart: nil,
                currentPeriodEnd: nil
            )
        }
        
        return try doc.data(as: UserQuota.self)
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
        
        return debrief
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
                    let debrief = try document.data(as: Debrief.self)
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
            .whereField("timestamp", isGreaterThanOrEqualTo: startMs)
            .whereField("timestamp", isLessThan: endMs)
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
            .whereField("timestamp", isGreaterThanOrEqualTo: startMs)
            .whereField("timestamp", isLessThan: endMs)
            .count
            .getAggregation(source: .server)
        
        let (debriefsDocs, callsAgg) = try await (debriefsSnapshot, callsCountQuery)
        
        // Calculate duration from debriefs
        let totalDuration = debriefsDocs.documents.reduce(0) { sum, doc in
            let data = doc.data()
            if let d = data["duration"] as? Double { return sum + Int(d) }
            if let d = data["duration"] as? Int { return sum + d }
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
        
        // Manual Summation for Robustness
        // Backend might have `duration` OR `audioDurationSec` (legacy).
        // Server-side aggregate only sums one field. Client-side processing covers both.
        // We access the dictionary directly to avoid full object coding cost.
        let totalSeconds = snapshot.documents.reduce(0.0) { sum, doc in
            let data = doc.data()
            var duration: Double = 0
            
            if let d = data["duration"] as? Double {
                duration = d
            } else if let d = data["duration"] as? Int { // Handle Int storage
                duration = Double(d)
            } else if let d = data["audioDurationSec"] as? Double {
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
    
    // MARK: - Consolidated Weekly Stats
    
    /// Fetches all weekly stats in a single optimized query
    func getWeeklyStats(userId: String, start: Date, end: Date) async throws -> WeeklyStats {
        let startMs = Int64(start.timeIntervalSince1970 * 1000)
        let endMs = Int64(end.timeIntervalSince1970 * 1000)
        
        let snapshot = try await db.collection("debriefs")
            .whereField("userId", isEqualTo: userId)
            .whereField("occurredAt", isGreaterThanOrEqualTo: startMs)
            .whereField("occurredAt", isLessThan: endMs)
            .getDocuments()
        
        // Process on background thread to avoid Main Thread hang with 10k+ items
        return try await Task.detached(priority: .userInitiated) {
            var totalDuration: Double = 0
            var totalActionItems = 0
            var contactIds = Set<String>()
            
            for doc in snapshot.documents {
                let data = doc.data()
                
                // Duration
                if let d = data["duration"] as? Double {
                    totalDuration += d
                } else if let d = data["duration"] as? Int {
                    totalDuration += Double(d)
                } else if let d = data["audioDurationSec"] as? Double {
                    totalDuration += d
                } else if let d = data["audioDurationSec"] as? Int {
                    totalDuration += Double(d)
                }
                
                // Action Items
                if let items = data["actionItems"] as? [String] {
                    totalActionItems += items.count
                }
                
                // Unique Contacts
                if let cid = data["contactId"] as? String, !cid.isEmpty {
                    contactIds.insert(cid)
                }
            }
            
            return WeeklyStats(
                count: snapshot.documents.count,
                duration: Int(totalDuration),
                actionItems: totalActionItems,
                uniqueContacts: contactIds.count
            )
        }.value
    }
}
