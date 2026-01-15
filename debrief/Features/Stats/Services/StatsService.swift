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
        guard let url = URL(string: "\(baseURL)/calls/sync") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["calls": calls]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)
        }
        
        struct SyncResponse: Codable {
            let syncedCount: Int
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(SyncResponse.self, from: data)
        return result.syncedCount
    }
}
