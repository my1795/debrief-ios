//
//  CallObserverService.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 15/01/2026.
//

import CallKit
import Foundation

class CallObserverService: NSObject, CXCallObserverDelegate {
    static let shared = CallObserverService()
    
    private let callObserver = CXCallObserver()
    private var observedCalls: Set<UUID> = []
    
    // We track start times loosely to calculate duration
    private var callStartTimes: [UUID: Date] = [:]
    
    override init() {
        super.init()
        callObserver.setDelegate(self, queue: nil)
        print("📞 [CallObserver] Service initialized")
    }
    
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        if call.hasEnded {
            handleCallEnded(call)
        } else if call.hasConnected {
            handleCallConnected(call)
        } else if call.isOutgoing || !call.hasConnected {
            // Dialing or Incoming ringing
            if !observedCalls.contains(call.uuid) {
                print("📞 [CallObserver] New Call Detected: \(call.uuid) (Outgoing: \(call.isOutgoing))")
                observedCalls.insert(call.uuid)
            }
        }
    }
    
    private func handleCallConnected(_ call: CXCall) {
        guard callStartTimes[call.uuid] == nil else { return }
        
        print("📞 [CallObserver] Call Connected: \(call.uuid)")
        callStartTimes[call.uuid] = Date()
    }
    
    private func handleCallEnded(_ call: CXCall) {
        print("📞 [CallObserver] Call Ended: \(call.uuid). Connected: \(call.hasConnected)")
        
        // Clean up
        observedCalls.remove(call.uuid)
        let startTime = callStartTimes.removeValue(forKey: call.uuid)
        
        // FILTER: Only log answered/connected calls
        if call.hasConnected {
            // Calculate Duration
            let duration: TimeInterval
            if let start = startTime {
                duration = Date().timeIntervalSince(start)
            } else {
                // If we missed the start (e.g. app launched mid-call), default to 0 or estimates
                duration = 0 
                print("⚠️ [CallObserver] Missed start time for connected call")
            }
            
            // 1. Save Locally (Offline First)
            CallStorageService.shared.saveCall(timestamp: Date(), duration: duration)
            
            // 2. Trigger Notification
            NotificationService.shared.scheduleDebriefPrompt()
            
            // 3. Attempt Sync (Fire and Forget)
            Task {
                try? await StatsService().syncPendingCalls()
            }
        } else {
            print("📞 [CallObserver] Call Ignored (Not connected/Answered)")
        }
    }
}
