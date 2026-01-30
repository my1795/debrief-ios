//
//  ContactTests.swift
//  debriefTests
//

import XCTest
@testable import debrief

final class ContactTests: XCTestCase {

    // MARK: - contactId alias

    func test_contactId_equalsId() {
        let contact = TestFixtures.makeContact(id: "abc-123")
        XCTAssertEqual(contact.contactId, "abc-123")
        XCTAssertEqual(contact.contactId, contact.id)
    }

    // MARK: - Decoding

    func test_decode_fullContact() throws {
        let json = """
        {
            "id": "c-001",
            "name": "Alice",
            "handle": "Acme",
            "totalDebriefs": 10,
            "phoneNumbers": ["+1234567890", "+0987654321"],
            "emailAddresses": ["alice@example.com"]
        }
        """
        let contact = try JSONDecoder().decode(Contact.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(contact.id, "c-001")
        XCTAssertEqual(contact.name, "Alice")
        XCTAssertEqual(contact.handle, "Acme")
        XCTAssertEqual(contact.totalDebriefs, 10)
        XCTAssertEqual(contact.phoneNumbers.count, 2)
        XCTAssertEqual(contact.emailAddresses, ["alice@example.com"])
    }

    func test_decode_emptyArrays() throws {
        let json = """
        {
            "id": "c-002",
            "name": "Bob",
            "handle": null,
            "totalDebriefs": 0,
            "phoneNumbers": [],
            "emailAddresses": []
        }
        """
        let contact = try JSONDecoder().decode(Contact.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(contact.id, "c-002")
        XCTAssertNil(contact.handle)
        XCTAssertEqual(contact.phoneNumbers.count, 0)
        XCTAssertEqual(contact.emailAddresses.count, 0)
    }

    // MARK: - Identifiable

    func test_identifiable_conformance() {
        let contact = TestFixtures.makeContact(id: "unique-id")
        XCTAssertEqual(contact.id, "unique-id")
    }
}
