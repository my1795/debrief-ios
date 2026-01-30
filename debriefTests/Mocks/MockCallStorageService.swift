//
//  MockCallStorageService.swift
//  debriefTests
//

import Foundation
@testable import debrief

final class MockCallStorageService: CallStorageServiceProtocol {

    // MARK: - Stubs

    var pendingCalls: [CallStat] = []

    // MARK: - Call Tracking

    var saveCallCount = 0
    var clearCallsCount = 0
    var lastClearedCalls: [CallStat] = []

    // MARK: - Protocol Conformance

    func saveCall(timestamp: Date, duration: TimeInterval) {
        saveCallCount += 1
        let call = CallStat(id: UUID(), timestamp: timestamp, duration: duration)
        pendingCalls.append(call)
    }

    func getPendingCalls() -> [CallStat] {
        return pendingCalls
    }

    func clearCalls(_ calls: [CallStat]) {
        clearCallsCount += 1
        lastClearedCalls = calls
        let idsToRemove = Set(calls.map { $0.id })
        pendingCalls.removeAll { idsToRemove.contains($0.id) }
    }

    var hasPendingCalls: Bool {
        return !pendingCalls.isEmpty
    }
}
