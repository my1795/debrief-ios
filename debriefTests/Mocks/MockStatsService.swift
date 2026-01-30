//
//  MockStatsService.swift
//  debriefTests
//

import Foundation
@testable import debrief

final class MockStatsService: StatsServiceProtocol {

    // MARK: - Stubs

    var callsCountResult: Int = 0
    var debriefsCountResult: Int = 0
    var syncCallsResult: Int = 0

    // MARK: - Call Tracking

    var getCallsCountCallCount = 0
    var getDebriefsCountCallCount = 0
    var syncCallsCallCount = 0

    // MARK: - Protocol Conformance

    func getCallsCount(start: Date, end: Date) async throws -> Int {
        getCallsCountCallCount += 1
        return callsCountResult
    }

    func getDebriefsCount(start: Date, end: Date) async throws -> Int {
        getDebriefsCountCallCount += 1
        return debriefsCountResult
    }

    func syncCalls(calls: [Int64]) async throws -> Int {
        syncCallsCallCount += 1
        return syncCallsResult
    }
}
