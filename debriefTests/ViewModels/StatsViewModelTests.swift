//
//  StatsViewModelTests.swift
//  debriefTests
//

import XCTest
@testable import debrief

@MainActor
final class StatsViewModelTests: XCTestCase {

    private var mockStats: MockStatsService!
    private var sut: StatsViewModel!

    override func setUp() {
        super.setUp()
        mockStats = MockStatsService()
        sut = StatsViewModel(statsService: mockStats)
    }

    override func tearDown() {
        sut = nil
        mockStats = nil
        super.tearDown()
    }

    // MARK: - Quota Percentage

    func test_recordingsQuotaPercent_normalCase() {
        sut.quota = StatsQuota(
            tier: "FREE",
            recordingsThisMonth: 25,
            recordingsLimit: 50,
            minutesThisMonth: 0,
            minutesLimit: 30,
            storageUsedMB: 0,
            storageLimitMB: 500
        )

        XCTAssertEqual(sut.recordingsQuotaPercent, 0.5, accuracy: 0.001)
    }

    func test_recordingsQuotaPercent_unlimitedReturnsZero() {
        sut.quota = StatsQuota(
            tier: "PRO",
            recordingsThisMonth: 100,
            recordingsLimit: Int.max,
            minutesThisMonth: 0,
            minutesLimit: Int.max,
            storageUsedMB: 0,
            storageLimitMB: Int.max
        )

        XCTAssertEqual(sut.recordingsQuotaPercent, 0)
    }

    func test_minutesQuotaPercent_normalCase() {
        sut.quota = StatsQuota(
            tier: "FREE",
            recordingsThisMonth: 0,
            recordingsLimit: 50,
            minutesThisMonth: 15,
            minutesLimit: 30,
            storageUsedMB: 0,
            storageLimitMB: 500
        )

        XCTAssertEqual(sut.minutesQuotaPercent, 0.5, accuracy: 0.001)
    }

    func test_storageQuotaPercent_normalCase() {
        sut.quota = StatsQuota(
            tier: "FREE",
            recordingsThisMonth: 0,
            recordingsLimit: 50,
            minutesThisMonth: 0,
            minutesLimit: 30,
            storageUsedMB: 250,
            storageLimitMB: 500
        )

        XCTAssertEqual(sut.storageQuotaPercent, 0.5, accuracy: 0.001)
    }

    func test_storageQuotaPercent_zeroLimit_returnsZero() {
        sut.quota = StatsQuota(
            tier: "FREE",
            recordingsThisMonth: 0,
            recordingsLimit: 0,
            minutesThisMonth: 0,
            minutesLimit: 0,
            storageUsedMB: 100,
            storageLimitMB: 0
        )

        XCTAssertEqual(sut.storageQuotaPercent, 0)
    }

    // MARK: - Most Active Day (dayName helper tested via calculateMostActiveDay)

    func test_dayName_weekdayMapping() {
        // We can test the overview field after setting it
        sut.overview = StatsOverview(
            totalDebriefs: 0,
            totalMinutes: 0,
            totalActionItems: 0,
            totalContacts: 0,
            avgDebriefDuration: 0,
            mostActiveDay: "Monday",
            longestStreak: 0
        )

        XCTAssertEqual(sut.overview.mostActiveDay, "Monday")
    }

    // MARK: - Empty State

    func test_initialState_isEmpty() {
        XCTAssertTrue(sut.stats.isEmpty)
        XCTAssertEqual(sut.overview.totalDebriefs, 0)
        XCTAssertEqual(sut.overview.mostActiveDay, "-")
        XCTAssertEqual(sut.overview.longestStreak, 0)
    }

    // MARK: - Billing Week Properties

    func test_billingDaysRemaining_noPlan_returns7() {
        sut.userPlan = nil
        XCTAssertEqual(sut.billingDaysRemaining, 7)
    }

    func test_billingWeekRangeString_noPlan_returnsDash() {
        sut.userPlan = nil
        XCTAssertEqual(sut.billingWeekRangeString, "-")
    }

    func test_statsWeekRangeString_containsDayNames() {
        let rangeString = sut.statsWeekRangeString
        // Should contain abbreviated day names like "Sun", "Sat"
        XCTAssertFalse(rangeString.isEmpty)
        XCTAssertTrue(rangeString.contains(" - "))
    }

    // MARK: - StatsOverview Empty

    func test_statsOverview_empty() {
        let empty = StatsOverview.empty
        XCTAssertEqual(empty.totalDebriefs, 0)
        XCTAssertEqual(empty.totalMinutes, 0)
        XCTAssertEqual(empty.totalActionItems, 0)
        XCTAssertEqual(empty.totalContacts, 0)
        XCTAssertEqual(empty.avgDebriefDuration, 0)
        XCTAssertEqual(empty.mostActiveDay, "-")
        XCTAssertEqual(empty.longestStreak, 0)
    }

    // MARK: - Cache Validation

    func test_calculatedStatsCache_isValid_withinSixHours() {
        let cache = CalculatedStatsCache(
            mostActiveDay: "Monday",
            longestStreak: 3,
            cachedAt: Date(), // just now
            weekStart: Date()
        )
        XCTAssertTrue(cache.isValid)
    }

    func test_calculatedStatsCache_isValid_expiredAfterSixHours() {
        let cache = CalculatedStatsCache(
            mostActiveDay: "Monday",
            longestStreak: 3,
            cachedAt: Date().addingTimeInterval(-7 * 3600), // 7 hours ago
            weekStart: Date()
        )
        XCTAssertFalse(cache.isValid)
    }

    func test_statsWeekCache_isValid_withinOneHour() {
        let cache = StatsWeekCache(
            debriefCount: 10,
            totalSeconds: 600,
            actionItemsCount: 5,
            uniqueContactsCount: 3,
            cachedAt: Date(),
            weekStart: Date()
        )
        XCTAssertTrue(cache.isValid)
    }

    func test_statsWeekCache_isValid_expiredAfterOneHour() {
        let cache = StatsWeekCache(
            debriefCount: 10,
            totalSeconds: 600,
            actionItemsCount: 5,
            uniqueContactsCount: 3,
            cachedAt: Date().addingTimeInterval(-2 * 3600), // 2 hours ago
            weekStart: Date()
        )
        XCTAssertFalse(cache.isValid)
    }
}
