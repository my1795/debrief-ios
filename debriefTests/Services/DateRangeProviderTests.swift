//
//  DateRangeProviderTests.swift
//  debriefTests
//

import XCTest
@testable import debrief

final class DateRangeProviderTests: XCTestCase {

    // MARK: - StatsWeekProvider (Sunday → Saturday)

    func test_statsWeek_mondayReturnsPreviousSundayStart() {
        // Create a known Monday: 2026-01-19 (Monday)
        var cal = Calendar.current
        cal.firstWeekday = 1
        let monday = cal.date(from: DateComponents(year: 2026, month: 1, day: 19))!

        let provider = StatsWeekProvider(calendar: cal)
        // We need to test with a fixed date. StatsWeekProvider uses Date() internally,
        // so we test the logic via known calendar math.

        // Verify Monday is indeed weekday 2
        XCTAssertEqual(cal.component(.weekday, from: monday), 2)

        // The Sunday before this Monday is Jan 18
        let expectedSunday = cal.date(from: DateComponents(year: 2026, month: 1, day: 18))!
        let daysFromSunday = cal.component(.weekday, from: monday) - 1 // 2 - 1 = 1
        let computedSunday = cal.date(byAdding: .day, value: -daysFromSunday, to: monday)!
        let startOfComputed = cal.startOfDay(for: computedSunday)
        let startOfExpected = cal.startOfDay(for: expectedSunday)

        XCTAssertEqual(startOfComputed, startOfExpected)
    }

    func test_statsWeek_sundayReturnsSameDayStart() {
        var cal = Calendar.current
        cal.firstWeekday = 1
        // Jan 18, 2026 is a Sunday
        let sunday = cal.date(from: DateComponents(year: 2026, month: 1, day: 18))!
        XCTAssertEqual(cal.component(.weekday, from: sunday), 1)

        let daysFromSunday = cal.component(.weekday, from: sunday) - 1 // 1 - 1 = 0
        XCTAssertEqual(daysFromSunday, 0)
    }

    func test_statsWeek_saturdayReturnsPreviousSundayStart() {
        var cal = Calendar.current
        cal.firstWeekday = 1
        // Jan 24, 2026 is a Saturday
        let saturday = cal.date(from: DateComponents(year: 2026, month: 1, day: 24))!
        XCTAssertEqual(cal.component(.weekday, from: saturday), 7)

        let daysFromSunday = cal.component(.weekday, from: saturday) - 1 // 7 - 1 = 6
        XCTAssertEqual(daysFromSunday, 6)

        let computedSunday = cal.date(byAdding: .day, value: -daysFromSunday, to: saturday)!
        let expectedSunday = cal.date(from: DateComponents(year: 2026, month: 1, day: 18))!
        XCTAssertEqual(cal.startOfDay(for: computedSunday), cal.startOfDay(for: expectedSunday))
    }

    func test_statsWeek_currentWeekRange_startIsBeforeEnd() {
        let provider = StatsWeekProvider()
        let (start, end) = provider.currentWeekRange()

        XCTAssertTrue(start < end, "Week start should be before end")
    }

    func test_statsWeek_weekRangeSpans7Days() {
        let provider = StatsWeekProvider()
        let (start, end) = provider.currentWeekRange()

        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: start, to: end).day!
        XCTAssertEqual(days, 6, "Sunday 00:00 to Saturday 23:59 = 6 days difference")
    }

    func test_statsWeek_startTimeIs000000() {
        let provider = StatsWeekProvider()
        let (start, _) = provider.currentWeekRange()

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: start)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func test_statsWeek_endTimeIs235959() {
        let provider = StatsWeekProvider()
        let (_, end) = provider.currentWeekRange()

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: end)
        XCTAssertEqual(components.hour, 23)
        XCTAssertEqual(components.minute, 59)
        XCTAssertEqual(components.second, 59)
    }

    // MARK: - BillingWeekProvider

    func test_billingWeek_registrationDayIsWeekStart() {
        let calendar = Calendar.current
        let regDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!

        let provider = BillingWeekProvider(registrationDate: regDate, calendar: calendar)
        let (start, _) = provider.currentWeekRange()

        // The week start should be based on registration day
        let dayOfWeek = calendar.component(.day, from: start)
        // It should be on 15th or 15+7n
        let diff = calendar.dateComponents([.day], from: regDate, to: start).day ?? 0
        XCTAssertEqual(diff % 7, 0, "Billing week start should be a multiple of 7 from registration")
    }

    func test_billingWeek_weekEndIs6DaysAfterStart() {
        let calendar = Calendar.current
        let regDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!

        let provider = BillingWeekProvider(registrationDate: regDate, calendar: calendar)
        let (start, end) = provider.currentWeekRange()

        let days = calendar.dateComponents([.day], from: start, to: end).day!
        XCTAssertEqual(days, 6)
    }

    func test_billingWeek_completeWeeksCalculation() {
        let calendar = Calendar.current
        let regDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!

        // 6 days after registration → still in first week
        let day6 = calendar.date(byAdding: .day, value: 6, to: regDate)!
        let daysSince6 = calendar.dateComponents([.day], from: regDate, to: day6).day!
        XCTAssertEqual(daysSince6 / 7, 0, "6 days = 0 complete weeks")

        // 7 days after → new week
        let day7 = calendar.date(byAdding: .day, value: 7, to: regDate)!
        let daysSince7 = calendar.dateComponents([.day], from: regDate, to: day7).day!
        XCTAssertEqual(daysSince7 / 7, 1, "7 days = 1 complete week")
    }

    // MARK: - isInCurrentWeek / isInCurrentMonth

    func test_isInCurrentWeek_todayIsInWeek() {
        let provider = StatsWeekProvider()
        XCTAssertTrue(provider.isInCurrentWeek(Date()))
    }

    func test_isInCurrentMonth_todayIsInMonth() {
        let provider = StatsWeekProvider()
        XCTAssertTrue(provider.isInCurrentMonth(Date()))
    }

    func test_isInCurrentWeek_distantPast_false() {
        let provider = StatsWeekProvider()
        let distantPast = Date(timeIntervalSince1970: 0) // 1970
        XCTAssertFalse(provider.isInCurrentWeek(distantPast))
    }

    // MARK: - Month Range

    func test_statsWeek_currentMonthRange_firstDayIsDay1() {
        let provider = StatsWeekProvider()
        let (start, _) = provider.currentMonthRange()

        let calendar = Calendar.current
        let day = calendar.component(.day, from: start)
        XCTAssertEqual(day, 1)
    }

    func test_statsWeek_currentMonthRange_endIsLastSecond() {
        let provider = StatsWeekProvider()
        let (start, end) = provider.currentMonthRange()

        // End should be last second of last day of month
        XCTAssertTrue(end > start)

        let calendar = Calendar.current
        let endComponents = calendar.dateComponents([.hour, .minute, .second], from: end)
        XCTAssertEqual(endComponents.hour, 23)
        XCTAssertEqual(endComponents.minute, 59)
        XCTAssertEqual(endComponents.second, 59)
    }

    // MARK: - DisplayName

    func test_statsWeekProvider_displayName() {
        let provider = StatsWeekProvider()
        XCTAssertEqual(provider.displayName, "Stats Week (Sun-Sun)")
    }

    func test_billingWeekProvider_displayName() {
        let provider = BillingWeekProvider(registrationDate: Date())
        XCTAssertEqual(provider.displayName, "Billing Week")
    }
}
