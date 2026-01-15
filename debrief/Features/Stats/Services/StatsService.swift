//
//  StatsService.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 14/01/2026.
//

import Foundation

protocol StatsServiceProtocol {
    func getOverview() async throws -> OverviewResponse
    func getCallsCount(start: Date, end: Date) async throws -> Int
    func getDebriefsCount(start: Date, end: Date) async throws -> Int
    func syncCalls(calls: [Int64]) async throws -> Int
}

class StatsService: StatsServiceProtocol {
    private let apiService: APIService
    private let contactStoreService: ContactStoreService
    private let session: URLSession
    private let baseURL = "http://localhost:8080/v1" // Align with APIService
    
    init(apiService: APIService = .shared, contactStoreService: ContactStoreService = .shared, session: URLSession = .shared) {
        self.apiService = apiService
        self.contactStoreService = contactStoreService
        self.session = session
    }
    
    func getOverview() async throws -> OverviewResponse {
        return try await apiService.getStatsOverview()
    }
    
    func getCallsCount(start: Date, end: Date) async throws -> Int {
        let startMs = Int64(start.timeIntervalSince1970 * 1000)
        let endMs = Int64(end.timeIntervalSince1970 * 1000)
        
        guard let url = URL(string: "\(baseURL)/calls/count?start=\(startMs)&end=\(endMs)") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(CallCountResponse.self, from: data)
        return result.count
    }
    
    func getDebriefsCount(start: Date, end: Date) async throws -> Int {
        let startMs = Int64(start.timeIntervalSince1970 * 1000)
        let endMs = Int64(end.timeIntervalSince1970 * 1000)
        
        guard let url = URL(string: "\(baseURL)/debriefs/count?start=\(startMs)&end=\(endMs)") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(DebriefCountResponse.self, from: data)
        return result.count
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
        
        print("🔄 [StatsService] Syncing \(pending.count) calls...")
        
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
        
        // Add Auth Token (Assuming simple Bearer if managed, or relying on session cookies/headers handled by APIService)
        // Since we are using raw URLSession here, we might miss Auth if APIService injects it.
        // Let's try to get headers from APIService if possible, or assume session handles it.
        // For now, sticking to raw request as per existing pattern in this file,
        // BUT assuming headers might be needed.
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
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
        print("✅ [StatsService] Synced \(result.syncedCount) calls.")
        
        return result.syncedCount
    }
}
