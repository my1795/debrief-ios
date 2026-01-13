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
    
    init() {
        loadMockData()
    }
    
    func loadMockData() {
        // Mock Data
        self.debriefs = [
            Debrief(id: "1", contactName: "Ahmet - TechCorp", occurredAt: Date(), duration: 1800, status: .ready, summary: "Discussed project roadmap and timeline for Q1.", transcript: nil, actionItems: ["Send proposal", "Update Jira"]),
            Debrief(id: "2", contactName: "Sarah - Design", occurredAt: Date().addingTimeInterval(-86400), duration: 1200, status: .processing, summary: "Reviewing new UI mockups for the landing page.", transcript: nil, actionItems: []),
            Debrief(id: "3", contactName: "Mehmet - Engineer", occurredAt: Date().addingTimeInterval(-172800), duration: 600, status: .draft, summary: nil, transcript: nil, actionItems: nil)
        ]
        filterDebriefs()
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
