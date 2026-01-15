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
    @Published var notificationsEnabled: Bool = true
    @Published var usageCost: String = "$0.00"
    
    // Auth Session reference will be passed from View or accessed via EnvironmentObject if available,
    // but here we just handle view-specific logic.
    
    private let statsService = StatsService()

    init() {
        calculateCacheSize()
        fetchAppVersion()
        Task {
            await calculateUsage()
        }
    }
    
    func calculateCacheSize() {
        // Mocking cache size calculation for now.
        // In real app, we would sum up file sizes in the documents/cache directory.
        let mbs = Int.random(in: 15...250)
        self.cacheSize = "\(mbs) MB"
    }
    
    func clearCache() {
        // Mock clearing
        self.cacheSize = "0 KB"
    }
    
    func calculateUsage() async {
        do {
            // Use new Firestore aggregation integration
            let safeStart = Date(timeIntervalSince1970: 0) // Avoids 'Timestamp out of range' crash
            let totalDebriefs = try await statsService.getDebriefsCount(start: safeStart, end: Date())
            
            // For MVP: totalDebriefs * $0.50 per debrief.
            let cost = Double(totalDebriefs) * 0.50
            self.usageCost = String(format: "$%.2f", cost)
        } catch {
            print("Failed to fetch usage stats: \(error)")
            self.usageCost = "$0.00"
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
    
    func openPrivacyPolicy() {
        if let url = URL(string: "https://debrief.ai/privacy") {
            UIApplication.shared.open(url)
        }
    }
    
    func openHelpCenter() {
        if let url = URL(string: "https://debrief.ai/support") {
            UIApplication.shared.open(url)
        }
    }
}
