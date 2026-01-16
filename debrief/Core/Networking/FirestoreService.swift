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
    
    private init() {}
    
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
    func fetchDebriefs(userId: String) async throws -> [Debrief] {
        let snapshot = try await db.collection("debriefs")
            .whereField("userId", isEqualTo: userId)
            // .order(by: "occurredAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            do {
                return try document.data(as: Debrief.self)
            } catch {
                print("❌ [FirestoreService] Failed to decode debrief (ID: \(document.documentID)): \(error)")
                return nil
            }
        }
    }
    
    func fetchDebriefs(userId: String, contactId: String) async throws -> [Debrief] {
        let snapshot = try await db.collection("debriefs")
            .whereField("userId", isEqualTo: userId)
            .whereField("contactId", isEqualTo: contactId)
            // .order(by: "occurredAt", descending: true) // Removed to avoid composite index requirement
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: Debrief.self)
        }
    }
    
    // Added for Stats Refactor
    func fetchDebriefs(userId: String, start: Date, end: Date) async throws -> [Debrief] {
        let startMs = Int64(start.timeIntervalSince1970 * 1000)
        let endMs = Int64(end.timeIntervalSince1970 * 1000)
        
        let snapshot = try await db.collection("debriefs")
            .whereField("userId", isEqualTo: userId)
            .whereField("occurredAt", isGreaterThanOrEqualTo: startMs)
            .whereField("occurredAt", isLessThan: endMs)
            .getDocuments()
            
        return snapshot.documents.compactMap { document in
             try? document.data(as: Debrief.self)
        }
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
    }
}
