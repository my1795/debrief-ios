//
//  HomeViewModel.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 13/01/2026.
//

import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var debriefs: [Debrief] = []
    @Published var searchQuery: String = ""
    @Published var filteredDebriefs: [Debrief] = []
    
    private let apiService = APIService.shared
    
    init() {
        Task {
            await fetchDebriefs()
        }
    }
    
    func fetchDebriefs() async {
        do {
            let fetchedDebriefs = try await apiService.getDebriefs()
            await MainActor.run {
                self.debriefs = fetchedDebriefs
                self.filterDebriefs()
            }
        } catch {
            print("Failed to fetch debriefs: \(error)")
        }
    }
    
    func filterDebriefs() {
        if searchQuery.isEmpty {
            filteredDebriefs = debriefs
        } else {
            filteredDebriefs = debriefs.filter { debrief in
                debrief.contactName.localizedCaseInsensitiveContains(searchQuery) ||
                (debrief.summary?.localizedCaseInsensitiveContains(searchQuery) ?? false)
            }
        }
        
        // Default sort: Recent
        filteredDebriefs.sort { $0.occurredAt > $1.occurredAt }
    }
    
    var stats: (today: Int, total: Int, totalMins: Int) {
        let totalCalls = debriefs.count
        let totalMins = Int(debriefs.reduce(0) { $0 + $1.duration } / 60)
        let today = debriefs.filter { Calendar.current.isDateInToday($0.occurredAt) }.count
        return (today, totalCalls, totalMins)
    }
}
