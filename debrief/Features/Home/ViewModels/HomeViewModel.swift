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
    
    private let firestoreService = FirestoreService.shared
    private let contactStoreService: ContactStoreServiceProtocol
    
    // Combine logic to observe UploadManager
    private var cancellables = Set<AnyCancellable>()
    
    init(contactStoreService: ContactStoreServiceProtocol = ContactStoreService()) {
        self.contactStoreService = contactStoreService
        
        // Observe pending uploads and re-filter list when they change
        DebriefUploadManager.shared.$pendingDebriefs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.filterDebriefs()
            }
            .store(in: &cancellables)
            
        // Observe deletions from Detail View or elsewhere
        NotificationCenter.default.publisher(for: .didDeleteDebrief)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self, let id = notification.userInfo?["debriefId"] as? String else { return }
                
                print("🗑 [HomeViewModel] Removing deleted debrief: \(id)")
                
                // Remove from lists
                self.debriefs.removeAll { $0.id == id }
                self.filteredDebriefs.removeAll { $0.id == id }
                
                // Also remove if it was pending (Manager handles its own state, but we filter manager's list too)
                self.filterDebriefs() 
            }
            .store(in: &cancellables)
    }
    
    func fetchDebriefs(userId: String) async {
        do {
            let fetchedDebriefs = try await firestoreService.fetchDebriefs(userId: userId)
            
            // Resolve Names locally
            var resolvedDebriefs: [Debrief] = []
            
            for debrief in fetchedDebriefs {
                var finalDebrief = debrief
                
                if !debrief.contactId.isEmpty {
                    if let localName = await contactStoreService.getContactName(for: debrief.contactId) {
                        finalDebrief = Debrief(
                            id: debrief.id,
                            userId: debrief.userId,
                            contactId: debrief.contactId,
                            contactName: localName,
                            occurredAt: debrief.occurredAt,
                            duration: debrief.duration,
                            status: debrief.status,
                            summary: debrief.summary,
                            transcript: debrief.transcript,
                            actionItems: debrief.actionItems,
                            audioUrl: debrief.audioUrl,
                            audioStoragePath: debrief.audioStoragePath
                        )
                    } else {
                         finalDebrief = Debrief(
                            id: debrief.id,
                            userId: debrief.userId,
                            contactId: debrief.contactId,
                            contactName: "Deleted Contact",
                            occurredAt: debrief.occurredAt,
                            duration: debrief.duration,
                            status: debrief.status,
                            summary: debrief.summary,
                            transcript: debrief.transcript,
                            actionItems: debrief.actionItems,
                            audioUrl: debrief.audioUrl,
                            audioStoragePath: debrief.audioStoragePath
                        )
                    }
                } else {
                    finalDebrief = Debrief(
                        id: debrief.id,
                        userId: debrief.userId,
                        contactId: "",
                        contactName: "Unknown",
                        occurredAt: debrief.occurredAt,
                        duration: debrief.duration,
                        status: debrief.status,
                        summary: debrief.summary,
                        transcript: debrief.transcript,
                        actionItems: debrief.actionItems,
                        audioUrl: debrief.audioUrl,
                        audioStoragePath: debrief.audioStoragePath
                    )
                }
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
        // MERGE: Pending Uploads + Fetched Debriefs
        // We filter out any pending items that might have completed and are now in the fetched list (by ID overlap)
        // Ideally, UploadManager removes them from pending once ready, but strict overlap check is safer.
        
        let pending = DebriefUploadManager.shared.pendingDebriefs
        // Exclude pending items if they already exist in fetched list (by ID)
        let uniquePending = pending.filter { p in !debriefs.contains(where: { $0.id == p.id }) }
        
        let allDebriefs = uniquePending + debriefs
        
        if searchQuery.isEmpty {
            filteredDebriefs = allDebriefs
        } else {
            filteredDebriefs = allDebriefs.filter { debrief in
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
