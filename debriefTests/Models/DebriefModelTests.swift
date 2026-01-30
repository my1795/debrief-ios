//
//  DebriefTests.swift
//  debriefTests
//

import XCTest
@testable import debrief

final class DebriefModelTests: XCTestCase {

    // MARK: - JSON Decoding

    func test_decode_fullJSON_allFieldsPopulated() throws {
        let data = TestFixtures.debriefFullJSON.data(using: .utf8)!
        let debrief = try JSONDecoder().decode(Debrief.self, from: data)

        XCTAssertEqual(debrief.id, "d-001")
        XCTAssertEqual(debrief.debriefId, "d-001") // alias
        XCTAssertEqual(debrief.userId, "u-123")
        XCTAssertEqual(debrief.contactId, "c-456")
        XCTAssertEqual(debrief.contactName, "Jane Smith")
        XCTAssertEqual(debrief.status, .ready)
        XCTAssertEqual(debrief.summary, "Meeting went well")
        XCTAssertEqual(debrief.transcript, "Full transcript here")
        XCTAssertEqual(debrief.actionItems, ["Follow up", "Send email"])
        XCTAssertEqual(debrief.actionItemsCount, 2)
        XCTAssertEqual(debrief.audioUrl, "https://example.com/audio.m4a")
        XCTAssertEqual(debrief.audioStoragePath, "debriefs/u-123/d-001/audio.m4a")
        XCTAssertFalse(debrief.encrypted)
        XCTAssertNil(debrief.encryptionVersion)
        XCTAssertEqual(debrief.phoneNumber, "+1234567890")
        XCTAssertEqual(debrief.email, "jane@example.com")
        XCTAssertEqual(debrief.retryCount, 0)
        XCTAssertNil(debrief.nextRetryAt)
        XCTAssertNil(debrief.errorMessage)
    }

    func test_decode_minimalJSON_usesDefaults() throws {
        let data = TestFixtures.debriefMinimalJSON.data(using: .utf8)!
        let debrief = try JSONDecoder().decode(Debrief.self, from: data)

        XCTAssertEqual(debrief.id, "d-002")
        XCTAssertEqual(debrief.userId, "")
        XCTAssertEqual(debrief.contactId, "")
        XCTAssertEqual(debrief.contactName, "Unknown")
        XCTAssertEqual(debrief.status, .created)
        XCTAssertNil(debrief.summary)
        XCTAssertNil(debrief.transcript)
        XCTAssertNil(debrief.actionItems)
        XCTAssertFalse(debrief.encrypted)
        XCTAssertEqual(debrief.retryCount, 0)
        XCTAssertEqual(debrief.duration, 0)
    }

    // MARK: - Status Logic

    func test_isRetrying_failedWithLowRetryCountAndNextRetry() throws {
        let data = TestFixtures.debriefRetryingJSON.data(using: .utf8)!
        let debrief = try JSONDecoder().decode(Debrief.self, from: data)

        XCTAssertTrue(debrief.isRetrying)
        XCTAssertFalse(debrief.isPermanentlyFailed)
    }

    func test_isPermanentlyFailed_retryCountExceeded() throws {
        let data = TestFixtures.debriefPermanentlyFailedJSON.data(using: .utf8)!
        let debrief = try JSONDecoder().decode(Debrief.self, from: data)

        XCTAssertFalse(debrief.isRetrying)
        XCTAssertTrue(debrief.isPermanentlyFailed)
    }

    func test_isPermanentlyFailed_noNextRetryAt() {
        let debrief = TestFixtures.makeDebrief(
            status: .failed,
            retryCount: 1,
            nextRetryAt: nil
        )
        XCTAssertFalse(debrief.isRetrying)
        XCTAssertTrue(debrief.isPermanentlyFailed)
    }

    func test_isRetrying_falseForNonFailedStatus() {
        let debrief = TestFixtures.makeDebrief(status: .ready)
        XCTAssertFalse(debrief.isRetrying)
        XCTAssertFalse(debrief.isPermanentlyFailed)
    }

    // MARK: - Encryption Flag

    func test_encryptionVersion_v1_setsEncryptedTrue() throws {
        let data = TestFixtures.debriefEncryptedJSON.data(using: .utf8)!
        let debrief = try JSONDecoder().decode(Debrief.self, from: data)

        // encrypted was false in JSON but encryptionVersion="v1" overrides
        XCTAssertTrue(debrief.encrypted)
        XCTAssertEqual(debrief.encryptionVersion, "v1")
    }

    func test_initManual_encryptionVersionV1_overridesFlag() {
        let debrief = TestFixtures.makeDebrief(encrypted: false, encryptionVersion: "v1")
        XCTAssertTrue(debrief.encrypted)
    }

    func test_initManual_noEncryptionVersion_respectsExplicitFlag() {
        let debriefEncrypted = TestFixtures.makeDebrief(encrypted: true, encryptionVersion: nil)
        XCTAssertTrue(debriefEncrypted.encrypted)

        let debriefPlain = TestFixtures.makeDebrief(encrypted: false, encryptionVersion: nil)
        XCTAssertFalse(debriefPlain.encrypted)
    }

    // MARK: - Date Parsing

    func test_decode_secondsTimestamp() throws {
        let data = TestFixtures.debriefFullJSON.data(using: .utf8)!
        let debrief = try JSONDecoder().decode(Debrief.self, from: data)

        // 1706000000 seconds → 2024-01-23
        let expected = Date(timeIntervalSince1970: 1706000000)
        XCTAssertEqual(debrief.occurredAt.timeIntervalSince1970, expected.timeIntervalSince1970, accuracy: 1)
    }

    func test_decode_millisTimestamp() throws {
        let data = TestFixtures.debriefMillisTimestampJSON.data(using: .utf8)!
        let debrief = try JSONDecoder().decode(Debrief.self, from: data)

        // 1706000000000 millis → should be converted to seconds
        let expected = Date(timeIntervalSince1970: 1706000000)
        XCTAssertEqual(debrief.occurredAt.timeIntervalSince1970, expected.timeIntervalSince1970, accuracy: 1)
    }

    // MARK: - Duration

    func test_decode_negativeDuration_clampedToZero() throws {
        let data = TestFixtures.debriefNegativeDurationJSON.data(using: .utf8)!
        let debrief = try JSONDecoder().decode(Debrief.self, from: data)

        XCTAssertEqual(debrief.duration, 0)
    }

    func test_decode_audioDurationSec_mappedToDuration() throws {
        let data = TestFixtures.debriefFullJSON.data(using: .utf8)!
        let debrief = try JSONDecoder().decode(Debrief.self, from: data)

        // audioDurationSec=180 in JSON maps to duration
        XCTAssertEqual(debrief.duration, 180)
    }

    // MARK: - CodingKeys

    func test_codingKey_debriefIdMapsToId() throws {
        let json = """
        {"debriefId": "custom-id", "status": "CREATED", "occurredAt": 1706000000}
        """
        let debrief = try JSONDecoder().decode(Debrief.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(debrief.id, "custom-id")
        XCTAssertEqual(debrief.debriefId, "custom-id")
    }

    // MARK: - withContactName

    func test_withContactName_returnsNewDebriefWithUpdatedName() {
        let original = TestFixtures.makeDebrief(contactName: "Old Name")
        let updated = original.withContactName("New Name")

        XCTAssertEqual(updated.contactName, "New Name")
        XCTAssertEqual(updated.id, original.id)
        XCTAssertEqual(updated.userId, original.userId)
        XCTAssertEqual(updated.status, original.status)
    }
}
