//
//  DebriefFiltersTests.swift
//  debriefTests
//

import XCTest
@testable import debrief

final class DebriefFiltersTests: XCTestCase {

    // MARK: - isActive

    func test_isActive_defaultFilters_false() {
        let filters = DebriefFilters()
        XCTAssertFalse(filters.isActive)
    }

    func test_isActive_withContactId_true() {
        var filters = DebriefFilters()
        filters.contactId = "c-123"
        XCTAssertTrue(filters.isActive)
    }

    func test_isActive_withDateOption_true() {
        var filters = DebriefFilters()
        filters.dateOption = .today
        XCTAssertTrue(filters.isActive)
    }

    func test_isActive_withHasActionItems_true() {
        var filters = DebriefFilters()
        filters.hasActionItems = true
        XCTAssertTrue(filters.isActive)
    }

    func test_isActive_withStatus_true() {
        var filters = DebriefFilters()
        filters.status = .ready
        XCTAssertTrue(filters.isActive)
    }

    func test_isActive_allOption_false() {
        var filters = DebriefFilters()
        filters.dateOption = .all
        XCTAssertFalse(filters.isActive)
    }

    // MARK: - startDate / endDate

    func test_startDate_all_nil() {
        let filters = DebriefFilters()
        XCTAssertNil(filters.startDate)
        XCTAssertNil(filters.endDate)
    }

    func test_startDate_today_isStartOfDay() {
        var filters = DebriefFilters()
        filters.dateOption = .today

        let startDate = filters.startDate
        XCTAssertNotNil(startDate)

        let calendar = Calendar.current
        let expected = calendar.startOfDay(for: Date())
        XCTAssertEqual(startDate!, expected)
    }

    func test_startDate_thisWeek_isSunday() {
        var filters = DebriefFilters()
        filters.dateOption = .thisWeek

        let startDate = filters.startDate
        XCTAssertNotNil(startDate)

        // Should be a Sunday
        var calendar = Calendar.current
        calendar.firstWeekday = 1
        let weekday = calendar.component(.weekday, from: startDate!)
        XCTAssertEqual(weekday, 1, "Week start should be Sunday")
    }

    func test_endDate_thisWeek_isNotNil() {
        var filters = DebriefFilters()
        filters.dateOption = .thisWeek

        XCTAssertNotNil(filters.endDate)
    }

    func test_startDate_thisMonth_isFirstOfMonth() {
        var filters = DebriefFilters()
        filters.dateOption = .thisMonth

        let startDate = filters.startDate
        XCTAssertNotNil(startDate)

        let calendar = Calendar.current
        let day = calendar.component(.day, from: startDate!)
        XCTAssertEqual(day, 1)
    }

    func test_startDate_custom_isStartOfCustomDate() {
        var filters = DebriefFilters()
        filters.dateOption = .custom
        let customDate = Date(timeIntervalSince1970: 1706000000) // Fixed date
        filters.customStartDate = customDate
        filters.customEndDate = customDate

        let calendar = Calendar.current
        let expected = calendar.startOfDay(for: customDate)
        XCTAssertEqual(filters.startDate, expected)
    }

    func test_endDate_custom_isNextDayStart() {
        var filters = DebriefFilters()
        filters.dateOption = .custom
        let customDate = Date(timeIntervalSince1970: 1706000000)
        filters.customEndDate = customDate

        let endDate = filters.endDate
        XCTAssertNotNil(endDate)

        // Should be start of next day
        let calendar = Calendar.current
        let nextDay = calendar.date(byAdding: .day, value: 1, to: customDate)!
        let expected = calendar.startOfDay(for: nextDay)
        XCTAssertEqual(endDate!, expected)
    }

    // MARK: - Equatable (limit excluded)

    func test_equatable_sameFilters_equal() {
        let sharedDate = Date()

        var f1 = DebriefFilters()
        f1.contactId = "c-1"
        f1.dateOption = .today
        f1.customStartDate = sharedDate
        f1.customEndDate = sharedDate

        var f2 = DebriefFilters()
        f2.contactId = "c-1"
        f2.dateOption = .today
        f2.customStartDate = sharedDate
        f2.customEndDate = sharedDate

        XCTAssertEqual(f1, f2)
    }

    func test_equatable_differentLimit_stillEqual() {
        var f1 = DebriefFilters()
        f1.limit = 50

        var f2 = DebriefFilters()
        f2.limit = 100

        XCTAssertEqual(f1, f2, "limit should be excluded from equality")
    }

    func test_equatable_differentContactId_notEqual() {
        var f1 = DebriefFilters()
        f1.contactId = "c-1"

        var f2 = DebriefFilters()
        f2.contactId = "c-2"

        XCTAssertNotEqual(f1, f2)
    }

    // MARK: - clear()

    func test_clear_resetsAllFields() {
        var filters = DebriefFilters()
        filters.contactId = "c-1"
        filters.contactName = "Test"
        filters.hasActionItems = true
        filters.dateOption = .today
        filters.status = .ready

        filters.clear()

        XCTAssertNil(filters.contactId)
        XCTAssertNil(filters.contactName)
        XCTAssertFalse(filters.hasActionItems)
        XCTAssertEqual(filters.dateOption, .all)
        XCTAssertNil(filters.status)
    }

    // MARK: - DateRangeOption

    func test_dateRangeOption_displayNames() {
        XCTAssertEqual(DateRangeOption.all.displayName, "All Time")
        XCTAssertEqual(DateRangeOption.today.displayName, "Today")
        XCTAssertEqual(DateRangeOption.thisWeek.displayName, "This Week")
        XCTAssertEqual(DateRangeOption.thisMonth.displayName, "This Month")
        XCTAssertEqual(DateRangeOption.custom.displayName, "Custom Range")
    }
}
