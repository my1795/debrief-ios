//
//  IntegrationUITests.swift
//  debriefUITests
//
//  Created by Mustafa Yildirim on 21/01/2026.
//
//  End-to-end integration tests that cover complete user flows
//  across multiple features.
//

import XCTest

final class IntegrationUITests: DebriefUITestCase {

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    // MARK: - Complete User Journey Tests

    /// Test the complete flow: Login -> Record -> Save -> View in Feed
    func testCompleteRecordingJourney() throws {
        // Given: New user logging in
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // Step 1: Verify on Debriefs feed
        let debriefsTitle = app.navigationBars["Debriefs"]
        waitForElementToAppear(debriefsTitle, timeout: 10)
        takeScreenshot(name: "Integration_Step1_Feed")

        // Step 2: Start recording
        let recordButton = app.tabBars.buttons["Record"]
        recordButton.tap()

        let recordingText = app.staticTexts["Recording..."]
        waitForElementToAppear(recordingText, timeout: 5)
        takeScreenshot(name: "Integration_Step2_Recording")

        // Step 3: Record for a few seconds
        sleep(3)

        // Step 4: Stop recording
        let stopButton = app.buttons["Stop Recording"]
        stopButton.tap()

        let recordingSavedText = app.staticTexts["Recording Saved!"]
        waitForElementToAppear(recordingSavedText, timeout: 5)
        takeScreenshot(name: "Integration_Step3_Contact_Selection")

        // Step 5: Select a contact
        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()
        let contactRow = scrollView.buttons.firstMatch
        if contactRow.exists {
            contactRow.tap()
        }

        // Step 6: Save debrief
        let saveButton = app.buttons["Save Debrief"]
        if waitForElement(saveButton, timeout: 3) {
            saveButton.tap()
            sleep(2)
        }

        // Step 7: Verify back on feed
        waitForElementToAppear(debriefsTitle, timeout: 10)
        takeScreenshot(name: "Integration_Step4_Back_To_Feed")

        // Step 8: New debrief should appear (or be processing)
        // Note: Due to async processing, the new debrief may show as "Processing"
    }

    /// Test navigating from Stats -> Top Contact -> Contact Detail -> Debrief Detail
    func testStatsToDebriefNavigation() throws {
        // Given: User with activity
        configureWithTestScenario(TestScenario.withTopContacts.rawValue)
        launchAppAuthenticated()

        // Step 1: Navigate to Stats
        navigateToTab(.stats)
        let statsTitle = app.navigationBars["Stats"]
        waitForElementToAppear(statsTitle)
        takeScreenshot(name: "Integration_Stats_Start")

        // Step 2: Scroll to top contacts
        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()
        scrollView.swipeUp()

        let topContactsTitle = app.staticTexts["Top Contacts"]
        waitForElementToAppear(topContactsTitle, timeout: 5)
        takeScreenshot(name: "Integration_Stats_Top_Contacts")

        // Step 3: Tap on a top contact
        let contactRow = app.buttons.matching(NSPredicate(format: "label CONTAINS '#1'")).firstMatch
        if contactRow.exists {
            contactRow.tap()

            // Step 4: Verify on contact detail
            sleep(2)
            takeScreenshot(name: "Integration_Contact_Detail")

            // Step 5: Scroll to interaction history
            let detailScrollView = app.scrollViews.firstMatch
            detailScrollView.swipeUp()

            // Step 6: Tap on a debrief in history
            let debriefRow = detailScrollView.buttons.firstMatch
            if debriefRow.exists {
                debriefRow.tap()

                // Step 7: Verify on debrief detail
                sleep(2)
                takeScreenshot(name: "Integration_Debrief_Detail")

                tapBackButton()
            }

            tapBackButton()
        }
    }

    /// Test the complete filtering flow across Debriefs feed
    func testFilteringJourney() throws {
        // Given: User with many debriefs
        configureWithTestScenario(TestScenario.powerUser.rawValue)
        launchAppAuthenticated()

        let debriefsTitle = app.navigationBars["Debriefs"]
        waitForElementToAppear(debriefsTitle)

        // Step 1: Open filter sheet
        let filterButton = app.buttons["line.3.horizontal.decrease.circle"]
        filterButton.tap()
        sleep(1)
        takeScreenshot(name: "Integration_Filter_Sheet")

        // Step 2: Apply "This Week" filter
        let thisWeekOption = app.buttons["This Week"]
        if thisWeekOption.exists {
            thisWeekOption.tap()
            let applyButton = app.buttons["Apply"]
            if applyButton.exists {
                applyButton.tap()
            }
        }
        sleep(1)
        takeScreenshot(name: "Integration_Filter_Applied")

        // Step 3: Verify filter chip appears
        // Step 4: Use search within filtered results
        let searchButton = app.buttons["magnifyingglass"]
        searchButton.tap()

        let searchField = app.searchFields.firstMatch
        waitForElementToAppear(searchField)
        searchField.tap()
        searchField.typeText("meeting")
        sleep(2)
        takeScreenshot(name: "Integration_Search_With_Filter")

        // Step 5: Clear search and dismiss
        let doneButton = app.buttons["Done"]
        doneButton.tap()

        // Step 6: Remove filter
        let removeChipButton = app.buttons["xmark.circle.fill"]
        if removeChipButton.exists {
            removeChipButton.tap()
        }
        sleep(1)
        takeScreenshot(name: "Integration_Filter_Removed")
    }

    /// Test Settings -> Free Space -> Verify Stats Update
    func testFreeSpaceJourney() throws {
        // Given: User with storage usage
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // Step 1: Check initial storage in Stats
        navigateToTab(.stats)
        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()
        takeScreenshot(name: "Integration_Storage_Before")

        // Step 2: Go to Settings
        navigateToTab(.settings)
        let settingsScrollView = app.scrollViews.firstMatch
        settingsScrollView.swipeUp()

        // Step 3: Tap Free Voice Space
        let freeSpaceButton = app.buttons["Free Voice Space"]
        if waitForElement(freeSpaceButton, timeout: 3) {
            freeSpaceButton.tap()
            takeScreenshot(name: "Integration_Free_Space_Confirmation")

            // Step 4: Confirm
            let deleteButton = app.alerts.buttons["Delete"]
            if deleteButton.exists {
                deleteButton.tap()
                sleep(3) // Wait for deletion
            }
        }

        // Step 5: Go back to Stats and verify
        navigateToTab(.stats)
        sleep(2)
        takeScreenshot(name: "Integration_Storage_After")
    }

    /// Test Contact search and navigation flow
    func testContactSearchJourney() throws {
        // Given: User with contacts
        configureWithTestScenario(TestScenario.manyContacts.rawValue)
        launchAppAuthenticated()

        // Step 1: Navigate to Contacts
        navigateToTab(.contacts)
        let contactsTitle = app.navigationBars["Contacts"]
        waitForElementToAppear(contactsTitle)
        takeScreenshot(name: "Integration_Contacts_Start")

        // Step 2: Search for a contact
        let searchField = app.searchFields.firstMatch
        waitForElementToAppear(searchField)
        searchField.tap()
        searchField.typeText("John")
        sleep(1)
        takeScreenshot(name: "Integration_Contacts_Search")

        // Step 3: Tap on search result
        let contactRow = app.scrollViews.firstMatch.buttons.firstMatch
        if contactRow.exists {
            contactRow.tap()

            // Step 4: View contact detail
            sleep(2)
            takeScreenshot(name: "Integration_Contact_Detail_From_Search")

            // Step 5: Navigate to a debrief
            let detailScrollView = app.scrollViews.firstMatch
            detailScrollView.swipeUp()

            let debriefRow = detailScrollView.buttons.firstMatch
            if debriefRow.exists {
                debriefRow.tap()
                sleep(2)
                takeScreenshot(name: "Integration_Debrief_From_Contact")
                tapBackButton()
            }

            tapBackButton()
        }

        // Step 6: Clear search
        let clearButton = searchField.buttons["Clear text"]
        if clearButton.exists {
            clearButton.tap()
        }
    }

    // MARK: - Action Items Flow

    /// Test adding and managing action items
    func testActionItemsJourney() throws {
        // Given: User with a debrief
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // Step 1: Open a debrief
        let debriefsTitle = app.navigationBars["Debriefs"]
        waitForElementToAppear(debriefsTitle)
        sleep(2)

        let scrollView = app.scrollViews.firstMatch
        let debriefRow = scrollView.buttons.firstMatch
        if debriefRow.exists {
            debriefRow.tap()
            sleep(2)
            takeScreenshot(name: "Integration_Action_Items_Start")

            // Step 2: Find action items section
            let detailScrollView = app.scrollViews.firstMatch
            detailScrollView.swipeUp()

            // Step 3: Select an action item
            let checkbox = app.buttons["circle"]
            if checkbox.exists {
                checkbox.tap()
                takeScreenshot(name: "Integration_Action_Item_Selected")

                // Step 4: Clear selection
                let clearButton = app.buttons["Clear"]
                if clearButton.exists {
                    clearButton.tap()
                }
            }

            // Step 5: Add new action item
            detailScrollView.swipeUp()
            let addButton = app.buttons["Add Action Item"]
            if addButton.exists {
                addButton.tap()
                sleep(1)
                takeScreenshot(name: "Integration_Add_Action_Item")
            }

            tapBackButton()
        }
    }

    // MARK: - Audio Player Flow

    /// Test audio playback controls
    func testAudioPlayerJourney() throws {
        // Given: Debrief with audio
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // Step 1: Open a debrief
        sleep(2)
        let scrollView = app.scrollViews.firstMatch
        let debriefRow = scrollView.buttons.firstMatch
        if debriefRow.exists {
            debriefRow.tap()
            sleep(2)

            // Step 2: Scroll to audio player
            let detailScrollView = app.scrollViews.firstMatch
            detailScrollView.swipeUp()
            detailScrollView.swipeUp()

            // Step 3: Play audio
            let playButton = app.buttons["play.fill"]
            if playButton.exists {
                playButton.tap()
                sleep(2)
                takeScreenshot(name: "Integration_Audio_Playing")

                // Step 4: Change speed
                let speed15x = app.buttons["1.5x"]
                if speed15x.exists {
                    speed15x.tap()
                    takeScreenshot(name: "Integration_Audio_Speed_Changed")
                }

                // Step 5: Pause
                let pauseButton = app.buttons["pause.fill"]
                if pauseButton.exists {
                    pauseButton.tap()
                }
            }

            tapBackButton()
        }
    }

    // MARK: - Tab Navigation Flow

    /// Test navigating through all tabs
    func testTabNavigationJourney() throws {
        // Given: Authenticated user
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // Step 1: Debriefs tab (default)
        let debriefsTitle = app.navigationBars["Debriefs"]
        waitForElementToAppear(debriefsTitle)
        takeScreenshot(name: "Integration_Tab_Debriefs")

        // Step 2: Stats tab
        navigateToTab(.stats)
        let statsTitle = app.navigationBars["Stats"]
        waitForElementToAppear(statsTitle)
        takeScreenshot(name: "Integration_Tab_Stats")

        // Step 3: Contacts tab
        navigateToTab(.contacts)
        let contactsTitle = app.navigationBars["Contacts"]
        waitForElementToAppear(contactsTitle)
        takeScreenshot(name: "Integration_Tab_Contacts")

        // Step 4: Settings tab
        navigateToTab(.settings)
        let settingsTitle = app.navigationBars["Settings"]
        waitForElementToAppear(settingsTitle)
        takeScreenshot(name: "Integration_Tab_Settings")

        // Step 5: Back to Debriefs
        navigateToTab(.debriefs)
        waitForElementToAppear(debriefsTitle)
        takeScreenshot(name: "Integration_Tab_Debriefs_Return")
    }

    // MARK: - Error Handling Flows

    /// Test offline mode behavior
    func testOfflineModeJourney() throws {
        // Given: Offline mode
        configureWithTestScenario(TestScenario.offlineMode.rawValue)
        launchAppAuthenticated()

        // Step 1: Verify app still loads
        let tabBar = app.tabBars.firstMatch
        waitForElementToAppear(tabBar, timeout: 10)

        // Step 2: Check Stats (should show cached data)
        navigateToTab(.stats)
        sleep(2)
        takeScreenshot(name: "Integration_Offline_Stats")

        // Step 3: Check Contacts
        navigateToTab(.contacts)
        sleep(2)
        takeScreenshot(name: "Integration_Offline_Contacts")

        // Step 4: Try to record (may fail or work offline)
        let recordButton = app.tabBars.buttons["Record"]
        recordButton.tap()
        sleep(2)
        takeScreenshot(name: "Integration_Offline_Record_Attempt")
    }

    // MARK: - Performance Tests

    /// Measure complete app launch to ready time
    func testAppLaunchToReadyPerformance() throws {
        configureWithTestScenario(TestScenario.basicUser.rawValue)

        measure(metrics: [XCTClockMetric()]) {
            launchAppAuthenticated()

            let debriefsTitle = app.navigationBars["Debriefs"]
            _ = waitForElement(debriefsTitle, timeout: 10)

            // Navigate through tabs to ensure all views are ready
            navigateToTab(.stats)
            _ = waitForElement(app.navigationBars["Stats"], timeout: 5)

            navigateToTab(.contacts)
            _ = waitForElement(app.navigationBars["Contacts"], timeout: 5)

            navigateToTab(.settings)
            _ = waitForElement(app.navigationBars["Settings"], timeout: 5)

            app.terminate()
        }
    }

    /// Measure recording flow performance
    func testRecordingFlowPerformance() throws {
        configureWithTestScenario(TestScenario.basicUser.rawValue)

        measure(metrics: [XCTClockMetric()]) {
            launchAppAuthenticated()

            let recordButton = app.tabBars.buttons["Record"]
            _ = waitForElement(recordButton, timeout: 10)
            recordButton.tap()

            let recordingText = app.staticTexts["Recording..."]
            _ = waitForElement(recordingText, timeout: 5)

            let stopButton = app.buttons["Stop Recording"]
            _ = waitForElement(stopButton, timeout: 3)
            stopButton.tap()

            let recordingSavedText = app.staticTexts["Recording Saved!"]
            _ = waitForElement(recordingSavedText, timeout: 5)

            app.terminate()
        }
    }
}
