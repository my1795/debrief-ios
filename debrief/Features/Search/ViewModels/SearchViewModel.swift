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
    private var isVerbose: Bool { AppConfig.shared.isVerboseLoggingEnabled }
    
    init() {
        setupSearchSubscription()
        if isVerbose {
            print("🔍 [SearchViewModel] Initialized - Verbose logging enabled")
        }
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
        guard query.count >= 3 else {
            if isVerbose {
                print("🔍 [SearchViewModel] Query too short (\(query.count) chars), skipping")
            }
            return
        }
        
        if isVerbose {
            print("🔍 [SearchViewModel] ========== SEARCH START ==========")
            print("🔍 [SearchViewModel] Query: \"\(query)\"")
        }
        
        isLoading = true
        error = nil
        
        do {
            guard let userId = Auth.auth().currentUser?.uid else {
                if isVerbose {
                    print("❌ [SearchViewModel] No authenticated user!")
                }
                isLoading = false
                return
            }
            
            // Step 1: Call backend search API
            if isVerbose {
                print("🔍 [SearchViewModel] Step 1: Calling backend search API...")
            }
            
            let startTime = Date()
            let searchResults = try await APIService.shared.searchDebriefs(query: query, limit: 10)
            
            if isVerbose {
                let elapsed = Date().timeIntervalSince(startTime)
                print("🔍 [SearchViewModel] Backend search completed in \(String(format: "%.2f", elapsed))s")
                print("🔍 [SearchViewModel] Results from backend: \(searchResults.count)")
            }
            
            guard !searchResults.isEmpty else {
                if isVerbose {
                    print("🔍 [SearchViewModel] No results from backend, returning empty")
                }
                self.searchResults = []
                isLoading = false
                return
            }
            
            // Step 2: Fetch debriefs by IDs from Firestore
            if isVerbose {
                print("🔍 [SearchViewModel] Step 2: Fetching debriefs by IDs from Firestore...")
            }
            
            let debriefIds = searchResults.map { $0.debriefId }
            let fetchStart = Date()
            let debriefs = try await FirestoreService.shared.fetchDebriefsByIds(debriefIds, userId: userId)
            
            if isVerbose {
                let fetchElapsed = Date().timeIntervalSince(fetchStart)
                print("🔍 [SearchViewModel] Firestore fetch completed in \(String(format: "%.2f", fetchElapsed))s")
                print("🔍 [SearchViewModel] Fetched \(debriefs.count) debriefs")
            }
            
            // Step 3: Sort by similarity (preserving backend order)
            // Create a lookup for similarity scores
            let similarityMap = Dictionary(uniqueKeysWithValues: searchResults.map { ($0.debriefId, $0.similarity) })
            
            // Sort debriefs by similarity (highest first)
            let sortedDebriefs = debriefs.sorted { debrief1, debrief2 in
                let sim1 = similarityMap[debrief1.id] ?? 0
                let sim2 = similarityMap[debrief2.id] ?? 0
                return sim1 > sim2
            }
            
            if isVerbose {
                print("🔍 [SearchViewModel] ========== SEARCH COMPLETE ==========")
                print("🔍 [SearchViewModel] Final results: \(sortedDebriefs.count)")
                for (index, debrief) in sortedDebriefs.prefix(3).enumerated() {
                    let similarity = similarityMap[debrief.id] ?? 0
                    let summaryPreview = String(debrief.summary?.prefix(40) ?? "N/A")
                    print("🔍 [SearchViewModel] \(index + 1). [\(String(format: "%.2f", similarity))] \(debrief.contactName): \(summaryPreview)...")
                }
            }
            
            self.searchResults = sortedDebriefs
            
        } catch {
            print("❌ [SearchViewModel] Search failed: \(error)")
            if isVerbose {
                print("❌ [SearchViewModel] Error details: \(error.localizedDescription)")
            }
            self.error = error
        }
        
        isLoading = false
    }
}
