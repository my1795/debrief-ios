//
//  StatsService.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 14/01/2026.
//

import Foundation
import FirebaseAuth

protocol StatsServiceProtocol {
    func getCallsCount(start: Date, end: Date) async throws -> Int
    func getDebriefsCount(start: Date, end: Date) async throws -> Int
    func syncCalls(calls: [Int64]) async throws -> Int
}

class StatsService: StatsServiceProtocol {
    private let apiService: APIService
    private let firestoreService: FirestoreService
    private let contactStoreService: ContactStoreService
    private let session: URLSession
    private var baseURL: String { AppConfig.shared.apiBaseURL }
    
    init(apiService: APIService = .shared, firestoreService: FirestoreService = .shared, contactStoreService: ContactStoreService = .shared, session: URLSession = .shared) {
        self.apiService = apiService
        self.firestoreService = firestoreService
        self.contactStoreService = contactStoreService
        self.session = session
    }
    
    func getCallsCount(start: Date, end: Date) async throws -> Int {
        guard let userId = Auth.auth().currentUser?.uid else {
             // If no user, return 0 or throw. Returning 0 is safer for stats UI.
             return 0
        }
        return try await firestoreService.getCallsCount(userId: userId, start: start, end: end)
    }
    
    func getDebriefsCount(start: Date, end: Date) async throws -> Int {
        guard let userId = Auth.auth().currentUser?.uid else {
             return 0
        }
        return try await firestoreService.getDebriefsCount(userId: userId, start: start, end: end)
    }
    
    func syncCalls(calls: [Int64]) async throws -> Int {
        // Legacy/Direct conformance. We prefer syncPendingCalls()
        return try await syncPendingCalls()
    }
    
    // New Sync Method using Offline Storage
    func syncPendingCalls() async throws -> Int {
        let storage = CallStorageService.shared
        let pending = storage.getPendingCalls()
        
        guard !pending.isEmpty else { return 0 }
        
        Logger.sync("Syncing \(pending.count) calls...")
        
        let items = pending.map { record in
            CallSyncItem(
                timestamp: Int64(record.timestamp.timeIntervalSince1970 * 1000), // Millis
                durationSec: Int(record.duration)
            )
        }
        
        // Use CallSyncRequest struct from StatsModels
        let payload = CallSyncRequest(calls: items)
        
        guard let url = URL(string: "\(baseURL)/calls/sync") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add Firebase Auth token
        if let user = Auth.auth().currentUser {
            let token = try await user.getIDToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
             throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)
        }
        
        let result = try JSONDecoder().decode(CallSyncResponse.self, from: data)
        
        // Success -> Clear Storage
        storage.clearCalls(pending)
        Logger.success("Synced \(result.syncedCount) calls.")
        
        return result.syncedCount
    }
}
