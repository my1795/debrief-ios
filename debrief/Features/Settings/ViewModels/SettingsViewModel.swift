//
//  SettingsViewModel.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 14/01/2026.
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var cacheSize: String = "Calculating..."
    @Published var appVersion: String = "v1.0.0"

    // Notification preference - controls local notifications (not system push)
    @Published var notificationsEnabled: Bool = true {
        didSet {
            guard oldValue != notificationsEnabled else { return }
            NotificationService.shared.setNotificationsEnabled(notificationsEnabled)
        }
    }

    @Published var currentPlan: String = "Loading..."
    @Published var usageCost: String = "$0.00" // Kept for now, effectively placeholder
    @Published var showClearConfirmation = false
    
    // Storage Quota Stats
    @Published var storageUsedMB: Int = 0
    @Published var storageLimitMB: Int = 500 // Default 500MB
    
    private var cancellables = Set<AnyCancellable>()
    private let statsService = StatsService() // You might want to remove this if not using stats here anymore
    
    init() {
        // Load saved notification preference
        notificationsEnabled = NotificationService.shared.isNotificationsEnabled

        calculateCacheSize()
        fetchAppVersion()
        fetchUserQuota()
    }
    
    private func fetchUserQuota() {
        guard let userId = AuthSession.shared.user?.id else {
            self.currentPlan = "Free" // Fallback
            return
        }
        
        FirestoreService.shared.observeQuota(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("Error fetching quota for settings: \(error)")
                }
            }, receiveValue: { [weak self] quota in
                self?.currentPlan = quota.subscriptionTier
                self?.storageUsedMB = quota.usedStorageMB
                self?.storageLimitMB = quota.storageLimitMB
                
                // Check for storage warning (threshold e.g. 90% or >450MB) 
                // We handle this here because SettingsViewModel observes quota. 
                // But typically this should happen in background or after a call. 
                // Since user asked for logic "adam 450 mb ye ualstı adama bildirim atıcaz", 
                // doing it here catches it when they open settings, which is good usage feedback, 
                // but real-time notification should be in CallObserver. 
                // We'll leave the real-time part for CallObserver.
            })
            .store(in: &cancellables)
    }
    
    var canFreeSpace: Bool {
        return currentPlan.lowercased() == "free"
    }
    
    func calculateCacheSize() {
        // Estimate size of the Documents directory where recordings might be stored
        if let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            do {
                let resources = try docsDir.resourceValues(forKeys: [.fileSizeKey])
                // This is just the root folder, need to traverse or assume a specific subfolder "recordings"
                // For safety/MVP, assuming subfolder "voice_debriefs" or similar based on audio recorder logic.
                // If not defined, we'll traverse all files in Documents (safest for "Clear Data").
                
                // Let's traverse recursively
                let resourceKeys: [URLResourceKey] = [.isRegularFileKey, .fileSizeKey]
                let enumerator = FileManager.default.enumerator(at: docsDir, includingPropertiesForKeys: resourceKeys)
                
                var totalSize: Int64 = 0
                while let fileURL = enumerator?.nextObject() as? URL {
                    let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                    if resourceValues.isRegularFile == true {
                        totalSize += Int64(resourceValues.fileSize ?? 0)
                    }
                }
                
                let mb = Double(totalSize) / 1024 / 1024
                self.cacheSize = String(format: "%.1f MB", mb)
                
            } catch {
                self.cacheSize = "Unknown"
            }
        }
    }

    @Published var isClearingVoiceData = false
    @Published var lastFreedStorageMessage: String?

    func clearVoiceData() {
        isClearingVoiceData = true

        Task {
            do {
                // 1. Call backend to delete audio files (returns 202, processes async)
                let response = try await APIService.shared.freeVoiceStorage()

                let freedMB = response.freedStorageMB ?? 0
                let deletedFiles = response.deletedFilesCount ?? 0
                Logger.success("Request accepted. Freed \(freedMB) MB, deleted \(deletedFiles) files")

                // 2. Delete local audio files only (not all documents)
                deleteLocalAudioFiles()

                // 3. Refresh quota (will get updated value once backend finishes)
                await MainActor.run {
                    self.lastFreedStorageMessage = response.message ?? "Voice files are being deleted..."
                    self.isClearingVoiceData = false
                    // Refresh quota after short delay to get updated value
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.fetchUserQuota()
                    }
                }
            } catch {
                Logger.error("Error freeing voice storage: \(error)")
                await MainActor.run {
                    self.isClearingVoiceData = false
                }
            }
        }
    }

    /// Delete only local audio files (.m4a, .wav) - not all documents
    private func deleteLocalAudioFiles() {
        guard let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: docsDir, includingPropertiesForKeys: nil)
            let audioExtensions = ["m4a", "wav", "mp3", "caf", "aac"]

            for fileURL in fileURLs {
                if audioExtensions.contains(fileURL.pathExtension.lowercased()) {
                    try FileManager.default.removeItem(at: fileURL)
                    Logger.info("Deleted local audio: \(fileURL.lastPathComponent)")
                }
            }
        } catch {
            Logger.warning("Error deleting local audio files: \(error)")
        }
    }
    
    func fetchAppVersion() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            self.appVersion = "v\(version) (\(build))"
        } else {
            self.appVersion = "v1.0.0"
        }
    }
    
    @Published var showDeleteAccountWarning = false
    @Published var showDeleteConfirmationInput = false
    @Published var deleteConfirmationText = ""
    @Published var isDeletingAccount = false
    
    // ... (Existing Methods) ...
    
    func deleteAccount() {
        guard deleteConfirmationText == "DELETE" else { return }
        isDeletingAccount = true
        
        Task {
            do {
                let _ = try await APIService.shared.deleteAccount()
                try Auth.auth().signOut()
                // Session listener in App entry point should handle navigation to Login
            } catch {
                Logger.error("Error deleting account: \(error)")
                isDeletingAccount = false
            }
        }
    }
    
    func openPrivacyPolicy() {
        if let url = AppConfig.shared.privacyPolicyURL {
            UIApplication.shared.open(url)
        }
    }

    func openHelpCenter() {
        if let url = AppConfig.shared.helpCenterURL {
            UIApplication.shared.open(url)
        }
    }

    func openDataHandling() {
        if let url = AppConfig.shared.termsOfServiceURL {
            UIApplication.shared.open(url)
        }
    }
}
