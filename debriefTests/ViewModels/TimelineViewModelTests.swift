//
//  TimelineViewModelTests.swift
//  debriefTests
//
//  Note: TimelineViewModel uses FirestoreService.shared, DebriefUploadManager.shared,
//  and AuthSession.shared directly in init (no injection). Creating an instance in tests
//  causes malloc crashes. We test only the pure helper types and DateCalculator here.
//

import XCTest
@testable import debrief

final class TimelineViewModelTests: XCTestCase {

    // MARK: - DateCalculator (used by TimelineViewModel internally)

    func test_dayBounds_startIsStartOfDay() {
        let date = Date(timeIntervalSince1970: 1706025600) // some mid-day
        let (start, _) = DateCalculator.dayBounds(for: date)

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: start)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func test_dayBounds_endIsNextDayStart() {
        let date = Date(timeIntervalSince1970: 1706025600)
        let (start, end) = DateCalculator.dayBounds(for: date)

        let calendar = Calendar.current
        let diff = calendar.dateComponents([.day], from: start, to: end).day
        XCTAssertEqual(diff, 1)
    }

    func test_toMilliseconds_andBack() {
        let date = Date(timeIntervalSince1970: 1706000000)
        let ms = DateCalculator.toMilliseconds(date)
        let back = DateCalculator.fromMilliseconds(ms)

        XCTAssertEqual(ms, 1706000000000)
        XCTAssertEqual(back.timeIntervalSince1970, date.timeIntervalSince1970, accuracy: 0.001)
    }

    func test_relativeSectionTitle_today() {
        let title = DateCalculator.relativeSectionTitle(for: Date())
        XCTAssertEqual(title, "Today")
    }

    func test_relativeSectionTitle_yesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let title = DateCalculator.relativeSectionTitle(for: yesterday)
        XCTAssertEqual(title, "Yesterday")
    }

    func test_relativeSectionTitle_olderDate_formattedAsMonthDay() {
        let oldDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let title = DateCalculator.relativeSectionTitle(for: oldDate)

        // Should be like "January 20" — not "Today" or "Yesterday"
        XCTAssertNotEqual(title, "Today")
        XCTAssertNotEqual(title, "Yesterday")
        XCTAssertFalse(title.isEmpty)
    }

    // MARK: - TimelineSection struct

    func test_timelineSection_identifiable() {
        let section = TimelineViewModel.TimelineSection(
            id: "test",
            title: "Today",
            date: Date(),
            debriefs: [TestFixtures.makeDebrief()]
        )

        XCTAssertEqual(section.id, "test")
        XCTAssertEqual(section.title, "Today")
        XCTAssertEqual(section.debriefs.count, 1)
    }

    // MARK: - DailyStats struct

    func test_dailyStats_defaults() {
        let stats = TimelineViewModel.DailyStats()
        XCTAssertEqual(stats.todayDebriefs, 0)
        XCTAssertEqual(stats.todayCalls, 0)
        XCTAssertEqual(stats.todayDuration, 0)
    }

    // MARK: - DebriefFilters (used by Timeline for filtering)

    func test_filtersDefault_notActive() {
        let filters = DebriefFilters()
        XCTAssertFalse(filters.isActive)
    }
}
