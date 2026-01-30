//
//  EncryptionKeyResponseTests.swift
//  debriefTests
//

import XCTest
@testable import debrief

final class EncryptionKeyResponseTests: XCTestCase {

    // MARK: - keyData

    func test_keyData_validBase64_returnsData() {
        // 32 bytes → 44 chars base64
        let validBase64 = Data(repeating: 0xAB, count: 32).base64EncodedString()

        let response = EncryptionKeyResponse(
            userKey: validBase64,
            algorithm: "AES-256-GCM",
            version: "v1",
            nonceSize: 12,
            tagSize: 128
        )

        XCTAssertNotNil(response.keyData)
        XCTAssertEqual(response.keyData?.count, 32)
    }

    func test_keyData_invalidBase64_returnsNil() {
        let response = EncryptionKeyResponse(
            userKey: "not-valid-base64!!!@@@",
            algorithm: "AES-256-GCM",
            version: "v1",
            nonceSize: 12,
            tagSize: 128
        )

        XCTAssertNil(response.keyData)
    }

    func test_keyData_emptyString_returnsEmptyData() {
        let response = EncryptionKeyResponse(
            userKey: "",
            algorithm: "AES-256-GCM",
            version: "v1",
            nonceSize: 12,
            tagSize: 128
        )

        // Empty string is valid base64, produces empty Data
        XCTAssertNotNil(response.keyData)
        XCTAssertEqual(response.keyData?.count, 0)
    }

    // MARK: - Decoding

    func test_decode_fullResponse() throws {
        let validKey = Data(repeating: 0xCD, count: 32).base64EncodedString()
        let json = """
        {
            "userKey": "\(validKey)",
            "algorithm": "AES-256-GCM",
            "version": "v1",
            "nonceSize": 12,
            "tagSize": 128
        }
        """

        let response = try JSONDecoder().decode(
            EncryptionKeyResponse.self,
            from: json.data(using: .utf8)!
        )

        XCTAssertEqual(response.algorithm, "AES-256-GCM")
        XCTAssertEqual(response.version, "v1")
        XCTAssertEqual(response.nonceSize, 12)
        XCTAssertEqual(response.tagSize, 128)
        XCTAssertNotNil(response.keyData)
        XCTAssertEqual(response.keyData?.count, 32)
    }
}
