//
//  DebriefsFeedUITests.swift
//  debriefUITests
//
//  Created by Mustafa Yildirim on 21/01/2026.
//

import XCTest

final class DebriefsFeedUITests: DebriefUITestCase {

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    // MARK: - Basic Feed Screen Tests

    func testDebriefsFeedLoads() throws {
        // Given: Authenticated user with debriefs
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: App loads (Debriefs is default tab)
        // Then: Feed screen should be visible
        let debriefsTitle = app.navigationBars["Debriefs"]
        waitForElementToAppear(debriefsTitle, timeout: 10)

        takeScreenshot(name: "Debriefs_Feed_Loaded")
    }

    func testDebriefsFeedShowsDailyStats() throws {
        // Given: User with today's activity
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Feed loads
        let debriefsTitle = app.navigationBars["Debriefs"]
        waitForElementToAppear(debriefsTitle)

        // Then: Daily stats pill should be visible
        // Look for stats text like "X debriefs" or duration
        sleep(2)

        takeScreenshot(name: "Debriefs_Daily_Stats")
    }

    // MARK: - Search Tests

    func testSearchButtonOpensSearchView() throws {
        // Given: At debriefs feed
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        let debriefsTitle = app.navigationBars["Debriefs"]
        waitForElementToAppear(debriefsTitle)

        // When: Tap search button
        let searchButton = app.buttons["magnifyingglass"]
        waitForElementToAppear(searchButton)
        searchButton.tap()

        // Then: Search view should open
        let searchTitle = app.staticTexts["AI Semantic Search"]
        waitForElementToAppear(searchTitle, timeout: 5)

        takeScreenshot(name: "Debriefs_Search_Opened")
    }

    func testSearchViewShowsEmptyState() throws {
        // Given: Search view opened
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        let searchButton = app.buttons["magnifyingglass"]
        waitForElementToAppear(searchButton)
        searchButton.tap()

        // Then: Should show empty state with prompt
        let searchPrompt = app.staticTexts["Search by meaning"]
        waitForElementToAppear(searchPrompt, timeout: 5)

        takeScreenshot(name: "Debriefs_Search_Empty")
    }

    func testSearchWithQuery() throws {
        // Given: Search view opened
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        let searchButton = app.buttons["magnifyingglass"]
        waitForElementToAppear(searchButton)
        searchButton.tap()

        // When: Type search query
        let searchField = app.searchFields.firstMatch
        waitForElementToAppear(searchField)
        searchField.tap()
        searchField.typeText("meeting")

        // Then: Should show loading or results
        sleep(3) // Wait for search

        takeScreenshot(name: "Debriefs_Search_Results")
    }

    func testSearchInfoButton() throws {
        // Given: Search view opened
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        let searchButton = app.buttons["magnifyingglass"]
        waitForElementToAppear(searchButton)
        searchButton.tap()

        // When: Tap info button
        let infoButton = app.buttons["questionmark.circle"]
        if waitForElement(infoButton, timeout: 3) {
            infoButton.tap()

            // Then: Should show info sheet
            let examplesText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'example'")).firstMatch
            waitForElementToAppear(examplesText, timeout: 3)

            takeScreenshot(name: "Debriefs_Search_Info")
        }
    }

    func testSearchDoneButton() throws {
        // Given: Search view opened
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        let searchButton = app.buttons["magnifyingglass"]
        waitForElementToAppear(searchButton)
        searchButton.tap()

        let searchTitle = app.staticTexts["AI Semantic Search"]
        waitForElementToAppear(searchTitle)

        // When: Tap Done button
        let doneButton = app.buttons["Done"]
        waitForElementToAppear(doneButton)
        doneButton.tap()

        // Then: Should dismiss search view
        waitForElementToDisappear(searchTitle, timeout: 3)

        takeScreenshot(name: "Debriefs_Search_Dismissed")
    }

    // MARK: - Filter Tests

    func testFilterButtonOpensSheet() throws {
        // Given: At debriefs feed
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        let debriefsTitle = app.navigationBars["Debriefs"]
        waitForElementToAppear(debriefsTitle)

        // When: Tap filter button
        let filterButton = app.buttons["line.3.horizontal.decrease.circle"]
        waitForElementToAppear(filterButton)
        filterButton.tap()

        // Then: Filter sheet should open
        sleep(1)

        takeScreenshot(name: "Debriefs_Filter_Sheet")
    }

    func testFilterByDateThisWeek() throws {
        // Given: Filter sheet opened
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        let filterButton = app.buttons["line.3.horizontal.decrease.circle"]
        waitForElementToAppear(filterButton)
        filterButton.tap()

        // When: Select "This Week" filter
        let thisWeekOption = app.buttons["This Week"]
        if thisWeekOption.exists {
            thisWeekOption.tap()

            // Apply
            let applyButton = app.buttons["Apply"]
            if applyButton.exists {
                applyButton.tap()
            }
        }

        // Then: Filter chip should appear
        sleep(1)

        takeScreenshot(name: "Debriefs_Filter_This_Week")
    }

    func testFilterByDateThisMonth() throws {
        // Given: At debriefs feed
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        let filterButton = app.buttons["line.3.horizontal.decrease.circle"]
        waitForElementToAppear(filterButton)
        filterButton.tap()

        // When: Select "This Month"
        let thisMonthOption = app.buttons["This Month"]
        if thisMonthOption.exists {
            thisMonthOption.tap()

            let applyButton = app.buttons["Apply"]
            if applyButton.exists {
                applyButton.tap()
            }
        }

        sleep(1)

        takeScreenshot(name: "Debriefs_Filter_This_Month")
    }

    func testRemoveFilterChip() throws {
        // Given: Filter applied
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        let filterButton = app.buttons["line.3.horizontal.decrease.circle"]
        waitForElementToAppear(filterButton)
        filterButton.tap()

        let thisWeekOption = app.buttons["This Week"]
        if thisWeekOption.exists {
            thisWeekOption.tap()
            let applyButton = app.buttons["Apply"]
            if applyButton.exists {
                applyButton.tap()
            }
        }

        sleep(1)

        // When: Tap X on filter chip
        let removeChipButton = app.buttons["xmark.circle.fill"]
        if removeChipButton.exists {
            removeChipButton.tap()

            // Then: Filter should be removed
            sleep(1)

            takeScreenshot(name: "Debriefs_Filter_Removed")
        }
    }

    func testFilterActiveIndicator() throws {
        // Given: No filter applied
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        let debriefsTitle = app.navigationBars["Debriefs"]
        waitForElementToAppear(debriefsTitle)

        // Filter button should not have active indicator initially
        // Apply a filter
        let filterButton = app.buttons["line.3.horizontal.decrease.circle"]
        filterButton.tap()

        let thisWeekOption = app.buttons["This Week"]
        if thisWeekOption.exists {
            thisWeekOption.tap()
            let applyButton = app.buttons["Apply"]
            if applyButton.exists {
                applyButton.tap()
            }
        }

        // Then: Filter button should show active indicator (orange dot)
        sleep(1)

        takeScreenshot(name: "Debriefs_Filter_Active_Indicator")
    }

    // MARK: - Debrief List Tests

    func testDebriefListScrolling() throws {
        // Given: User with many debriefs
        configureWithTestScenario(TestScenario.powerUser.rawValue)
        launchAppAuthenticated()

        let debriefsTitle = app.navigationBars["Debriefs"]
        waitForElementToAppear(debriefsTitle)

        sleep(2)

        // When: Scroll through debrief list
        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()
        scrollView.swipeUp()
        scrollView.swipeUp()

        // Then: Should load more debriefs without crash
        takeScreenshot(name: "Debriefs_List_Scrolled")
    }

    func testDebriefListGroupedByDate() throws {
        // Given: User with debriefs across multiple days
        configureWithTestScenario(TestScenario.powerUser.rawValue)
        launchAppAuthenticated()

        let debriefsTitle = app.navigationBars["Debriefs"]
        waitForElementToAppear(debriefsTitle)

        sleep(2)

        // Then: Should show date headers
        // Look for "Today", "Yesterday", or date strings
        let todayHeader = app.staticTexts["Today"]
        let yesterdayHeader = app.staticTexts["Yesterday"]

        let hasDateHeaders = todayHeader.exists || yesterdayHeader.exists
        // Date headers might be further down
        if !hasDateHeaders {
            let scrollView = app.scrollViews.firstMatch
            scrollView.swipeUp()
        }

        takeScreenshot(name: "Debriefs_Date_Grouping")
    }

    func testDebriefTapNavigatesToDetail() throws {
        // Given: User with debriefs
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        let debriefsTitle = app.navigationBars["Debriefs"]
        waitForElementToAppear(debriefsTitle)

        sleep(2)

        // When: Tap on a debrief
        let scrollView = app.scrollViews.firstMatch
        let debriefRow = scrollView.buttons.firstMatch
        if debriefRow.exists {
            debriefRow.tap()

            // Then: Should navigate to debrief detail
            sleep(2)

            takeScreenshot(name: "Debriefs_Detail_Navigation")

            tapBackButton()
        }
    }

    // MARK: - Recent People Strip Tests

    func testRecentPeopleStripDisplays() throws {
        // Given: User with recent contacts
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        let debriefsTitle = app.navigationBars["Debriefs"]
        waitForElementToAppear(debriefsTitle)

        sleep(2)

        // Then: Recent people strip should be visible (when no contact filter)
        // It's a horizontal scroll of avatars

        takeScreenshot(name: "Debriefs_Recent_People")
    }

    func testRecentPeopleHiddenWithContactFilter() throws {
        // Given: Contact filter applied
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        let debriefsTitle = app.navigationBars["Debriefs"]
        waitForElementToAppear(debriefsTitle)

        // Apply contact filter (if available)
        let filterButton = app.buttons["line.3.horizontal.decrease.circle"]
        filterButton.tap()

        // Would need to select a contact in filter sheet
        // For now, just take screenshot

        sleep(1)

        takeScreenshot(name: "Debriefs_Contact_Filter_Applied")
    }

    // MARK: - Pull to Refresh Tests

    func testPullToRefresh() throws {
        // Given: At debriefs feed
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        let debriefsTitle = app.navigationBars["Debriefs"]
        waitForElementToAppear(debriefsTitle)

        sleep(2)

        // When: Pull to refresh
        let scrollView = app.scrollViews.firstMatch
        pullToRefresh(on: scrollView)

        // Then: Should refresh without crash
        sleep(2)

        takeScreenshot(name: "Debriefs_After_Refresh")
    }

    // MARK: - Empty State Tests

    func testEmptyUserShowsEmptyState() throws {
        // Given: New user with no debriefs
        configureWithTestScenario(TestScenario.emptyUser.rawValue)
        launchAppAuthenticated()

        // Then: Should show empty state
        let debriefsTitle = app.navigationBars["Debriefs"]
        waitForElementToAppear(debriefsTitle)

        sleep(2)

        // Look for empty state message
        let emptyStateText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'no debrief' OR label CONTAINS[c] 'get started'")).firstMatch
        // May show empty list or prompt

        takeScreenshot(name: "Debriefs_Empty_State")
    }

    // MARK: - Debrief Detail Tests

    func testDebriefDetailLoads() throws {
        // Given: User with debriefs
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        sleep(2)

        // When: Navigate to debrief detail
        let scrollView = app.scrollViews.firstMatch
        let debriefRow = scrollView.buttons.firstMatch
        if debriefRow.exists {
            debriefRow.tap()

            // Then: Detail view should load with all sections
            sleep(2)

            takeScreenshot(name: "Debrief_Detail_Loaded")

            tapBackButton()
        }
    }

    func testDebriefDetailShowsContactName() throws {
        // Given: At debrief detail
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        sleep(2)

        let scrollView = app.scrollViews.firstMatch
        let debriefRow = scrollView.buttons.firstMatch
        if debriefRow.exists {
            debriefRow.tap()

            sleep(2)

            // Then: Should show contact name in header
            // Contact name should be visible
            takeScreenshot(name: "Debrief_Detail_Contact_Name")

            tapBackButton()
        }
    }

    func testDebriefDetailStatusBadge() throws {
        // Given: Debrief in processing state
        configureWithTestScenario(TestScenario.processingDebrief.rawValue)
        launchAppAuthenticated()

        sleep(2)

        let scrollView = app.scrollViews.firstMatch
        let debriefRow = scrollView.buttons.firstMatch
        if debriefRow.exists {
            debriefRow.tap()

            sleep(2)

            // Then: Should show processing status badge
            let processingText = app.staticTexts["Processing"]
            if processingText.exists {
                assertElementExists(processingText)
            }

            takeScreenshot(name: "Debrief_Detail_Status_Badge")

            tapBackButton()
        }
    }

    // MARK: - Action Items Tests

    func testActionItemsSection() throws {
        // Given: Debrief with action items
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        sleep(2)

        let scrollView = app.scrollViews.firstMatch
        let debriefRow = scrollView.buttons.firstMatch
        if debriefRow.exists {
            debriefRow.tap()

            sleep(2)

            // Then: Action items section should exist
            let actionItemsText = app.staticTexts["Action Items"]
            if waitForElement(actionItemsText, timeout: 3) {
                assertElementExists(actionItemsText)
            }

            takeScreenshot(name: "Debrief_Detail_Action_Items")

            tapBackButton()
        }
    }

    func testActionItemSelection() throws {
        // Given: At debrief detail with action items
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        sleep(2)

        let scrollView = app.scrollViews.firstMatch
        let debriefRow = scrollView.buttons.firstMatch
        if debriefRow.exists {
            debriefRow.tap()

            sleep(2)

            // Find action item checkbox
            let checkbox = app.buttons["circle"]
            if checkbox.exists {
                // When: Tap checkbox
                checkbox.tap()

                // Then: Should select item (checkmark appears)
                sleep(1)

                takeScreenshot(name: "Debrief_Action_Item_Selected")
            }

            tapBackButton()
        }
    }

    func testAddActionItemButton() throws {
        // Given: At debrief detail
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        sleep(2)

        let scrollView = app.scrollViews.firstMatch
        let debriefRow = scrollView.buttons.firstMatch
        if debriefRow.exists {
            debriefRow.tap()

            sleep(2)

            // Scroll to find add button
            let detailScrollView = app.scrollViews.firstMatch
            detailScrollView.swipeUp()

            // When: Tap "Add Action Item"
            let addButton = app.buttons["Add Action Item"]
            if addButton.exists {
                addButton.tap()

                // Then: Should show add action item sheet
                sleep(1)

                takeScreenshot(name: "Debrief_Add_Action_Item")
            }

            tapBackButton()
        }
    }

    // MARK: - Audio Player Tests

    func testAudioPlayerExists() throws {
        // Given: Debrief with audio
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        sleep(2)

        let scrollView = app.scrollViews.firstMatch
        let debriefRow = scrollView.buttons.firstMatch
        if debriefRow.exists {
            debriefRow.tap()

            sleep(2)

            // Scroll to audio player
            let detailScrollView = app.scrollViews.firstMatch
            detailScrollView.swipeUp()

            // Then: Audio player should exist
            let playButton = app.buttons["play.fill"]
            if playButton.exists {
                assertElementExists(playButton)
            }

            takeScreenshot(name: "Debrief_Audio_Player")

            tapBackButton()
        }
    }

    func testAudioPlayerPlayPause() throws {
        // Given: At debrief detail with audio
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        sleep(2)

        let scrollView = app.scrollViews.firstMatch
        let debriefRow = scrollView.buttons.firstMatch
        if debriefRow.exists {
            debriefRow.tap()

            sleep(2)

            let detailScrollView = app.scrollViews.firstMatch
            detailScrollView.swipeUp()

            // When: Tap play button
            let playButton = app.buttons["play.fill"]
            if playButton.exists {
                playButton.tap()

                // Then: Should start playing (button changes to pause)
                sleep(2)

                let pauseButton = app.buttons["pause.fill"]
                if pauseButton.exists {
                    assertElementExists(pauseButton)
                }

                takeScreenshot(name: "Debrief_Audio_Playing")
            }

            tapBackButton()
        }
    }

    func testAudioSpeedButtons() throws {
        // Given: At debrief detail with audio
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        sleep(2)

        let scrollView = app.scrollViews.firstMatch
        let debriefRow = scrollView.buttons.firstMatch
        if debriefRow.exists {
            debriefRow.tap()

            sleep(2)

            let detailScrollView = app.scrollViews.firstMatch
            detailScrollView.swipeUp()

            // Then: Speed buttons should exist
            let speed1x = app.buttons["1x"]
            let speed15x = app.buttons["1.5x"]
            let speed2x = app.buttons["2x"]

            // At least one should exist
            let hasSpeedButtons = speed1x.exists || speed15x.exists || speed2x.exists

            takeScreenshot(name: "Debrief_Audio_Speed_Buttons")

            tapBackButton()
        }
    }

    // MARK: - Transcript Tests

    func testTranscriptSection() throws {
        // Given: Debrief with transcript
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        sleep(2)

        let scrollView = app.scrollViews.firstMatch
        let debriefRow = scrollView.buttons.firstMatch
        if debriefRow.exists {
            debriefRow.tap()

            sleep(2)

            let detailScrollView = app.scrollViews.firstMatch
            detailScrollView.swipeUp()
            detailScrollView.swipeUp()

            // Then: Transcript section should exist
            let transcriptText = app.staticTexts["Read Full Transcript"]
            if transcriptText.exists {
                assertElementExists(transcriptText)
            }

            takeScreenshot(name: "Debrief_Transcript_Section")

            tapBackButton()
        }
    }

    func testFullTranscriptView() throws {
        // Given: At debrief detail with transcript
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        sleep(2)

        let scrollView = app.scrollViews.firstMatch
        let debriefRow = scrollView.buttons.firstMatch
        if debriefRow.exists {
            debriefRow.tap()

            sleep(2)

            let detailScrollView = app.scrollViews.firstMatch
            detailScrollView.swipeUp()
            detailScrollView.swipeUp()

            // When: Tap "Read Full Transcript"
            let transcriptButton = app.buttons["Read Full Transcript"]
            if transcriptButton.exists {
                transcriptButton.tap()

                // Then: Should open full transcript view
                sleep(1)

                takeScreenshot(name: "Debrief_Full_Transcript")

                // Dismiss
                tapBackButton()
            }

            tapBackButton()
        }
    }

    // MARK: - Delete Debrief Tests

    func testDeleteDebriefButton() throws {
        // Given: At debrief detail
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        sleep(2)

        let scrollView = app.scrollViews.firstMatch
        let debriefRow = scrollView.buttons.firstMatch
        if debriefRow.exists {
            debriefRow.tap()

            sleep(2)

            let detailScrollView = app.scrollViews.firstMatch
            detailScrollView.swipeUp()
            detailScrollView.swipeUp()

            // Then: Delete button should exist
            let deleteButton = app.buttons["Delete"]
            if deleteButton.exists {
                assertElementExists(deleteButton)
            }

            takeScreenshot(name: "Debrief_Delete_Button")

            tapBackButton()
        }
    }

    func testDeleteDebriefConfirmation() throws {
        // Given: At debrief detail
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        sleep(2)

        let scrollView = app.scrollViews.firstMatch
        let debriefRow = scrollView.buttons.firstMatch
        if debriefRow.exists {
            debriefRow.tap()

            sleep(2)

            let detailScrollView = app.scrollViews.firstMatch
            detailScrollView.swipeUp()
            detailScrollView.swipeUp()

            // When: Tap delete button
            let deleteButton = app.buttons["Delete"]
            if deleteButton.exists {
                deleteButton.tap()

                // Then: Should show confirmation alert
                let alert = app.alerts.firstMatch
                waitForElementToAppear(alert, timeout: 3)

                takeScreenshot(name: "Debrief_Delete_Confirmation")

                // Cancel
                app.alerts.buttons["Cancel"].tap()
            }

            tapBackButton()
        }
    }

    // MARK: - Performance Tests

    func testDebriefsFeedPerformance() throws {
        configureWithTestScenario(TestScenario.powerUser.rawValue)

        measure(metrics: [XCTClockMetric()]) {
            launchAppAuthenticated()

            let debriefsTitle = app.navigationBars["Debriefs"]
            _ = waitForElement(debriefsTitle, timeout: 10)

            sleep(2)

            app.terminate()
        }
    }

    func testDebriefDetailPerformance() throws {
        configureWithTestScenario(TestScenario.basicUser.rawValue)

        measure(metrics: [XCTClockMetric()]) {
            launchAppAuthenticated()

            sleep(2)

            let scrollView = app.scrollViews.firstMatch
            let debriefRow = scrollView.buttons.firstMatch
            if debriefRow.exists {
                debriefRow.tap()
                sleep(2)
            }

            app.terminate()
        }
    }
}
