//
//  CallStorageService.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 15/01/2026.
//

import Foundation

protocol CallStorageServiceProtocol {
    func saveCall(timestamp: Date, duration: TimeInterval)
    func getPendingCalls() -> [CallStat]
    func clearCalls(_ calls: [CallStat])
    var hasPendingCalls: Bool { get }
}

class CallStorageService: CallStorageServiceProtocol {
    static let shared = CallStorageService()
    
    private let key = "pending_calls_queue"
    private let defaults = UserDefaults.standard
    
    func saveCall(timestamp: Date, duration: TimeInterval) {
        var current = getPendingCalls()
        let newCall = CallStat(id: UUID(), timestamp: timestamp, duration: duration)
        current.append(newCall)
        
        do {
            let data = try JSONEncoder().encode(current)
            defaults.set(data, forKey: key)
            Logger.data("Saved call stat. Queue size: \(current.count)")
        } catch {
            Logger.error("Failed to save call stat: \(error)")
        }
    }
    
    func getPendingCalls() -> [CallStat] {
        guard let data = defaults.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode([CallStat].self, from: data)
        } catch {
            Logger.error("Failed to decode call stats: \(error)")
            return []
        }
    }
    
    func clearCalls(_ callsToClear: [CallStat]) {
        var current = getPendingCalls()
        let idsToClear = Set(callsToClear.map { $0.id })
        
        current.removeAll { idsToClear.contains($0.id) }
        
        do {
            let data = try JSONEncoder().encode(current)
            defaults.set(data, forKey: key)
            Logger.info("Cleared \(callsToClear.count) call stats. Remaining: \(current.count)")
        } catch {
            Logger.error("Failed to clear call stats: \(error)")
        }
    }
    
    var hasPendingCalls: Bool {
        return !getPendingCalls().isEmpty
    }
}
