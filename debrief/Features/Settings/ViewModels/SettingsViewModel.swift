//
//  SettingsViewModel.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 14/01/2026.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var cacheSize: String = "Calculating..."
    @Published var appVersion: String = "v1.0.0"
    
    // Persist notification preference
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true
    
    @Published var currentPlan: String = "Loading..."
    @Published var usageCost: String = "$0.00" // Kept for now, effectively placeholder
    @Published var showClearConfirmation = false
    
    // Storage Quota Stats
    @Published var storageUsedMB: Int = 0
    @Published var storageLimitMB: Int = 500 // Default 500MB
    
    private var cancellables = Set<AnyCancellable>()
    private let statsService = StatsService() // You might want to remove this if not using stats here anymore
    
    init() {
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
                    print("Error fetching quota for settings: \(error)")
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

    func clearVoiceData() {
        // Implement deletion logic.
        // User said: "actually we are deleting remote ones too". 
        // We must call a service to delete remote data for this user.
        
        // 1. Delete Local
        guard let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: docsDir, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            print("Error clearing local data: \(error)")
        }
        
        // 2. Delete Remote & Trigger Quota Recalculation
        Task {
            do {
                try await APIService.shared.deleteAllDebriefs()
                
                // 3. Refresh Quota & Local Cache
                await MainActor.run {
                    self.fetchUserQuota()
                    self.calculateCacheSize()
                }
            } catch {
                print("Error clearing remote data: \(error)")
                // Still refresh local size even if remote fails
                await MainActor.run {
                    self.calculateCacheSize()
                }
            }
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
                print("Error deleting account: \(error)")
                isDeletingAccount = false
            }
        }
    }
    
    func openPrivacyPolicy() {
        if let url = URL(string: "https://debrief-app.vercel.app/") {
            UIApplication.shared.open(url)
        }
    }
    
    func openHelpCenter() {
        // Fallback to main site or generic support
        if let url = URL(string: "https://debrief-app.vercel.app/") {
            UIApplication.shared.open(url)
        }
    }
}
