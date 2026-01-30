//
//  DebriefDetailViewModelTests.swift
//  debriefTests
//

import XCTest
@testable import debrief

@MainActor
final class DebriefDetailViewModelTests: XCTestCase {

    private var mockFirestore: MockFirestoreService!

    override func setUp() {
        super.setUp()
        mockFirestore = MockFirestoreService()
    }

    override func tearDown() {
        mockFirestore = nil
        super.tearDown()
    }

    private func makeSUT(debrief: Debrief, userId: String = "user-1") -> DebriefDetailViewModel {
        DebriefDetailViewModel(
            debrief: debrief,
            userId: userId,
            firestoreService: mockFirestore,
            skipInitialLoad: true
        )
    }

    // MARK: - formatDuration

    func test_formatDuration_zeroSeconds() {
        let sut = makeSUT(debrief: TestFixtures.makeDebrief())
        XCTAssertEqual(sut.formatDuration(0), "0:00")
    }

    func test_formatDuration_oneMinuteThirtySeconds() {
        let sut = makeSUT(debrief: TestFixtures.makeDebrief())
        XCTAssertEqual(sut.formatDuration(90), "1:30")
    }

    func test_formatDuration_tenMinutes() {
        let sut = makeSUT(debrief: TestFixtures.makeDebrief())
        XCTAssertEqual(sut.formatDuration(600), "10:00")
    }

    func test_formatDuration_negativeDuration_clampedToZero() {
        let sut = makeSUT(debrief: TestFixtures.makeDebrief())
        XCTAssertEqual(sut.formatDuration(-10), "0:00")
    }

    // MARK: - shareableText

    func test_shareableText_containsContactName() {
        let sut = makeSUT(debrief: TestFixtures.makeDebrief(contactName: "Alice"))
        XCTAssertTrue(sut.shareableText.contains("Alice"))
    }

    func test_shareableText_containsSummary() {
        let sut = makeSUT(debrief: TestFixtures.makeDebrief(summary: "Important meeting"))
        XCTAssertTrue(sut.shareableText.contains("Important meeting"))
    }

    func test_shareableText_containsActionItems() {
        let sut = makeSUT(debrief: TestFixtures.makeDebrief(actionItems: ["Task 1", "Task 2"]))
        XCTAssertTrue(sut.shareableText.contains("Task 1"))
        XCTAssertTrue(sut.shareableText.contains("Task 2"))
    }

    func test_shareableText_nilSummary_showsNA() {
        let sut = makeSUT(debrief: TestFixtures.makeDebrief(summary: nil))
        XCTAssertTrue(sut.shareableText.contains("N/A"))
    }

    func test_shareableText_nilActionItems_showsNone() {
        let sut = makeSUT(debrief: TestFixtures.makeDebrief(actionItems: nil))
        XCTAssertTrue(sut.shareableText.contains("None"))
    }

    // MARK: - Initial State

    func test_initialState_debriefSet() {
        let sut = makeSUT(debrief: TestFixtures.makeDebrief(id: "d-1", contactName: "Test"))
        XCTAssertEqual(sut.debrief.id, "d-1")
        XCTAssertEqual(sut.debrief.contactName, "Test")
        XCTAssertFalse(sut.isDeleting)
        XCTAssertNil(sut.errorMessage)
    }

    func test_initialState_userId() {
        let sut = makeSUT(debrief: TestFixtures.makeDebrief(), userId: "custom-user")
        XCTAssertEqual(sut.userId, "custom-user")
    }

    // MARK: - Action Items

    func test_editActionItem_updatesLocally() {
        let sut = makeSUT(debrief: TestFixtures.makeDebrief(actionItems: ["Old item", "Keep this"]))
        sut.editActionItem(at: 0, newText: "New item")

        XCTAssertEqual(sut.debrief.actionItems?[0], "New item")
        XCTAssertEqual(sut.debrief.actionItems?[1], "Keep this")
    }

    func test_deleteActionItem_removesFromList() {
        let sut = makeSUT(debrief: TestFixtures.makeDebrief(actionItems: ["Item 1", "Item 2", "Item 3"]))
        sut.deleteActionItem(at: 1)

        XCTAssertEqual(sut.debrief.actionItems?.count, 2)
        XCTAssertEqual(sut.debrief.actionItems?[0], "Item 1")
        XCTAssertEqual(sut.debrief.actionItems?[1], "Item 3")
    }

    func test_addActionItem_appendsToList() {
        let sut = makeSUT(debrief: TestFixtures.makeDebrief(actionItems: ["Existing"]))
        sut.addActionItem("New item")

        XCTAssertEqual(sut.debrief.actionItems?.count, 2)
        XCTAssertEqual(sut.debrief.actionItems?.last, "New item")
    }

    func test_addActionItem_nilActionItems_createsNewArray() {
        let sut = makeSUT(debrief: TestFixtures.makeDebrief(actionItems: nil))
        sut.addActionItem("First item")

        XCTAssertEqual(sut.debrief.actionItems?.count, 1)
        XCTAssertEqual(sut.debrief.actionItems?.first, "First item")
    }

    func test_editActionItem_outOfBounds_noEffect() {
        let sut = makeSUT(debrief: TestFixtures.makeDebrief(actionItems: ["Only item"]))
        sut.editActionItem(at: 5, newText: "Should not apply")

        XCTAssertEqual(sut.debrief.actionItems?.count, 1)
        XCTAssertEqual(sut.debrief.actionItems?[0], "Only item")
    }

    func test_deleteActionItem_outOfBounds_noEffect() {
        let sut = makeSUT(debrief: TestFixtures.makeDebrief(actionItems: ["Only item"]))
        sut.deleteActionItem(at: 10)

        XCTAssertEqual(sut.debrief.actionItems?.count, 1)
    }
}
