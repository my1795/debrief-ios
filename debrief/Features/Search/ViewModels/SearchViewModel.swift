//
//  SearchViewModel.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 19/01/2026.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var searchResults: [Debrief] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupSearchSubscription()
        Logger.debug("SearchViewModel initialized")
    }
    
    private func setupSearchSubscription() {
        $searchText
            .debounce(for: .seconds(0.8), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                Task {
                    await self?.performSearch(query: query)
                }
            }
            .store(in: &cancellables)
    }
    
    private func performSearch(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        // Minimum length check to avoid low quality queries
        guard query.count >= AppConfig.shared.minimumSearchQueryLength else {
            Logger.debug("Query too short (\(query.count) chars), skipping")
            return
        }

        Logger.debug("========== SEARCH START ==========")
        Logger.debug("Query: \"\(query)\"")
        
        isLoading = true
        error = nil
        
        do {
            guard let userId = Auth.auth().currentUser?.uid else {
                Logger.error("No authenticated user!")
                isLoading = false
                return
            }

            // Step 1: Call backend search API
            Logger.debug("Step 1: Calling backend search API...")

            let startTime = Date()
            let searchResults = try await APIService.shared.searchDebriefs(query: query, limit: 10)

            let elapsed = Date().timeIntervalSince(startTime)
            Logger.debug("Backend search completed in \(String(format: "%.2f", elapsed))s")
            Logger.debug("Results from backend: \(searchResults.count)")

            guard !searchResults.isEmpty else {
                Logger.debug("No results from backend, returning empty")
                self.searchResults = []
                isLoading = false
                return
            }

            // Step 2: Fetch debriefs by IDs from Firestore
            Logger.debug("Step 2: Fetching debriefs by IDs from Firestore...")

            let debriefIds = searchResults.map { $0.debriefId }
            let fetchStart = Date()
            let debriefs = try await FirestoreService.shared.fetchDebriefsByIds(debriefIds, userId: userId)

            let fetchElapsed = Date().timeIntervalSince(fetchStart)
            Logger.debug("Firestore fetch completed in \(String(format: "%.2f", fetchElapsed))s")
            Logger.debug("Fetched \(debriefs.count) debriefs")
            
            // Step 3: Sort by similarity (preserving backend order)
            // Create a lookup for similarity scores
            let similarityMap = Dictionary(uniqueKeysWithValues: searchResults.map { ($0.debriefId, $0.similarity) })
            
            // Sort debriefs by similarity (highest first)
            let sortedDebriefs = debriefs.sorted { debrief1, debrief2 in
                let sim1 = similarityMap[debrief1.id] ?? 0
                let sim2 = similarityMap[debrief2.id] ?? 0
                return sim1 > sim2
            }
            
            Logger.debug("========== SEARCH COMPLETE ==========")
            Logger.debug("Final results: \(sortedDebriefs.count)")
            for (index, debrief) in sortedDebriefs.prefix(3).enumerated() {
                let similarity = similarityMap[debrief.id] ?? 0
                let summaryPreview = String(debrief.summary?.prefix(40) ?? "N/A")
                Logger.debug("\(index + 1). [\(String(format: "%.2f", similarity))] \(debrief.contactName): \(summaryPreview)...")
            }

            self.searchResults = sortedDebriefs

        } catch {
            Logger.error("Search failed: \(error)")
            Logger.error("Error details: \(error.localizedDescription)")
            self.error = error
        }
        
        isLoading = false
    }
}
