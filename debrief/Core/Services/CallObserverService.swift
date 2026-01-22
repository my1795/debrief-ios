//
//  CallObserverService.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 15/01/2026.
//

import CallKit
import Foundation
import UIKit

class CallObserverService: NSObject, CXCallObserverDelegate {
    static let shared = CallObserverService()

    private let callObserver = CXCallObserver()
    private var observedCalls: Set<UUID> = []

    // We track start times loosely to calculate duration
    private var callStartTimes: [UUID: Date] = [:]

    // Background task identifier for extending execution
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    override init() {
        super.init()
        callObserver.setDelegate(self, queue: nil)
        Logger.info("CallObserver service initialized")
    }
    
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        if call.hasEnded {
            handleCallEnded(call)
        } else if call.hasConnected {
            handleCallConnected(call)
        } else if call.isOutgoing || !call.hasConnected {
            // Dialing or Incoming ringing
            if !observedCalls.contains(call.uuid) {
                Logger.info("New Call Detected: \(call.uuid) (Outgoing: \(call.isOutgoing))")
                observedCalls.insert(call.uuid)
            }
        }
    }
    
    private func handleCallConnected(_ call: CXCall) {
        guard callStartTimes[call.uuid] == nil else { return }
        
        Logger.info("Call Connected: \(call.uuid)")
        callStartTimes[call.uuid] = Date()
    }
    
    private func handleCallEnded(_ call: CXCall) {
        Logger.info("Call Ended: \(call.uuid). Connected: \(call.hasConnected)")

        // Clean up
        observedCalls.remove(call.uuid)
        let startTime = callStartTimes.removeValue(forKey: call.uuid)

        // FILTER: Only log answered/connected calls
        if call.hasConnected {
            // Request background time to ensure notification is scheduled immediately
            beginBackgroundTask()

            // Calculate Duration
            let duration: TimeInterval
            if let start = startTime {
                duration = Date().timeIntervalSince(start)
            } else {
                // If we missed the start (e.g. app launched mid-call), default to 0 or estimates
                duration = 0
                Logger.warning("Missed start time for connected call")
            }

            // 1. Save Locally (Offline First)
            CallStorageService.shared.saveCall(timestamp: Date(), duration: duration)

            // 2. Trigger Notification (respects user preference)
            NotificationService.shared.scheduleDebriefPrompt()

            // 3. Attempt Sync (Fire and Forget)
            Task {
                try? await StatsService().syncPendingCalls()
                // End background task after sync attempt
                self.endBackgroundTask()
            }
        } else {
            Logger.info("Call Ignored (Not connected/Answered)")
        }
    }

    // MARK: - Background Task Management

    private func beginBackgroundTask() {
        // End any existing task first
        endBackgroundTask()

        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "CallEndedTask") { [weak self] in
            // Expiration handler - clean up
            Logger.warning("Background task expired")
            self?.endBackgroundTask()
        }
        Logger.info("Background task started: \(backgroundTask.rawValue)")
    }

    private func endBackgroundTask() {
        guard backgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        Logger.info("Background task ended: \(backgroundTask.rawValue)")
        backgroundTask = .invalid
    }
}
