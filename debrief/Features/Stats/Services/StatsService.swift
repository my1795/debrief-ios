//
//  StatsService.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 14/01/2026.
//

import Foundation

protocol StatsServiceProtocol {
    func getOverview() async throws -> OverviewResponse
}

class StatsService: StatsServiceProtocol {
    private let apiService: APIService
    private let contactStoreService: ContactStoreService
    
    init(apiService: APIService = .shared, contactStoreService: ContactStoreService = .shared) {
        self.apiService = apiService
        self.contactStoreService = contactStoreService
    }
    
    func getOverview() async throws -> OverviewResponse {
        return try await apiService.getStatsOverview()
    }
}
