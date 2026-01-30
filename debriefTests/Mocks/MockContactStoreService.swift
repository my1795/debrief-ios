//
//  MockContactStoreService.swift
//  debriefTests
//

import Foundation
@testable import debrief

final class MockContactStoreService: ContactStoreServiceProtocol {

    // MARK: - Stubs

    var requestAccessResult = true
    var fetchContactsResult: [Contact] = []
    var contactNamesByID: [String: String] = [:]
    var contactsByPhone: [String: Contact] = [:]
    var contactsByEmail: [String: Contact] = [:]

    // MARK: - Call Tracking

    var requestAccessCallCount = 0
    var fetchContactsCallCount = 0
    var getContactNameCallCount = 0

    // MARK: - Protocol Conformance

    func requestAccess() async -> Bool {
        requestAccessCallCount += 1
        return requestAccessResult
    }

    func fetchContacts() async throws -> [Contact] {
        fetchContactsCallCount += 1
        return fetchContactsResult
    }

    func getContactName(for id: String) async -> String? {
        getContactNameCallCount += 1
        return contactNamesByID[id]
    }

    func findContact(byPhone phone: String) async -> Contact? {
        return contactsByPhone[phone]
    }

    func findContact(byEmail email: String) async -> Contact? {
        return contactsByEmail[email.lowercased()]
    }
}
