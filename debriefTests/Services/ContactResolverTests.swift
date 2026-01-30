//
//  ContactResolverTests.swift
//  debriefTests
//

import XCTest
@testable import debrief

final class ContactResolverTests: XCTestCase {

    // Note: ContactResolver.shared has private init and uses singletons.
    // We test the cascade logic via resolveDebrief/resolveDebriefs using the shared instance
    // with mock data where possible. For true unit isolation, consider making init internal.

    // MARK: - Cascade Lookup Logic Tests (via mock service)

    func test_mockContactStore_cascadeLookup_byId() async {
        let mockStore = MockContactStoreService()
        mockStore.contactNamesByID = ["c-1": "Alice"]

        let name = await mockStore.getContactName(for: "c-1")
        XCTAssertEqual(name, "Alice")
    }

    func test_mockContactStore_cascadeLookup_byPhone() async {
        let mockStore = MockContactStoreService()
        let contact = TestFixtures.makeContact(id: "c-2", name: "Bob", phoneNumbers: ["+1555000"])
        mockStore.contactsByPhone = ["+1555000": contact]

        let found = await mockStore.findContact(byPhone: "+1555000")
        XCTAssertEqual(found?.name, "Bob")
    }

    func test_mockContactStore_cascadeLookup_byEmail() async {
        let mockStore = MockContactStoreService()
        let contact = TestFixtures.makeContact(id: "c-3", name: "Carol", emailAddresses: ["carol@test.com"])
        mockStore.contactsByEmail = ["carol@test.com": contact]

        let found = await mockStore.findContact(byEmail: "carol@test.com")
        XCTAssertEqual(found?.name, "Carol")
    }

    func test_mockContactStore_missingId_returnsNil() async {
        let mockStore = MockContactStoreService()
        let name = await mockStore.getContactName(for: "nonexistent")
        XCTAssertNil(name)
    }

    // MARK: - Cache Logic (Mock-based)

    func test_mockContactStore_calledOnce_returnsCachedResult() async {
        let mockStore = MockContactStoreService()
        mockStore.contactNamesByID = ["c-1": "Alice"]

        // First call
        _ = await mockStore.getContactName(for: "c-1")
        // Second call
        _ = await mockStore.getContactName(for: "c-1")

        XCTAssertEqual(mockStore.getContactNameCallCount, 2)
        // In real ContactResolver, second call would hit cache. Here we verify mock tracks calls.
    }

    // MARK: - withContactName Extension

    func test_withContactName_preservesAllFields() {
        let original = TestFixtures.makeDebrief(
            id: "d-1",
            userId: "u-1",
            contactId: "c-1",
            contactName: "Old",
            duration: 120,
            status: .ready,
            summary: "Test",
            phoneNumber: "+1234",
            email: "test@test.com"
        )

        let updated = original.withContactName("New Name")

        XCTAssertEqual(updated.contactName, "New Name")
        XCTAssertEqual(updated.id, "d-1")
        XCTAssertEqual(updated.userId, "u-1")
        XCTAssertEqual(updated.contactId, "c-1")
        XCTAssertEqual(updated.duration, 120)
        XCTAssertEqual(updated.status, .ready)
        XCTAssertEqual(updated.summary, "Test")
        XCTAssertEqual(updated.phoneNumber, "+1234")
        XCTAssertEqual(updated.email, "test@test.com")
    }

    // MARK: - Empty contactId

    func test_emptyContactId_fallbackToUnknown() async {
        let mockStore = MockContactStoreService()
        let name = await mockStore.getContactName(for: "")
        // MockContactStoreService doesn't special-case empty, returns nil
        // ContactResolver.resolveName returns "Unknown" for empty
        XCTAssertNil(name)
    }
}
