//
//  MockFirestoreService.swift
//  debriefTests
//

import Foundation
import FirebaseFirestore
@testable import debrief

final class MockFirestoreService: FirestoreServiceProtocol {

    // MARK: - Stubs

    var fetchDebriefsResult: FirestoreService.FetchResult = .init(debriefs: [], lastDocument: nil)
    var fetchDebriefsByIdsResult: [Debrief] = []
    var fetchAllDebriefResult: [Debrief] = []
    var fetchDateRangeResult: [Debrief] = []
    var getDebriefResult: Result<Debrief, Error> = .failure(NSError(domain: "Test", code: 0))
    var getDebriefsCountResult: Int = 0
    var getCallsCountResult: Int = 0
    var getDailyStatsResult: FirestoreService.DailyStatsResult = .init(debriefsCount: 0, callsCount: 0, totalDurationSec: 0)
    var getUserPlanResult: Result<UserPlan, Error> = .failure(NSError(domain: "Test", code: 0))
    var getUserQuotaResult: Result<UserQuota, Error> = .failure(NSError(domain: "Test", code: 0))

    // MARK: - Call Tracking

    var fetchDebriefsCallCount = 0
    var getDailyStatsCallCount = 0
    var getUserPlanCallCount = 0
    var updateContactNameCallCount = 0
    var updateActionItemsCallCount = 0
    var lastUpdateActionItemsArgs: (debriefId: String, actionItems: [String], userId: String)?

    // MARK: - Protocol Conformance

    func fetchDebriefs(userId: String, filters: DebriefFilters?, limit: Int, startAfter: DocumentSnapshot?) async throws -> FirestoreService.FetchResult {
        fetchDebriefsCallCount += 1
        return fetchDebriefsResult
    }

    func fetchDebriefsByIds(_ ids: [String], userId: String) async throws -> [Debrief] {
        return fetchDebriefsByIdsResult
    }

    func fetchAllDebriefs(userId: String) async throws -> [Debrief] {
        return fetchAllDebriefResult
    }

    func fetchDebriefs(userId: String, start: Date, end: Date) async throws -> [Debrief] {
        return fetchDateRangeResult
    }

    func getDebrief(userId: String, debriefId: String) async throws -> Debrief {
        switch getDebriefResult {
        case .success(let d): return d
        case .failure(let e): throw e
        }
    }

    func getDebriefsCount(userId: String, start: Date, end: Date) async throws -> Int {
        return getDebriefsCountResult
    }

    func getCallsCount(userId: String, start: Date, end: Date) async throws -> Int {
        return getCallsCountResult
    }

    func getDailyStats(userId: String, date: Date) async throws -> FirestoreService.DailyStatsResult {
        getDailyStatsCallCount += 1
        return getDailyStatsResult
    }

    func getUserPlan(userId: String) async throws -> UserPlan {
        getUserPlanCallCount += 1
        switch getUserPlanResult {
        case .success(let p): return p
        case .failure(let e): throw e
        }
    }

    func getUserQuota(userId: String) async throws -> UserQuota {
        switch getUserQuotaResult {
        case .success(let q): return q
        case .failure(let e): throw e
        }
    }

    func updateDebriefContactName(debriefId: String, contactName: String) async throws {
        updateContactNameCallCount += 1
    }

    func updateActionItems(debriefId: String, actionItems: [String], userId: String) async throws {
        updateActionItemsCallCount += 1
        lastUpdateActionItemsArgs = (debriefId, actionItems, userId)
    }

    func decryptIfNeeded(_ debrief: Debrief, userId: String) -> Debrief {
        return debrief
    }

    func decryptIfNeeded(_ debriefs: [Debrief], userId: String) -> [Debrief] {
        return debriefs
    }
}
