//
//  StatsModelsTests.swift
//  debriefTests
//

import XCTest
@testable import debrief

final class StatsModelsTests: XCTestCase {

    // MARK: - UserPlan Tier Limits

    func test_freeTier_limits() {
        let plan = TestFixtures.makeUserPlan(tier: "FREE")

        XCTAssertEqual(plan.weeklyDebriefLimit, 50)
        XCTAssertEqual(plan.weeklyMinutesLimit, 30)
        XCTAssertEqual(plan.storageLimitMB, 500)
    }

    func test_personalTier_limits() {
        let plan = TestFixtures.makeUserPlan(tier: "PERSONAL")

        XCTAssertEqual(plan.weeklyDebriefLimit, Int.max)
        XCTAssertEqual(plan.weeklyMinutesLimit, 150)
        XCTAssertEqual(plan.storageLimitMB, 5000)
    }

    func test_proTier_limits() {
        let plan = TestFixtures.makeUserPlan(tier: "PRO")

        XCTAssertEqual(plan.weeklyDebriefLimit, Int.max)
        XCTAssertEqual(plan.weeklyMinutesLimit, Int.max)
        XCTAssertEqual(plan.storageLimitMB, Int.max)
    }

    func test_unknownTier_defaultsToFree() {
        let plan = TestFixtures.makeUserPlan(tier: "UNKNOWN")

        XCTAssertEqual(plan.weeklyDebriefLimit, 50)
        XCTAssertEqual(plan.weeklyMinutesLimit, 30)
        XCTAssertEqual(plan.storageLimitMB, 500)
    }

    func test_tierCaseInsensitive() {
        let plan = TestFixtures.makeUserPlan(tier: "free")
        XCTAssertEqual(plan.weeklyDebriefLimit, 50)

        let plan2 = TestFixtures.makeUserPlan(tier: "Personal")
        XCTAssertEqual(plan2.weeklyMinutesLimit, 150)
    }

    // MARK: - Minutes Rounding

    func test_usedMinutes_ceilRounding() {
        // 1 second → 1 minute (ceil)
        let plan1 = TestFixtures.makeUserPlan(totalSeconds: 1)
        XCTAssertEqual(plan1.usedMinutes, 1)

        // 60 seconds → 1 minute
        let plan60 = TestFixtures.makeUserPlan(totalSeconds: 60)
        XCTAssertEqual(plan60.usedMinutes, 1)

        // 61 seconds → 2 minutes
        let plan61 = TestFixtures.makeUserPlan(totalSeconds: 61)
        XCTAssertEqual(plan61.usedMinutes, 2)

        // 0 seconds → 0 minutes
        let plan0 = TestFixtures.makeUserPlan(totalSeconds: 0)
        XCTAssertEqual(plan0.usedMinutes, 0)
    }

    // MARK: - isUnlimited Checks

    func test_isUnlimitedDebriefs() {
        let freePlan = TestFixtures.makeUserPlan(tier: "FREE")
        XCTAssertFalse(freePlan.isUnlimitedDebriefs)

        let proPlan = TestFixtures.makeUserPlan(tier: "PRO")
        XCTAssertTrue(proPlan.isUnlimitedDebriefs)
    }

    func test_isUnlimitedMinutes() {
        let freePlan = TestFixtures.makeUserPlan(tier: "FREE")
        XCTAssertFalse(freePlan.isUnlimitedMinutes)

        let proPlan = TestFixtures.makeUserPlan(tier: "PRO")
        XCTAssertTrue(proPlan.isUnlimitedMinutes)

        let personalPlan = TestFixtures.makeUserPlan(tier: "PERSONAL")
        XCTAssertFalse(personalPlan.isUnlimitedMinutes)
    }

    func test_isUnlimitedStorage() {
        let freePlan = TestFixtures.makeUserPlan(tier: "FREE")
        XCTAssertFalse(freePlan.isUnlimitedStorage)

        let proPlan = TestFixtures.makeUserPlan(tier: "PRO")
        XCTAssertTrue(proPlan.isUnlimitedStorage)
    }

    // MARK: - toUserQuota Backward Compatibility

    func test_toUserQuota_mapsCorrectly() {
        let plan = TestFixtures.makeUserPlan(
            userId: "u-1",
            tier: "FREE",
            debriefCount: 10,
            totalSeconds: 300,
            usedStorageMB: 50
        )

        let quota = plan.toUserQuota()

        XCTAssertEqual(quota.userId, "u-1")
        XCTAssertEqual(quota.subscriptionTier, "FREE")
        XCTAssertEqual(quota.weeklyDebriefs, 50)  // FREE limit
        XCTAssertEqual(quota.weeklyRecordingMinutes, 30)
        XCTAssertEqual(quota.storageLimitMB, 500)
        XCTAssertEqual(quota.usedDebriefs, 10)
        XCTAssertEqual(quota.usedRecordingSeconds, 300)
        XCTAssertEqual(quota.usedStorageMB, 50)
    }

    // MARK: - Billing Week Dates

    func test_billingWeekDates_millisecondConversion() {
        let startMs: Int64 = 1706000000000  // Known millis timestamp
        let endMs: Int64 = 1706604800000

        let plan = TestFixtures.makeUserPlan(
            billingWeekStart: startMs,
            billingWeekEnd: endMs
        )

        let expectedStart = Date(timeIntervalSince1970: TimeInterval(startMs) / 1000)
        let expectedEnd = Date(timeIntervalSince1970: TimeInterval(endMs) / 1000)

        XCTAssertEqual(plan.billingWeekStartDate, expectedStart)
        XCTAssertEqual(plan.billingWeekEndDate, expectedEnd)
    }

    // MARK: - Unique Contacts

    func test_uniqueContactsCount_nilArray_returnsZero() {
        let usage = UserPlanWeeklyUsage(
            debriefCount: 5,
            totalSeconds: 100,
            actionItemsCount: nil,
            uniqueContactIds: nil
        )
        XCTAssertEqual(usage.uniqueContactsCount, 0)
    }

    func test_uniqueContactsCount_withArray() {
        let usage = UserPlanWeeklyUsage(
            debriefCount: 5,
            totalSeconds: 100,
            actionItemsCount: 3,
            uniqueContactIds: ["a", "b", "c"]
        )
        XCTAssertEqual(usage.uniqueContactsCount, 3)
    }

    func test_safeActionItemsCount_nilReturnsZero() {
        let usage = UserPlanWeeklyUsage(
            debriefCount: 5,
            totalSeconds: 100,
            actionItemsCount: nil,
            uniqueContactIds: nil
        )
        XCTAssertEqual(usage.safeActionItemsCount, 0)
    }

    // MARK: - UserQuota Computed Properties

    func test_userQuota_usedRecordingMinutes_ceil() {
        let quota = UserQuota(
            userId: "u-1",
            subscriptionTier: "FREE",
            weeklyDebriefs: 50,
            weeklyRecordingMinutes: 30,
            storageLimitMB: 500,
            usedDebriefs: 5,
            usedRecordingSeconds: 61,
            usedStorageMB: 100,
            currentPeriodStart: nil,
            currentPeriodEnd: nil
        )
        // 61 seconds → ceil → 2 minutes
        XCTAssertEqual(quota.usedRecordingMinutes, 2)
    }

    func test_userQuota_isUnlimited() {
        let quota = UserQuota(
            userId: "u-1",
            subscriptionTier: "PRO",
            weeklyDebriefs: Int.max,
            weeklyRecordingMinutes: Int.max,
            storageLimitMB: Int.max,
            usedDebriefs: 0,
            usedRecordingSeconds: 0,
            usedStorageMB: 0,
            currentPeriodStart: nil,
            currentPeriodEnd: nil
        )
        XCTAssertTrue(quota.isUnlimitedDebriefs)
        XCTAssertTrue(quota.isUnlimitedMinutes)
        XCTAssertTrue(quota.isUnlimitedStorage)
    }

    // MARK: - BillingConstants

    func test_billingConstants_tierLimits() {
        XCTAssertEqual(BillingConstants.Tier.free.weeklyDebriefLimit, 50)
        XCTAssertEqual(BillingConstants.Tier.free.weeklyMinutesLimit, 30)
        XCTAssertEqual(BillingConstants.Tier.free.storageLimitMB, 500)

        XCTAssertEqual(BillingConstants.Tier.personal.weeklyDebriefLimit, Int.max)
        XCTAssertEqual(BillingConstants.Tier.personal.weeklyMinutesLimit, 150)
        XCTAssertEqual(BillingConstants.Tier.personal.storageLimitMB, 5000)

        XCTAssertEqual(BillingConstants.Tier.pro.weeklyDebriefLimit, Int.max)
        XCTAssertEqual(BillingConstants.Tier.pro.weeklyMinutesLimit, Int.max)
        XCTAssertEqual(BillingConstants.Tier.pro.storageLimitMB, Int.max)
    }

    func test_billingConstants_maxValues() {
        XCTAssertEqual(BillingConstants.maxDebriefDurationSeconds, 600)
        XCTAssertEqual(BillingConstants.maxAudioFileSizeMB, 100)
    }
}
