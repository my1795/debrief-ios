//
//  CallModelsTests.swift
//  debriefTests
//

import XCTest
@testable import debrief

final class CallModelsTests: XCTestCase {

    // MARK: - CallStat

    func test_callStat_hasUniqueUUID() {
        let stat1 = CallStat(id: UUID(), timestamp: Date(), duration: 60)
        let stat2 = CallStat(id: UUID(), timestamp: Date(), duration: 120)

        XCTAssertNotEqual(stat1.id, stat2.id)
    }

    func test_callStat_storesDateAndDuration() {
        let date = Date(timeIntervalSince1970: 1706000000)
        let stat = CallStat(id: UUID(), timestamp: date, duration: 90.5)

        XCTAssertEqual(stat.timestamp.timeIntervalSince1970, 1706000000, accuracy: 0.001)
        XCTAssertEqual(stat.duration, 90.5)
    }

    func test_callStat_codable() throws {
        let original = CallStat(id: UUID(), timestamp: Date(), duration: 180)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CallStat.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.duration, original.duration)
    }

    // MARK: - CallSyncItem

    func test_callSyncItem_intValues() throws {
        let item = CallSyncItem(timestamp: 1706000000000, durationSec: 120)

        XCTAssertEqual(item.timestamp, 1706000000000)
        XCTAssertEqual(item.durationSec, 120)
    }

    func test_callSyncItem_codable() throws {
        let item = CallSyncItem(timestamp: 1706000000000, durationSec: 60)

        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(CallSyncItem.self, from: data)

        XCTAssertEqual(decoded.timestamp, 1706000000000)
        XCTAssertEqual(decoded.durationSec, 60)
    }

    // MARK: - CallSyncRequest

    func test_callSyncRequest_encodesArray() throws {
        let request = CallSyncRequest(calls: [
            CallSyncItem(timestamp: 1000, durationSec: 60),
            CallSyncItem(timestamp: 2000, durationSec: 120)
        ])

        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(CallSyncRequest.self, from: data)

        XCTAssertEqual(decoded.calls.count, 2)
        XCTAssertEqual(decoded.calls[0].timestamp, 1000)
        XCTAssertEqual(decoded.calls[1].durationSec, 120)
    }

    // MARK: - CallSyncResponse

    func test_callSyncResponse_decodes() throws {
        let json = """
        {"syncedCount": 5}
        """
        let response = try JSONDecoder().decode(CallSyncResponse.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(response.syncedCount, 5)
    }
}
