//
//  HomeViewModelTests.swift
//  debriefTests
//

import XCTest
@testable import debrief

@MainActor
final class HomeViewModelTests: XCTestCase {

    private var mockFirestore: MockFirestoreService!
    private var mockContactStore: MockContactStoreService!
    private var mockStats: MockStatsService!
    private var sut: HomeViewModel!

    override func setUp() {
        super.setUp()
        mockFirestore = MockFirestoreService()
        mockContactStore = MockContactStoreService()
        mockStats = MockStatsService()
        sut = HomeViewModel(
            contactStoreService: mockContactStore,
            statsService: mockStats,
            firestoreService: mockFirestore
        )
    }

    override func tearDown() {
        sut = nil
        mockFirestore = nil
        mockContactStore = nil
        mockStats = nil
        super.tearDown()
    }

    // MARK: - filterDebriefs

    func test_filterDebriefs_emptySearch_returnsAll() {
        sut.debriefs = [
            TestFixtures.makeDebrief(id: "1", contactName: "Alice"),
            TestFixtures.makeDebrief(id: "2", contactName: "Bob")
        ]
        sut.searchQuery = ""

        sut.filterDebriefs()

        XCTAssertEqual(sut.filteredDebriefs.count, 2)
    }

    func test_filterDebriefs_searchByContactName_caseInsensitive() {
        sut.debriefs = [
            TestFixtures.makeDebrief(id: "1", contactName: "Alice Smith"),
            TestFixtures.makeDebrief(id: "2", contactName: "Bob Jones")
        ]
        sut.searchQuery = "alice"

        sut.filterDebriefs()

        XCTAssertEqual(sut.filteredDebriefs.count, 1)
        XCTAssertEqual(sut.filteredDebriefs[0].contactName, "Alice Smith")
    }

    func test_filterDebriefs_searchBySummary() {
        sut.debriefs = [
            TestFixtures.makeDebrief(id: "1", contactName: "Alice", summary: "Project update meeting"),
            TestFixtures.makeDebrief(id: "2", contactName: "Bob", summary: "Lunch plans")
        ]
        sut.searchQuery = "project"

        sut.filterDebriefs()

        XCTAssertEqual(sut.filteredDebriefs.count, 1)
        XCTAssertEqual(sut.filteredDebriefs[0].id, "1")
    }

    // MARK: - Sort

    func test_filterDebriefs_sortedByOccurredAtDescending() {
        let now = Date()
        sut.debriefs = [
            TestFixtures.makeDebrief(id: "old", occurredAt: now.addingTimeInterval(-3600)),
            TestFixtures.makeDebrief(id: "new", occurredAt: now),
            TestFixtures.makeDebrief(id: "mid", occurredAt: now.addingTimeInterval(-1800))
        ]
        sut.searchQuery = ""

        sut.filterDebriefs()

        XCTAssertEqual(sut.filteredDebriefs[0].id, "new")
        XCTAssertEqual(sut.filteredDebriefs[1].id, "mid")
        XCTAssertEqual(sut.filteredDebriefs[2].id, "old")
    }

    // MARK: - Daily Stats

    func test_stats_computedProperty() {
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!

        sut.debriefs = [
            TestFixtures.makeDebrief(id: "1", occurredAt: now, duration: 90),
            TestFixtures.makeDebrief(id: "2", occurredAt: now, duration: 30),
            TestFixtures.makeDebrief(id: "3", occurredAt: yesterday, duration: 120)
        ]

        let stats = sut.stats
        XCTAssertEqual(stats.today, 2)
        XCTAssertEqual(stats.total, 3)
        // todayMins: ceil(120/60) = 2
        XCTAssertEqual(stats.todayMins, 2)
        // totalMins: ceil(240/60) = 4
        XCTAssertEqual(stats.totalMins, 4)
    }

    func test_stats_todayMins_ceilRounding() {
        let now = Date()
        sut.debriefs = [
            TestFixtures.makeDebrief(id: "1", occurredAt: now, duration: 1) // 1 sec
        ]

        let stats = sut.stats
        // ceil(1/60) = 1 minute
        XCTAssertEqual(stats.todayMins, 1)
    }

    // MARK: - Delete Notification

    func test_deleteNotification_removesDebriefFromLists() {
        sut.debriefs = [
            TestFixtures.makeDebrief(id: "d-1"),
            TestFixtures.makeDebrief(id: "d-2")
        ]
        sut.filterDebriefs()
        XCTAssertEqual(sut.filteredDebriefs.count, 2)

        // Post delete notification
        NotificationCenter.default.post(
            name: .didDeleteDebrief,
            object: nil,
            userInfo: ["debriefId": "d-1"]
        )

        // Give RunLoop a chance to process
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))

        XCTAssertEqual(sut.debriefs.count, 1)
        XCTAssertEqual(sut.debriefs[0].id, "d-2")
    }

    // MARK: - fetchDebriefs

    func test_fetchDebriefs_setsDebriefs() async {
        let debriefs = [
            TestFixtures.makeDebrief(id: "1"),
            TestFixtures.makeDebrief(id: "2")
        ]
        mockFirestore.fetchDebriefsResult = FirestoreService.FetchResult(debriefs: debriefs, lastDocument: nil)
        mockFirestore.getDailyStatsResult = FirestoreService.DailyStatsResult(debriefsCount: 2, callsCount: 0, totalDurationSec: 60)

        await sut.fetchDebriefs(userId: "user-1")

        XCTAssertEqual(sut.debriefs.count, 2)
        XCTAssertEqual(mockFirestore.fetchDebriefsCallCount, 1)
    }
}
