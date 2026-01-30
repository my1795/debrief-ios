//
//  RecordViewModelTests.swift
//  debriefTests
//

import XCTest
@testable import debrief

@MainActor
final class RecordViewModelTests: XCTestCase {

    // MARK: - isApproachingLimit

    func test_isApproachingLimit_at540_true() {
        let mockRecorder = MockAudioRecorderService()
        let sut = RecordViewModel(recorderService: mockRecorder)
        sut.recordingTime = 540

        XCTAssertTrue(sut.isApproachingLimit)
    }

    func test_isApproachingLimit_at539_false() {
        let mockRecorder = MockAudioRecorderService()
        let sut = RecordViewModel(recorderService: mockRecorder)
        sut.recordingTime = 539

        XCTAssertFalse(sut.isApproachingLimit)
    }

    func test_isApproachingLimit_at600_true() {
        let mockRecorder = MockAudioRecorderService()
        let sut = RecordViewModel(recorderService: mockRecorder)
        sut.recordingTime = 600

        XCTAssertTrue(sut.isApproachingLimit)
    }

    // MARK: - remainingTime

    func test_remainingTime_atZero_returns600() {
        let mockRecorder = MockAudioRecorderService()
        let sut = RecordViewModel(recorderService: mockRecorder)
        sut.recordingTime = 0

        XCTAssertEqual(sut.remainingTime, 600)
    }

    func test_remainingTime_at300_returns300() {
        let mockRecorder = MockAudioRecorderService()
        let sut = RecordViewModel(recorderService: mockRecorder)
        sut.recordingTime = 300

        XCTAssertEqual(sut.remainingTime, 300)
    }

    func test_remainingTime_at650_returnsZero() {
        let mockRecorder = MockAudioRecorderService()
        let sut = RecordViewModel(recorderService: mockRecorder)
        sut.recordingTime = 650

        // max(0, 600-650) = 0
        XCTAssertEqual(sut.remainingTime, 0)
    }

    // MARK: - groupedContacts

    func test_groupedContacts_alphabeticalGrouping() {
        let mockRecorder = MockAudioRecorderService()
        let mockContactStore = MockContactStoreService()
        let sut = RecordViewModel(recorderService: mockRecorder, contactStoreService: mockContactStore)

        sut.contacts = [
            TestFixtures.makeContact(id: "1", name: "Alice"),
            TestFixtures.makeContact(id: "2", name: "Bob"),
            TestFixtures.makeContact(id: "3", name: "Anna")
        ]
        sut.searchQuery = ""

        let grouped = sut.groupedContacts

        // Should have 2 groups: A and B
        XCTAssertEqual(grouped.count, 2)
        XCTAssertEqual(grouped[0].key, "A")
        XCTAssertEqual(grouped[0].value.count, 2) // Alice, Anna
        XCTAssertEqual(grouped[1].key, "B")
        XCTAssertEqual(grouped[1].value.count, 1) // Bob
    }

    func test_groupedContacts_searchFiltering() {
        let mockRecorder = MockAudioRecorderService()
        let sut = RecordViewModel(recorderService: mockRecorder)

        sut.contacts = [
            TestFixtures.makeContact(id: "1", name: "Alice"),
            TestFixtures.makeContact(id: "2", name: "Bob"),
            TestFixtures.makeContact(id: "3", name: "Charlie")
        ]
        sut.searchQuery = "Bob"

        let grouped = sut.groupedContacts

        XCTAssertEqual(grouped.count, 1)
        XCTAssertEqual(grouped[0].key, "B")
        XCTAssertEqual(grouped[0].value[0].name, "Bob")
    }

    func test_groupedContacts_emptySearch_returnsAll() {
        let mockRecorder = MockAudioRecorderService()
        let sut = RecordViewModel(recorderService: mockRecorder)

        sut.contacts = [
            TestFixtures.makeContact(id: "1", name: "Alice"),
            TestFixtures.makeContact(id: "2", name: "Bob")
        ]
        sut.searchQuery = ""

        let grouped = sut.groupedContacts
        let totalContacts = grouped.reduce(0) { $0 + $1.value.count }
        XCTAssertEqual(totalContacts, 2)
    }

    // MARK: - State Transitions

    func test_stopRecording_changesStateToSelectContact() {
        let mockRecorder = MockAudioRecorderService()
        let sut = RecordViewModel(recorderService: mockRecorder)

        sut.state = .recording
        sut.stopRecording()

        if case .selectContact = sut.state {
            // pass
        } else {
            XCTFail("Expected .selectContact, got \(sut.state)")
        }
    }

    func test_selectContact_togglesSelection() {
        let mockRecorder = MockAudioRecorderService()
        let sut = RecordViewModel(recorderService: mockRecorder)

        let contact = TestFixtures.makeContact(id: "c-1", name: "Alice")

        // First select
        sut.selectContact(contact)
        XCTAssertEqual(sut.selectedContact?.id, "c-1")

        // Second select same → deselect
        sut.selectContact(contact)
        XCTAssertNil(sut.selectedContact)
    }

    func test_selectContact_switchesToDifferentContact() {
        let mockRecorder = MockAudioRecorderService()
        let sut = RecordViewModel(recorderService: mockRecorder)

        let alice = TestFixtures.makeContact(id: "c-1", name: "Alice")
        let bob = TestFixtures.makeContact(id: "c-2", name: "Bob")

        sut.selectContact(alice)
        XCTAssertEqual(sut.selectedContact?.id, "c-1")

        sut.selectContact(bob)
        XCTAssertEqual(sut.selectedContact?.id, "c-2")
    }

    func test_discardRecording_setsStateToComplete() {
        let mockRecorder = MockAudioRecorderService()
        let sut = RecordViewModel(recorderService: mockRecorder)

        sut.state = .recording
        sut.discardRecording()

        if case .complete = sut.state {
            // pass
        } else {
            XCTFail("Expected .complete, got \(sut.state)")
        }
    }
}
