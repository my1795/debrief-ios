//
//  DebriefDetailViewModel.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 14/01/2026.
//

import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

@MainActor
class DebriefDetailViewModel: ObservableObject {
    @Published var debrief: Debrief
    @Published var isLoadingDetails: Bool = false
    @Published var isDeleting: Bool = false
    @Published var errorMessage: String?
    @Published var isPlaying: Bool = false
    @Published var isLoading: Bool = false // Audio loading state
    
    // Audio Player Progress
    @Published var currentTime: TimeInterval = 0
    @Published var audioDuration: TimeInterval = 0
    @Published var playbackRate: Float = 1.0
    
    // Services
    private let apiService: APIService
    private let firestoreService: FirestoreService
    private let storageService: StorageService
    private let audioService: AudioPlaybackService
    private var cancellables = Set<AnyCancellable>()
    private let userId: String
    
    // Real-time listener for status updates
    private var debriefListener: ListenerRegistration?
    
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
            
        audioService.$decryptionError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.errorMessage = "Playback failed: \(error.localizedDescription)"
                }
            }
            .store(in: &cancellables)
        
        // Sync Audio Progress
        audioService.$currentTime
            .sink { [weak self] time in
                self?.currentTime = time
            }
            .store(in: &cancellables)
        
        audioService.$duration
            .sink { [weak self] duration in
                self?.audioDuration = duration
            }
            .store(in: &cancellables)
        
        audioService.$playbackRate
            .sink { [weak self] rate in
                self?.playbackRate = rate
            }
            .store(in: &cancellables)
            
        // Load full details immediately
        loadDebriefDetails()
        
        // Start real-time listener if still processing
        startListeningIfProcessing()
    }
    
    deinit {
        debriefListener?.remove()
        debriefListener = nil
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
                
                // Decrypt text fields if needed
                var finalTexts = (
                    summary: fullDebrief.summary,
                    transcript: fullDebrief.transcript,
                    actionItems: fullDebrief.actionItems
                )
                
                // Strict V1 check: valid version exists
                if fullDebrief.encryptionVersion != nil {
                    if let key = EncryptionKeyManager.shared.getKey(userId: userId) {
                        print("🔐 [DebriefDetailViewModel] Decrypting text fields (Strict V1)...")
                        
                        func decrypt(_ text: String?) -> String? {
                            guard let text = text, !text.isEmpty else { return nil }
                            // Directly decrypt base64 string, no checks
                            do {
                                return try EncryptionService.shared.decrypt(text, using: key)
                            } catch {
                                print("⚠️ [DebriefDetailViewModel] Decrypt failed: \(error)")
                                return text
                            }
                        }
                        
                        finalTexts.summary = decrypt(fullDebrief.summary)
                        finalTexts.transcript = decrypt(fullDebrief.transcript)
                        if let items = fullDebrief.actionItems {
                            finalTexts.actionItems = items.map { decrypt($0) ?? $0 }
                        }
                    } else {
                        print("⚠️ [DebriefDetailViewModel] Encrypted data but no key")
                        errorMessage = "Decryption key missing"
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
                    summary: finalTexts.summary,
                    transcript: finalTexts.transcript,
                    actionItems: finalTexts.actionItems,
                    audioUrl: resolvedAudioUrl,
                    audioStoragePath: fullDebrief.audioStoragePath,
                    encrypted: fullDebrief.encrypted, // Keep server flag
                    encryptionVersion: fullDebrief.encryptionVersion
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
    
    // MARK: - Real-Time Status Listener
    
    /// Starts a real-time listener if debrief is still processing.
    /// Automatically updates UI when status changes to READY.
    private func startListeningIfProcessing() {
        // Only start listener if status is not final
        guard debrief.status == .processing || debrief.status == .created || debrief.isRetrying else {
            print("📡 [DebriefDetailViewModel] Status is \(debrief.status), no listener needed")
            return
        }
        
        print("📡 [DebriefDetailViewModel] Starting real-time listener for status updates...")
        
        debriefListener = firestoreService.listenToDebrief(debriefId: debrief.id) { [weak self] result in
            guard let self = self else { return }
            
            Task { @MainActor in
                switch result {
                case .success(let updatedDebrief):
                    print("📡 [DebriefDetailViewModel] Received update: status=\(updatedDebrief.status)")
                    
                    // Update local state with new data
                    self.debrief = Debrief(
                        id: updatedDebrief.id,
                        userId: updatedDebrief.userId,
                        contactId: updatedDebrief.contactId,
                        contactName: self.debrief.contactName, // Preserve local contact name
                        occurredAt: updatedDebrief.occurredAt,
                        duration: updatedDebrief.duration,
                        status: updatedDebrief.status,
                        summary: updatedDebrief.summary,
                        transcript: updatedDebrief.transcript,
                        actionItems: updatedDebrief.actionItems,
                        audioUrl: updatedDebrief.audioUrl ?? self.debrief.audioUrl,
                        audioStoragePath: updatedDebrief.audioStoragePath,
                        encrypted: updatedDebrief.encrypted,
                        encryptionVersion: updatedDebrief.encryptionVersion,
                        phoneNumber: updatedDebrief.phoneNumber,
                        email: updatedDebrief.email
                    )
                    
                    // Stop listening once status is final
                    if updatedDebrief.status == .ready || updatedDebrief.status == .failed {
                        print("✅ [DebriefDetailViewModel] Final status reached, removing listener")
                        self.debriefListener?.remove()
                        self.debriefListener = nil
                    }
                    
                case .failure(let error):
                    print("❌ [DebriefDetailViewModel] Listener error: \(error)")
                }
            }
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
        
        Task {
            // Check if we should treat this as encrypted
            // Now strictly relying on model state (which checks encryptionVersion)
            // If the user refreshed, we should have the correct version.
            let isEncrypted = debrief.encrypted
            
            if isEncrypted {
                guard let key = EncryptionKeyManager.shared.getKey(userId: userId) else {
                    print("❌ [DebriefDetailViewModel] No encryption key found!")
                    errorMessage = "Decryption key missing"
                    return
                }
                
                await audioService.toggleEncrypted(remoteURL: url, key: key)
            } else {
                audioService.toggle(url: url)
            }
        }
    }
    
    // MARK: - Audio Controls
    
    func seekAudio(to time: TimeInterval) {
        audioService.seek(to: time)
    }
    
    func setPlaybackRate(_ rate: Float) {
        audioService.setPlaybackRate(rate)
    }
    
    /// Stops audio playback. Call on view disappear.
    func stopAudio() {
        audioService.stop()
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
        let d = max(0, duration)
        let minutes = Int(d) / 60
        let seconds = Int(d) % 60
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
