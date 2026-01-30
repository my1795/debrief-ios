//
//  MockEncryptionService.swift
//  debriefTests
//

import Foundation
@testable import debrief

final class MockEncryptionService: EncryptionServiceProtocol {

    // MARK: - Stubs

    var decryptResult: Result<String, Error> = .success("decrypted")
    var encryptResult: Result<String, Error> = .success("encrypted")
    var decryptAudioResult: Result<Data, Error> = .success(Data())

    // MARK: - Call Tracking

    var decryptCallCount = 0
    var encryptCallCount = 0
    var lastDecryptInput: String?
    var lastEncryptInput: String?

    // MARK: - Protocol Conformance

    func decrypt(_ base64String: String, using key: Data) throws -> String {
        decryptCallCount += 1
        lastDecryptInput = base64String
        switch decryptResult {
        case .success(let s): return s
        case .failure(let e): throw e
        }
    }

    func encrypt(_ plaintext: String, using key: Data) throws -> String {
        encryptCallCount += 1
        lastEncryptInput = plaintext
        switch encryptResult {
        case .success(let s): return s
        case .failure(let e): throw e
        }
    }

    func decryptAudioData(_ encryptedData: Data, using key: Data) throws -> Data {
        switch decryptAudioResult {
        case .success(let d): return d
        case .failure(let e): throw e
        }
    }
}
