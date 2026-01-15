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
    private let contactStoreService: ContactStoreServiceProtocol
    
    init(contactStoreService: ContactStoreServiceProtocol = ContactStoreService()) {
        self.contactStoreService = contactStoreService
        Task {
            await fetchDebriefs()
        }
    }
    
    func fetchDebriefs() async {
        do {
            let fetchedDebriefs = try await apiService.getDebriefs()
            
            // Resolve Names locally if missing
            var resolvedDebriefs: [Debrief] = []
            
            for debrief in fetchedDebriefs {
                var finalDebrief = debrief
                
                // Since APIService now returns empty name, we MUST resolve locally using contactId
                if !debrief.contactId.isEmpty {
                    // Try to resolve name from device contacts
                    if let localName = await contactStoreService.getContactName(for: debrief.contactId) {
                        finalDebrief = Debrief(
                            id: debrief.id,
                            contactId: debrief.contactId,
                            contactName: localName, // Resolved Name
                            occurredAt: debrief.occurredAt,
                            duration: debrief.duration,
                            status: debrief.status,
                            summary: debrief.summary,
                            transcript: debrief.transcript,
                            actionItems: debrief.actionItems,
                            audioUrl: debrief.audioUrl
                        )
                    } else {
                         // Fallback if ID not found in device (e.g. deleted contact)
                         // finalDebrief name remains "" or we can set "Deleted Contact"
                         finalDebrief = Debrief(
                            id: debrief.id,
                            contactId: debrief.contactId,
                            contactName: "Deleted Contact", // Or keep empty? User said "Deleted Contact" in example code
                            occurredAt: debrief.occurredAt,
                            duration: debrief.duration,
                            status: debrief.status,
                            summary: debrief.summary,
                            transcript: debrief.transcript,
                            actionItems: debrief.actionItems,
                            audioUrl: debrief.audioUrl
                        )
                    }
                } else {
                    // No contact ID involved
                    finalDebrief = Debrief(
                        id: debrief.id,
                        contactId: "",
                        contactName: "Unknown",
                        occurredAt: debrief.occurredAt,
                        duration: debrief.duration,
                        status: debrief.status,
                        summary: debrief.summary,
                        transcript: debrief.transcript,
                        actionItems: debrief.actionItems,
                        audioUrl: debrief.audioUrl
                    )
                }
                
                print("📜 [HomeViewModel] Debrief: \(finalDebrief.id) - Duration: \(finalDebrief.duration)s")
                resolvedDebriefs.append(finalDebrief)
            }
            
            let finalResult = resolvedDebriefs
            await MainActor.run {
                self.debriefs = finalResult
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
    

    
    var stats: (today: Int, total: Int, todayMins: Int, totalMins: Int) {
        let totalCalls = debriefs.count
        let totalSecs = debriefs.reduce(0) { $0 + $1.duration }
        // Use ceil to avoid 0 mins for short calls
        let totalMins = Int(ceil(totalSecs / 60))
        
        let todayDebriefs = debriefs.filter { Calendar.current.isDateInToday($0.occurredAt) }
        let today = todayDebriefs.count
        let todaySecs = todayDebriefs.reduce(0) { $0 + $1.duration }
        let todayMins = Int(ceil(todaySecs / 60))
        
        return (today, totalCalls, todayMins, totalMins)
    }
}
