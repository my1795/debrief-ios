//
//  DebriefDetailViewModel.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 14/01/2026.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class DebriefDetailViewModel: ObservableObject {
    @Published var debrief: Debrief
    @Published var isLoadingDetails: Bool = false
    @Published var isDeleting: Bool = false
    @Published var errorMessage: String?
    @Published var isPlaying: Bool = false
    @Published var isLoading: Bool = false // Audio loading state
    
    // Services
    private let apiService: APIService
    private let firestoreService: FirestoreService
    private let storageService: StorageService
    private let audioService: AudioPlaybackService
    private var cancellables = Set<AnyCancellable>()
    private let userId: String
    
    init(debrief: Debrief, userId: String, apiService: APIService = .shared, firestoreService: FirestoreService = .shared, storageService: StorageService = .shared) {
        self.debrief = debrief
        self.userId = userId
        self.apiService = apiService
        self.firestoreService = firestoreService
        self.storageService = storageService
        self.audioService = AudioPlaybackService()
        
        // Debug Logging
        print("🔍 [DebriefDetailViewModel] Init with Debrief ID: \(debrief.id)")
        print("   - Contact: \(debrief.contactName)")
        print("   - Status: \(debrief.status)")
        print("   - Audio URL: \(debrief.audioUrl ?? "N/A")")
        print("   - Transcript Length: \(debrief.transcript?.count ?? 0)")
        print("   - Action Items: \(debrief.actionItems?.count ?? 0)")
        
        // Sync Audio State
        audioService.$isPlaying
            .sink { [weak self] isPlaying in
                self?.isPlaying = isPlaying
            }
            .store(in: &cancellables)
        
        audioService.$isLoading
            .sink { [weak self] isLoading in
                self?.isLoading = isLoading
            }
            .store(in: &cancellables)
            
        // Load full details immediately
        loadDebriefDetails()
    }
    
    func loadDebriefDetails() {
        isLoadingDetails = true
        Task {
            do {
                print("🔄 [DebriefDetailViewModel] Fetching full details for ID: \(debrief.id)...")
                let fullDebrief = try await firestoreService.getDebrief(userId: userId, debriefId: debrief.id)
                
                // Resolve Audio URL if missing but storage path exists
                var resolvedAudioUrl = fullDebrief.audioUrl
                if (resolvedAudioUrl == nil || resolvedAudioUrl?.isEmpty == true),
                   let storagePath = fullDebrief.audioStoragePath {
                    do {
                        let url = try await storageService.getDownloadURL(for: storagePath)
                        resolvedAudioUrl = url.absoluteString
                        print("🔗 [DebriefDetailViewModel] Resolved Audio Storage Path: \(url)")
                    } catch {
                        print("⚠️ [DebriefDetailViewModel] Failed to resolve storage path: \(error)")
                    }
                }
                
                // Preserve locally known contact name
                let updatedDebrief = Debrief(
                    id: fullDebrief.id,
                    userId: self.userId, // Maintain consistency
                    contactId: fullDebrief.contactId,
                    contactName: self.debrief.contactName, // Preserve
                    occurredAt: fullDebrief.occurredAt,
                    duration: fullDebrief.duration,
                    status: fullDebrief.status,
                    summary: fullDebrief.summary,
                    transcript: fullDebrief.transcript,
                    actionItems: fullDebrief.actionItems,
                    audioUrl: resolvedAudioUrl,
                    audioStoragePath: fullDebrief.audioStoragePath
                )
                
                self.debrief = updatedDebrief
                print("✅ [DebriefDetailViewModel] Full details loaded.")
                print("   - Summary: \(updatedDebrief.summary?.prefix(20) ?? "nil")...")
                print("   - Audio URL: \(updatedDebrief.audioUrl ?? "nil")")
            } catch {
                print("❌ [DebriefDetailViewModel] Failed to load details: \(error)")
                self.errorMessage = "Failed to load full details"
            }
            isLoadingDetails = false
        }
    }
    
    func deleteDebrief(completion: @escaping () -> Void) {
        isDeleting = true
        Task {
            do {
                try await apiService.deleteDebrief(id: debrief.id)
                audioService.stop() // Stop audio if deleting
                
                // Notify app
                NotificationCenter.default.post(name: .didDeleteDebrief, object: nil, userInfo: ["debriefId": debrief.id])
                
                completion()
            } catch {
                print("❌ Error deleting debrief: \(error)")
                
                // If it was already failed/local, or 404, we should remove it locally anyway
                if debrief.status == .failed {
                    print("⚠️ Force removing failed debrief locally")
                    NotificationCenter.default.post(name: .didDeleteDebrief, object: nil, userInfo: ["debriefId": debrief.id])
                    completion()
                    return
                }
                
                self.errorMessage = "Failed to delete debrief"
                isDeleting = false
            }
        }
    }
    
    func toggleAudio() {
        guard let urlString = debrief.audioUrl, let url = URL(string: urlString) else {
            print("⚠️ [DebriefDetailViewModel] No valid audio URL")
            errorMessage = "No Audio URL found"
            return
        }
        
        audioService.toggle(url: url)
    }
    
    var shareableText: String {
        return """
        Debrief with \(debrief.contactName)
        Date: \(debrief.occurredAt.formatted(date: .long, time: .shortened))
        
        Summary:
        \(debrief.summary ?? "N/A")
        
        Action Items:
        \(debrief.actionItems?.map { "• \($0)" }.joined(separator: "\n") ?? "None")
        
        Transcript:
        \(debrief.transcript ?? "Not available")
        """
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Action Item Editing
    
    /// Edits an action item at the given index
    func editActionItem(at index: Int, newText: String) {
        guard var items = debrief.actionItems, index < items.count else { return }
        
        items[index] = newText
        updateActionItemsInFirebase(items)
    }
    
    /// Deletes an action item at the given index
    func deleteActionItem(at index: Int) {
        guard var items = debrief.actionItems, index < items.count else { return }
        
        items.remove(at: index)
        updateActionItemsInFirebase(items)
    }
    
    /// Adds a new action item
    func addActionItem(_ text: String) {
        var items = debrief.actionItems ?? []
        items.append(text)
        updateActionItemsInFirebase(items)
    }
    
    /// Updates action items locally and in Firebase
    private func updateActionItemsInFirebase(_ items: [String]) {
        // Update local state immediately
        debrief = Debrief(
            id: debrief.id,
            userId: debrief.userId,
            contactId: debrief.contactId,
            contactName: debrief.contactName,
            occurredAt: debrief.occurredAt,
            duration: debrief.duration,
            status: debrief.status,
            summary: debrief.summary,
            transcript: debrief.transcript,
            actionItems: items,
            audioUrl: debrief.audioUrl,
            audioStoragePath: debrief.audioStoragePath,
            encrypted: debrief.encrypted,
            phoneNumber: debrief.phoneNumber,
            email: debrief.email
        )
        
        // Persist to Firebase
        Task {
            do {
                try await firestoreService.updateActionItems(
                    debriefId: debrief.id,
                    actionItems: items,
                    userId: userId
                )
                print("✅ [DebriefDetailViewModel] Action items saved to Firebase")
            } catch {
                print("❌ [DebriefDetailViewModel] Failed to save action items: \(error)")
                errorMessage = "Failed to save changes"
            }
        }
    }
}
