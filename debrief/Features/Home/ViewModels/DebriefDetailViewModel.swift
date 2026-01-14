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
    @Published var isPlaying: Bool = false // This will be synced from audioService
    
    // Services
    private let apiService: APIService
    private let audioService: AudioPlaybackService
    private var cancellables = Set<AnyCancellable>()
    
    init(debrief: Debrief, apiService: APIService = .shared) {
        self.debrief = debrief
        self.apiService = apiService
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
            
        // Load full details immediately
        loadDebriefDetails()
    }
    
    func loadDebriefDetails() {
        isLoadingDetails = true
        Task {
            do {
                print("🔄 [DebriefDetailViewModel] Fetching full details for ID: \(debrief.id)...")
                let fullDebrief = try await apiService.getDebrief(id: debrief.id)
                
                // Preserve locally known contact name
                let updatedDebrief = Debrief(
                    id: fullDebrief.id,
                    contactId: fullDebrief.contactId,
                    contactName: self.debrief.contactName, // Preserve
                    occurredAt: fullDebrief.occurredAt,
                    duration: fullDebrief.duration,
                    status: fullDebrief.status,
                    summary: fullDebrief.summary,
                    transcript: fullDebrief.transcript,
                    actionItems: fullDebrief.actionItems,
                    audioUrl: fullDebrief.audioUrl
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
                completion()
            } catch {
                print("❌ Error deleting debrief: \(error)")
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
}
