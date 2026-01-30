//
//  MockDateRangeProvider.swift
//  debriefTests
//

import Foundation
@testable import debrief

final class MockDateRangeProvider: DateRangeProvider {

    // MARK: - Stubs

    var weekRange: (start: Date, end: Date) = (Date(), Date())
    var monthRange: (start: Date, end: Date) = (Date(), Date())

    var displayName: String = "Mock Week"

    // MARK: - Protocol Conformance

    func currentWeekRange() -> (start: Date, end: Date) {
        return weekRange
    }

    func currentMonthRange() -> (start: Date, end: Date) {
        return monthRange
    }
}
