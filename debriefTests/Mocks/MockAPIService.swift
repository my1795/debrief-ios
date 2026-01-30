//
//  MockAPIService.swift
//  debriefTests
//

import Foundation
@testable import debrief

final class MockAPIService: APIServiceProtocol {

    // MARK: - Stubs

    var searchDebriefResult: [APIService.SearchResult] = []
    var createDebriefResult: Result<Debrief, Error> = .failure(NSError(domain: "Test", code: 0))
    var exchangeKeyResult: Result<EncryptionKeyResponse, Error> = .failure(NSError(domain: "Test", code: 0))
    var deleteDebriefError: Error?
    var freeVoiceStorageResult: Result<APIService.FreeVoiceStorageResponse, Error> = .failure(NSError(domain: "Test", code: 0))
    var deleteAccountResult: Result<APIService.DeleteAccountResponse, Error> = .failure(NSError(domain: "Test", code: 0))

    // MARK: - Call Tracking

    var deleteDebriefCallCount = 0
    var lastDeletedDebriefId: String?

    // MARK: - Protocol Conformance

    func searchDebriefs(query: String, limit: Int) async throws -> [APIService.SearchResult] {
        return searchDebriefResult
    }

    func createDebrief(audioUrl: URL, contact: Contact, duration: TimeInterval) async throws -> Debrief {
        switch createDebriefResult {
        case .success(let d): return d
        case .failure(let e): throw e
        }
    }

    func exchangeKey() async throws -> EncryptionKeyResponse {
        switch exchangeKeyResult {
        case .success(let r): return r
        case .failure(let e): throw e
        }
    }

    func deleteDebrief(id: String) async throws {
        deleteDebriefCallCount += 1
        lastDeletedDebriefId = id
        if let error = deleteDebriefError { throw error }
    }

    func freeVoiceStorage() async throws -> APIService.FreeVoiceStorageResponse {
        switch freeVoiceStorageResult {
        case .success(let r): return r
        case .failure(let e): throw e
        }
    }

    func deleteAccount() async throws -> APIService.DeleteAccountResponse {
        switch deleteAccountResult {
        case .success(let r): return r
        case .failure(let e): throw e
        }
    }
}
