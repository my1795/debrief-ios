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
    
    init() {
        calculateCacheSize()
        calculateUsage()
        fetchAppVersion()
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
    
    func calculateUsage() {
        // Mock usage calculation based on "minutes used"
        // Rate: $0.10 per debrief minute (hypothetical)
        let totalMinutes = 125 // Retrieve from StatsService ideally
        let cost = Double(totalMinutes) * 0.10
        self.usageCost = String(format: "$%.2f", cost)
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
