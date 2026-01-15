//
//  FirestoreService.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 15/01/2026.
//

import Foundation
import FirebaseFirestore

class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    
    private init() {}
    
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
            .order(by: "occurredAt", descending: true)
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
}
