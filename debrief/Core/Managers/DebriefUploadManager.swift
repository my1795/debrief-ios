//
//  DebriefUploadManager.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 16/01/2026.
//

import Foundation
import Combine
import FirebaseFirestore
import UserNotifications

@MainActor
class DebriefUploadManager: ObservableObject {
    static let shared = DebriefUploadManager()
    
    // The source of truth for debriefs (both pending and confirmed)
    // HomeViewModel should observe this or merge it with Firestore results
    @Published var pendingDebriefs: [Debrief] = []
    
    // Keep track of listeners to avoid leaks
    private var listeners: [String: ListenerRegistration] = [:]
    
    private let apiService = APIService.shared
    
    private init() {
        // Request notification permission on init (silently if already determined)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        
        // Listen for deletions to clean up pending/failed items
        NotificationCenter.default.addObserver(self, selector: #selector(handleDeletion(_:)), name: .didDeleteDebrief, object: nil)
    }
    
    @objc private func handleDeletion(_ notification: Notification) {
        guard let id = notification.userInfo?["debriefId"] as? String else { return }
        
        Task { @MainActor in
            if let index = pendingDebriefs.firstIndex(where: { $0.id == id }) {
                print("🗑 [UploadManager] Removed pending/failed debrief: \(id)")
                pendingDebriefs.remove(at: index)
            }
        }
    }
    
    func save(audioUrl: URL, contact: Contact, duration: TimeInterval) {
        // 1. Create Optimistic Local Debrief
        // We use a temporary ID initially. If API returns a different ID, we swap it.
        // Ideally, if API allows calling with a client-generated ID, we use that.
        // Assuming API returns a generated ID, we'll store the temp ID locally to identify it.
        
        let tempId = UUID().uuidString
        let optimisticDebrief = Debrief(
            id: tempId,
            userId: AuthSession.shared.user?.id ?? "",
            contactId: contact.id,
            contactName: contact.name,
            occurredAt: Date(),
            duration: duration,
            status: .uploaded, // "Uploading..." style in UI
            summary: nil,
            transcript: nil,
            actionItems: nil,
            audioUrl: nil
        )
        
        print("🚀 [UploadManager] Optimistic Add: \(tempId)")
        
        // 2. Add to Pending List
        pendingDebriefs.insert(optimisticDebrief, at: 0)
        
        // 3. Start Background Upload
        Task.detached(priority: .userInitiated) { [weak self, audioUrl, contact] in
            guard let self = self else { return }
            
            do {
                // Simulate network RTT if needed/verified (removed)
                 
                // API Call
                let serverDebrief = try await self.apiService.createDebrief(
                    audioUrl: audioUrl,
                    contactId: contact.id,
                    duration: duration
                )
                
                print("✅ [UploadManager] Success: \(serverDebrief.id)")
                
                await MainActor.run {
                    self.handleUploadSuccess(tempId: tempId, serverDebrief: serverDebrief)
                }
                
                // Cleanup temp file if needed (Logic for moving file to perm storage?)
                // For now, audioRecorder cleanup handles temp files.
                
            } catch {
                print("❌ [UploadManager] Failed: \(error)")
                await MainActor.run {
                    self.handleUploadFailure(tempId: tempId, error: error)
                }
            }
        }
    }
    
    private func handleUploadSuccess(tempId: String, serverDebrief: Debrief) {
        // 1. Swap Temp Item with Server Item (or update ID)
        if let index = pendingDebriefs.firstIndex(where: { $0.id == tempId }) {
            pendingDebriefs[index] = serverDebrief
            // Status is likely .created or .processing now
        }
        
        // 2. Start Listening for Updates
        startListening(debriefId: serverDebrief.id)
    }
    
    private func handleUploadFailure(tempId: String, error: Error) {
        if let index = pendingDebriefs.firstIndex(where: { $0.id == tempId }) {
            // Update status to failed
            var failedDebrief = pendingDebriefs[index]
            // We need to mutate Debrief to support 'failed', status is already mutable via copy
            // Since Debrief is a struct, we create a new copy with .failed status
            let newDebrief = Debrief(
                id: failedDebrief.id,
                userId: failedDebrief.userId,
                contactId: failedDebrief.contactId,
                contactName: failedDebrief.contactName,
                occurredAt: failedDebrief.occurredAt,
                duration: failedDebrief.duration,
                status: .failed,
                summary: failedDebrief.summary,
                transcript: failedDebrief.transcript,
                actionItems: failedDebrief.actionItems,
                audioUrl: failedDebrief.audioUrl
            )
            pendingDebriefs[index] = newDebrief
        }
        
        // 3. Notify User
        sendFailureNotification()
    }
    
    private func startListening(debriefId: String) {
        // Avoid duplicate listeners
        guard listeners[debriefId] == nil else { return }
        
        let listener = FirestoreService.shared.listenToDebrief(debriefId: debriefId) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let updatedDebrief):
                self.updatePendingDebrief(updatedDebrief)
                
                if updatedDebrief.status == .ready {
                    print("✨ [UploadManager] Debrief Ready: \(debriefId)")
                    self.listeners[debriefId]?.remove()
                    self.listeners[debriefId] = nil
                    
                    // Optional: Remove from 'pending' if HomeView fetches fully from Firestore?
                    // For now, keep it so it stays consistent until refresh.
                }
                
            case .failure(let error):
                print("⚠️ [UploadManager] Listener Error: \(error)")
            }
        }
        
        listeners[debriefId] = listener
    }
    
    private func updatePendingDebrief(_ debrief: Debrief) {
        if let index = pendingDebriefs.firstIndex(where: { $0.id == debrief.id }) {
            pendingDebriefs[index] = debrief
        }
    }
    
    private func sendFailureNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Upload Failed"
        content.body = "Your last debrief could not be uploaded. Tap to retry."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    func retry(debriefId: String) {
        // Logic to retry upload if we persisted the file URL or data
        // For MVP, if we lost the file reference (because ViewModel died), we might not be able to retry easily
        // unless we passed the file path to this manager.
        // TODO: Store file path in LocalDebrief struct.
    }
}
