//
//  CallStorageServiceTests.swift
//  debriefTests
//

import XCTest
@testable import debrief

final class CallStorageServiceTests: XCTestCase {

    private var service: CallStorageService!
    private let testKey = "pending_calls_queue"

    override func setUp() {
        super.setUp()
        service = CallStorageService.shared
        // Clear any existing data
        UserDefaults.standard.removeObject(forKey: testKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: testKey)
        super.tearDown()
    }

    // MARK: - Save → Get Roundtrip

    func test_saveCall_thenGetPending_returnsCall() {
        let date = Date()
        service.saveCall(timestamp: date, duration: 120)

        let pending = service.getPendingCalls()
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending[0].duration, 120)
    }

    func test_saveMultipleCalls_allReturned() {
        service.saveCall(timestamp: Date(), duration: 60)
        service.saveCall(timestamp: Date(), duration: 120)
        service.saveCall(timestamp: Date(), duration: 180)

        let pending = service.getPendingCalls()
        XCTAssertEqual(pending.count, 3)
    }

    // MARK: - Clear

    func test_clearCalls_removesSpecificCalls() {
        service.saveCall(timestamp: Date(), duration: 60)
        service.saveCall(timestamp: Date(), duration: 120)

        let pending = service.getPendingCalls()
        XCTAssertEqual(pending.count, 2)

        // Clear only the first one
        service.clearCalls([pending[0]])

        let remaining = service.getPendingCalls()
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining[0].id, pending[1].id)
    }

    func test_clearCalls_allCalls_emptyResult() {
        service.saveCall(timestamp: Date(), duration: 60)
        service.saveCall(timestamp: Date(), duration: 120)

        let pending = service.getPendingCalls()
        service.clearCalls(pending)

        XCTAssertTrue(service.getPendingCalls().isEmpty)
    }

    // MARK: - hasPendingCalls

    func test_hasPendingCalls_empty_false() {
        XCTAssertFalse(service.hasPendingCalls)
    }

    func test_hasPendingCalls_withData_true() {
        service.saveCall(timestamp: Date(), duration: 60)
        XCTAssertTrue(service.hasPendingCalls)
    }

    func test_hasPendingCalls_afterClearAll_false() {
        service.saveCall(timestamp: Date(), duration: 60)
        let pending = service.getPendingCalls()
        service.clearCalls(pending)

        XCTAssertFalse(service.hasPendingCalls)
    }

    // MARK: - Edge Cases

    func test_getPendingCalls_noData_returnsEmpty() {
        let pending = service.getPendingCalls()
        XCTAssertTrue(pending.isEmpty)
    }

    func test_clearCalls_emptyArray_noEffect() {
        service.saveCall(timestamp: Date(), duration: 60)
        service.clearCalls([])

        XCTAssertEqual(service.getPendingCalls().count, 1)
    }
}
