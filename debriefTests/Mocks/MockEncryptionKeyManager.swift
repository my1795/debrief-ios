//
//  MockEncryptionKeyManager.swift
//  debriefTests
//

import Foundation
@testable import debrief

final class MockEncryptionKeyManager: EncryptionKeyManagerProtocol {

    // MARK: - Stubs

    var storedKey: Data?
    var fetchAndStoreError: Error?

    // MARK: - Call Tracking

    var fetchAndStoreKeyCallCount = 0
    var getKeyCallCount = 0
    var clearKeyCallCount = 0
    var ensureKeyAvailableCallCount = 0

    // MARK: - Protocol Conformance

    func fetchAndStoreKey(userId: String) async throws {
        fetchAndStoreKeyCallCount += 1
        if let error = fetchAndStoreError { throw error }
    }

    func getKey(userId: String) -> Data? {
        getKeyCallCount += 1
        return storedKey
    }

    func ensureKeyAvailable(userId: String) async {
        ensureKeyAvailableCallCount += 1
    }

    func clearKey(userId: String?) {
        clearKeyCallCount += 1
        storedKey = nil
    }
}
