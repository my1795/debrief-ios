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
    @Published var isPlaying: Bool = false
    @Published var isDeleting: Bool = false
    @Published var errorMessage: String?
    
    // Services
    private let apiService: APIService
    
    init(debrief: Debrief, apiService: APIService = .shared) {
        self.debrief = debrief
        self.apiService = apiService
        
        // Debug Logging
        print("🔍 [DebriefDetailViewModel] Init with Debrief ID: \(debrief.id)")
        print("   - Contact: \(debrief.contactName)")
        print("   - Status: \(debrief.status)")
        print("   - Audio URL: \(debrief.audioUrl ?? "N/A")")
        print("   - Transcript Length: \(debrief.transcript?.count ?? 0)")
        print("   - Action Items: \(debrief.actionItems?.count ?? 0)")
    }
    
    func deleteDebrief(completion: @escaping () -> Void) {
        isDeleting = true
        Task {
            do {
                try await apiService.deleteDebrief(id: debrief.id)
                completion()
            } catch {
                print("❌ Error deleting debrief: \(error)")
                self.errorMessage = "Failed to delete debrief"
                isDeleting = false
            }
        }
    }
    
    func toggleAudio() {
        // Here we would implement real AVPlayer logic
        // For now, toggle state for UI
        isPlaying.toggle()
        if isPlaying {
            print("▶️ Playing audio from: \(debrief.audioUrl ?? "No URL")")
        } else {
            print("⏸️ Paused")
        }
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
