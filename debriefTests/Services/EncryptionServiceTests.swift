//
//  EncryptionServiceTests.swift
//  debriefTests
//

import XCTest
import CryptoKit
@testable import debrief

final class EncryptionServiceTests: XCTestCase {

    private let service = EncryptionService.shared

    /// Generate a valid 32-byte AES-256 key
    private func makeKey() -> Data {
        let key = SymmetricKey(size: .bits256)
        return key.withUnsafeBytes { Data($0) }
    }

    // MARK: - Encrypt → Decrypt Roundtrip

    func test_encryptDecrypt_roundtrip_sameKey() throws {
        let key = makeKey()
        let original = "Hello, World!"

        let encrypted = try service.encrypt(original, using: key)
        let decrypted = try service.decrypt(encrypted, using: key)

        XCTAssertEqual(decrypted, original)
    }

    func test_encryptDecrypt_roundtrip_emptyString() throws {
        let key = makeKey()
        let original = ""

        let encrypted = try service.encrypt(original, using: key)
        let decrypted = try service.decrypt(encrypted, using: key)

        XCTAssertEqual(decrypted, original)
    }

    func test_encryptDecrypt_roundtrip_unicode() throws {
        let key = makeKey()
        let original = "Merhaba dünya! 🌍 Türkçe karakterler: çğıöşü ÇĞİÖŞÜ"

        let encrypted = try service.encrypt(original, using: key)
        let decrypted = try service.decrypt(encrypted, using: key)

        XCTAssertEqual(decrypted, original)
    }

    func test_encryptDecrypt_roundtrip_longText() throws {
        let key = makeKey()
        let original = String(repeating: "Lorem ipsum dolor sit amet. ", count: 100)

        let encrypted = try service.encrypt(original, using: key)
        let decrypted = try service.decrypt(encrypted, using: key)

        XCTAssertEqual(decrypted, original)
    }

    // MARK: - Wrong Key

    func test_decrypt_withDifferentKey_throws() throws {
        let key1 = makeKey()
        let key2 = makeKey() // Different key

        let encrypted = try service.encrypt("Secret", using: key1)

        XCTAssertThrowsError(try service.decrypt(encrypted, using: key2)) { error in
            XCTAssertTrue(error is EncryptionError)
        }
    }

    // MARK: - Invalid Input

    func test_decrypt_invalidBase64_throws() {
        let key = makeKey()

        XCTAssertThrowsError(try service.decrypt("not-valid-base64!!!", using: key)) { error in
            if case EncryptionError.invalidFormat = error {
                // pass
            } else {
                XCTFail("Expected .invalidFormat, got \(error)")
            }
        }
    }

    func test_decrypt_tooShortData_throws() {
        let key = makeKey()
        // Only 5 bytes → too short for nonce(12) + tag(16)
        let shortData = Data(repeating: 0, count: 5).base64EncodedString()

        XCTAssertThrowsError(try service.decrypt(shortData, using: key))
    }

    // MARK: - Base64 Format Verification

    func test_encrypt_outputIsValidBase64() throws {
        let key = makeKey()
        let encrypted = try service.encrypt("Test", using: key)

        XCTAssertNotNil(Data(base64Encoded: encrypted), "Output should be valid base64")
    }

    func test_encrypt_outputContainsNonceCiphertextTag() throws {
        let key = makeKey()
        let encrypted = try service.encrypt("Test", using: key)
        let data = Data(base64Encoded: encrypted)!

        // nonce(12) + ciphertext(>=1) + tag(16) → minimum 29 bytes
        XCTAssertGreaterThanOrEqual(data.count, 12 + 1 + 16)
    }

    // MARK: - Nonce Uniqueness

    func test_encrypt_sameInput_differentOutput() throws {
        let key = makeKey()
        let plaintext = "Same text"

        let encrypted1 = try service.encrypt(plaintext, using: key)
        let encrypted2 = try service.encrypt(plaintext, using: key)

        // Due to random nonce, encrypting same text twice should produce different ciphertext
        XCTAssertNotEqual(encrypted1, encrypted2)
    }

    // MARK: - Audio Data

    func test_decryptAudioData_roundtrip() throws {
        let key = makeKey()
        let originalAudio = Data(repeating: 0xFF, count: 1024) // Fake audio

        // Encrypt using CryptoKit directly
        let symmetricKey = SymmetricKey(data: key)
        let sealedBox = try AES.GCM.seal(originalAudio, using: symmetricKey)
        let combined = sealedBox.combined!

        let decrypted = try service.decryptAudioData(combined, using: key)

        XCTAssertEqual(decrypted, originalAudio)
    }
}
