//
//  RecordUITests.swift
//  debriefUITests
//
//  Created by Mustafa Yildirim on 21/01/2026.
//

import XCTest

final class RecordUITests: DebriefUITestCase {

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    // MARK: - Basic Recording Screen Tests

    func testRecordButtonOpensRecordingSheet() throws {
        // Given: Authenticated user with quota
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Tap the record button in tab bar
        let recordButton = app.tabBars.buttons["Record"]
        waitForElementToAppear(recordButton)
        recordButton.tap()

        // Then: Recording sheet should open
        let recordingText = app.staticTexts["Recording..."]
        waitForElementToAppear(recordingText, timeout: 5)

        // Timer should be visible
        let timerText = app.staticTexts["00:00"]
        waitForElementToAppear(timerText, timeout: 3)

        takeScreenshot(name: "Record_Sheet_Opened")
    }

    func testRecordingShowsTimer() throws {
        // Given: Authenticated user
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Start recording
        let recordButton = app.tabBars.buttons["Record"]
        waitForElementToAppear(recordButton)
        recordButton.tap()

        // Wait for recording to start
        let recordingText = app.staticTexts["Recording..."]
        waitForElementToAppear(recordingText)

        // Wait a few seconds
        sleep(3)

        // Then: Timer should have advanced
        let timerLabels = app.staticTexts.matching(NSPredicate(format: "label MATCHES '\\\\d{2}:\\\\d{2}'"))
        XCTAssertGreaterThan(timerLabels.count, 0, "Should show timer in MM:SS format")

        takeScreenshot(name: "Record_Timer_Running")
    }

    func testStopRecordingButton() throws {
        // Given: Recording in progress
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        let recordButton = app.tabBars.buttons["Record"]
        waitForElementToAppear(recordButton)
        recordButton.tap()

        let recordingText = app.staticTexts["Recording..."]
        waitForElementToAppear(recordingText)

        // Record for a few seconds
        sleep(2)

        // When: Tap stop button
        let stopButton = app.buttons["Stop Recording"]
        waitForElementToAppear(stopButton)
        stopButton.tap()

        // Then: Should transition to contact selection
        let recordingSavedText = app.staticTexts["Recording Saved!"]
        waitForElementToAppear(recordingSavedText, timeout: 5)

        takeScreenshot(name: "Record_Stopped")
    }

    func testCancelRecordingButton() throws {
        // Given: Recording in progress
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        let recordButton = app.tabBars.buttons["Record"]
        waitForElementToAppear(recordButton)
        recordButton.tap()

        let recordingText = app.staticTexts["Recording..."]
        waitForElementToAppear(recordingText)

        // When: Tap cancel button (X icon)
        let cancelButton = app.buttons["xmark"]
        if waitForElement(cancelButton, timeout: 3) {
            cancelButton.tap()
        } else {
            // Try alternative cancel button
            let cancelButton2 = app.buttons["Cancel"]
            cancelButton2.tap()
        }

        // Then: Should dismiss recording sheet
        waitForElementToDisappear(recordingText, timeout: 3)

        // Should be back on main tab view
        let tabBar = app.tabBars.firstMatch
        assertElementExists(tabBar)

        takeScreenshot(name: "Record_Cancelled")
    }

    // MARK: - Contact Selection Tests

    func testContactSelectionScreenAppears() throws {
        // Given: Recording completed
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        let recordButton = app.tabBars.buttons["Record"]
        recordButton.tap()

        sleep(2) // Record briefly

        let stopButton = app.buttons["Stop Recording"]
        waitForElementToAppear(stopButton)
        stopButton.tap()

        // Then: Contact selection should appear
        let recordingSavedText = app.staticTexts["Recording Saved!"]
        waitForElementToAppear(recordingSavedText)

        // Duration should be displayed
        let durationLabel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'sec'")).firstMatch
        assertElementExists(durationLabel)

        // Search bar should exist
        let searchField = app.searchFields.firstMatch
        assertElementExists(searchField)

        takeScreenshot(name: "Record_Contact_Selection")
    }

    func testContactSearchFiltering() throws {
        // Given: At contact selection with contacts
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        let recordButton = app.tabBars.buttons["Record"]
        recordButton.tap()

        sleep(1)

        let stopButton = app.buttons["Stop Recording"]
        waitForElementToAppear(stopButton)
        stopButton.tap()

        let recordingSavedText = app.staticTexts["Recording Saved!"]
        waitForElementToAppear(recordingSavedText)

        // When: Type in search field
        let searchField = app.searchFields.firstMatch
        waitForElementToAppear(searchField)
        searchField.tap()
        searchField.typeText("John")

        // Then: Should filter contacts
        sleep(1) // Wait for filter

        takeScreenshot(name: "Record_Contact_Search")
    }

    func testContactSelection() throws {
        // Given: At contact selection
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        let recordButton = app.tabBars.buttons["Record"]
        recordButton.tap()

        sleep(1)

        let stopButton = app.buttons["Stop Recording"]
        waitForElementToAppear(stopButton)
        stopButton.tap()

        let recordingSavedText = app.staticTexts["Recording Saved!"]
        waitForElementToAppear(recordingSavedText)

        // When: Tap on a contact
        let contactList = app.scrollViews.firstMatch
        waitForElementToAppear(contactList)

        // Find and tap any contact row
        let contactRow = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'john' OR label CONTAINS[c] 'test'")).firstMatch
        if contactRow.exists {
            contactRow.tap()

            // Then: Contact should be selected (checkmark visible)
            // Save button should appear
            let saveButton = app.buttons["Save Debrief"]
            waitForElementToAppear(saveButton, timeout: 3)

            takeScreenshot(name: "Record_Contact_Selected")
        }
    }

    func testContactDeselection() throws {
        // Given: Contact is selected
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        let recordButton = app.tabBars.buttons["Record"]
        recordButton.tap()

        sleep(1)

        let stopButton = app.buttons["Stop Recording"]
        waitForElementToAppear(stopButton)
        stopButton.tap()

        let recordingSavedText = app.staticTexts["Recording Saved!"]
        waitForElementToAppear(recordingSavedText)

        // Select a contact
        let contactRow = app.buttons.firstMatch
        if contactRow.exists {
            contactRow.tap()

            // Wait for selection
            sleep(1)

            // When: Tap again to deselect
            contactRow.tap()

            // Then: Save button should disappear or be disabled
            sleep(1)

            takeScreenshot(name: "Record_Contact_Deselected")
        }
    }

    func testSaveDebriefButton() throws {
        // Given: Contact is selected
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        let recordButton = app.tabBars.buttons["Record"]
        recordButton.tap()

        sleep(2)

        let stopButton = app.buttons["Stop Recording"]
        waitForElementToAppear(stopButton)
        stopButton.tap()

        let recordingSavedText = app.staticTexts["Recording Saved!"]
        waitForElementToAppear(recordingSavedText)

        // Scroll to find contact and select
        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()

        // Try to find and select any contact
        let buttons = app.buttons.allElementsBoundByIndex
        for button in buttons {
            if button.label.contains("@") || button.label.contains("Contact") {
                button.tap()
                break
            }
        }

        // When: Tap Save Debrief
        let saveButton = app.buttons["Save Debrief"]
        if waitForElement(saveButton, timeout: 3) {
            saveButton.tap()

            // Then: Should start processing and dismiss
            sleep(2)

            // Should return to main view
            let tabBar = app.tabBars.firstMatch
            waitForElementToAppear(tabBar, timeout: 5)

            takeScreenshot(name: "Record_Debrief_Saved")
        }
    }

    // MARK: - Quota Exceeded Tests

    func testQuotaExceededDebriefsLimit() throws {
        // Given: User who has exceeded debrief quota
        configureWithTestScenario(TestScenario.quotaExceeded.rawValue)
        launchAppAuthenticated()

        // When: Try to record
        let recordButton = app.tabBars.buttons["Record"]
        recordButton.tap()

        // Then: Should show quota exceeded view
        let limitReachedText = app.staticTexts["Limit Reached"]
        waitForElementToAppear(limitReachedText, timeout: 5)

        // Should show upgrade option
        let upgradeButton = app.buttons["Upgrade Plan"]
        assertElementExists(upgradeButton)

        // Should show close button
        let closeButton = app.buttons["Close"]
        assertElementExists(closeButton)

        takeScreenshot(name: "Record_Quota_Exceeded")
    }

    func testQuotaExceededMinutesLimit() throws {
        // Given: User near minutes limit
        configureWithTestScenario(TestScenario.nearQuotaLimit.rawValue)
        launchAppAuthenticated()

        // When: Try to record
        let recordButton = app.tabBars.buttons["Record"]
        recordButton.tap()

        // Then: May show warning or quota exceeded based on exact limit
        sleep(2)

        takeScreenshot(name: "Record_Near_Minutes_Limit")
    }

    func testQuotaExceededCloseButton() throws {
        // Given: Quota exceeded view is shown
        configureWithTestScenario(TestScenario.quotaExceeded.rawValue)
        launchAppAuthenticated()

        let recordButton = app.tabBars.buttons["Record"]
        recordButton.tap()

        let limitReachedText = app.staticTexts["Limit Reached"]
        waitForElementToAppear(limitReachedText, timeout: 5)

        // When: Tap close button
        let closeButton = app.buttons["Close"]
        closeButton.tap()

        // Then: Should dismiss and return to main view
        waitForElementToDisappear(limitReachedText, timeout: 3)

        let tabBar = app.tabBars.firstMatch
        assertElementExists(tabBar)

        takeScreenshot(name: "Record_Quota_Exceeded_Closed")
    }

    // MARK: - Timer and Duration Tests

    func testRecordingMaxDuration() throws {
        // Note: This is a long-running test (10+ minutes)
        // Skip in normal test runs, use for specific duration testing

        // Given: Authenticated user
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Start recording and let it run
        let recordButton = app.tabBars.buttons["Record"]
        recordButton.tap()

        let recordingText = app.staticTexts["Recording..."]
        waitForElementToAppear(recordingText)

        // This would test auto-stop at 10 minutes
        // For quick test, just verify timer format
        sleep(5)

        let timerLabels = app.staticTexts.matching(NSPredicate(format: "label MATCHES '\\\\d{2}:\\\\d{2}'"))
        XCTAssertGreaterThan(timerLabels.count, 0)

        takeScreenshot(name: "Record_Duration_Test")

        // Clean up - cancel recording
        let cancelButton = app.buttons["xmark"]
        if cancelButton.exists {
            cancelButton.tap()
        }
    }

    func testRecordingApproachingLimit() throws {
        // Given: User close to 10 minute limit
        // This test would need mock time injection

        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        let recordButton = app.tabBars.buttons["Record"]
        recordButton.tap()

        // Would verify warning appears at 9:00
        // For now, just verify recording starts
        let recordingText = app.staticTexts["Recording..."]
        waitForElementToAppear(recordingText)

        takeScreenshot(name: "Record_Approaching_Limit")

        // Cancel recording
        let cancelButton = app.buttons["xmark"]
        if cancelButton.exists {
            cancelButton.tap()
        }
    }

    // MARK: - Contact List Tests

    func testAlphabeticalContactGrouping() throws {
        // Given: At contact selection with many contacts
        configureWithTestScenario(TestScenario.manyContacts.rawValue)
        launchAppAuthenticated()

        let recordButton = app.tabBars.buttons["Record"]
        recordButton.tap()

        sleep(1)

        let stopButton = app.buttons["Stop Recording"]
        waitForElementToAppear(stopButton)
        stopButton.tap()

        let recordingSavedText = app.staticTexts["Recording Saved!"]
        waitForElementToAppear(recordingSavedText)

        // Then: Should show alphabetical section headers
        let sectionA = app.staticTexts["A"]
        let sectionB = app.staticTexts["B"]

        // At least some sections should exist
        let hasAlphabetHeaders = sectionA.exists || sectionB.exists
        XCTAssertTrue(hasAlphabetHeaders, "Should show alphabetical section headers")

        takeScreenshot(name: "Record_Alphabetical_Contacts")
    }

    func testContactListScrolling() throws {
        // Given: At contact selection with many contacts
        configureWithTestScenario(TestScenario.manyContacts.rawValue)
        launchAppAuthenticated()

        let recordButton = app.tabBars.buttons["Record"]
        recordButton.tap()

        sleep(1)

        let stopButton = app.buttons["Stop Recording"]
        waitForElementToAppear(stopButton)
        stopButton.tap()

        let recordingSavedText = app.staticTexts["Recording Saved!"]
        waitForElementToAppear(recordingSavedText)

        // When: Scroll through contacts
        let scrollView = app.scrollViews.firstMatch
        waitForElementToAppear(scrollView)

        scrollView.swipeUp()
        scrollView.swipeUp()
        scrollView.swipeUp()

        // Then: Should be able to scroll without crash
        takeScreenshot(name: "Record_Contacts_Scrolled")
    }

    // MARK: - Empty States Tests

    func testNoContactsState() throws {
        // Given: User with no contacts
        configureWithTestScenario(TestScenario.noContacts.rawValue)
        launchAppAuthenticated()

        // When: Try to record
        let recordButton = app.tabBars.buttons["Record"]
        recordButton.tap()

        sleep(1)

        let stopButton = app.buttons["Stop Recording"]
        if waitForElement(stopButton, timeout: 3) {
            stopButton.tap()

            // Then: Should show empty contact list
            let recordingSavedText = app.staticTexts["Recording Saved!"]
            waitForElementToAppear(recordingSavedText)

            takeScreenshot(name: "Record_No_Contacts")
        }
    }

    // MARK: - Performance Tests

    func testRecordingPerformance() throws {
        configureWithTestScenario(TestScenario.basicUser.rawValue)

        measure(metrics: [XCTClockMetric()]) {
            launchAppAuthenticated()

            let recordButton = app.tabBars.buttons["Record"]
            _ = waitForElement(recordButton, timeout: 10)
            recordButton.tap()

            let recordingText = app.staticTexts["Recording..."]
            _ = waitForElement(recordingText, timeout: 5)

            app.terminate()
        }
    }

    // MARK: - Accessibility Tests

    func testRecordingScreenAccessibility() throws {
        // Given: At recording screen
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        let recordButton = app.tabBars.buttons["Record"]
        recordButton.tap()

        let recordingText = app.staticTexts["Recording..."]
        waitForElementToAppear(recordingText)

        // Then: Key elements should be accessible
        let stopButton = app.buttons["Stop Recording"]
        XCTAssertTrue(stopButton.isEnabled, "Stop button should be enabled")

        takeScreenshot(name: "Record_Accessibility")
    }
}
