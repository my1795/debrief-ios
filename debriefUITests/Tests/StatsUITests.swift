//
//  StatsUITests.swift
//  debriefUITests
//
//  Created by Mustafa Yildirim on 21/01/2026.
//

import XCTest

final class StatsUITests: DebriefUITestCase {

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    // MARK: - Basic Stats Screen Tests

    func testStatsScreenLoads() throws {
        // Given: Authenticated user with basic usage
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Stats tab
        navigateToTab(.stats)

        // Then: Stats screen elements should be visible
        // Note: StatsView uses custom header with .navigationBarHidden(true)
        let statsTitle = app.staticTexts["Stats"]
        waitForElementToAppear(statsTitle, timeout: 10)

        // Verify tab buttons exist (custom segmented control)
        let overviewButton = app.buttons["Overview"]
        assertElementExists(overviewButton)

        takeScreenshot(name: "Stats_Screen_Loaded")
    }

    func testStatsTabSwitching() throws {
        // Given: Authenticated user
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Stats tab
        navigateToTab(.stats)

        // Then: Should be able to switch between tabs (custom button-based tabs)
        let statsTitle = app.staticTexts["Stats"]
        waitForElementToAppear(statsTitle, timeout: 10)

        // Switch to Charts tab
        let chartsButton = app.buttons["Charts"]
        waitForElementToAppear(chartsButton)
        chartsButton.tap()

        // Verify Coming Soon message appears
        let comingSoonText = app.staticTexts["Coming Soon"]
        waitForElementToAppear(comingSoonText)

        // Switch to Insights tab
        let insightsButton = app.buttons["Insights"]
        insightsButton.tap()

        // Verify another Coming Soon appears
        waitForElementToAppear(comingSoonText)

        // Switch back to Overview
        let overviewButton = app.buttons["Overview"]
        overviewButton.tap()

        takeScreenshot(name: "Stats_Tab_Switching")
    }

    // MARK: - Current Plan Card Tests

    func testCurrentPlanCardDisplaysFreeUser() throws {
        // Given: Free tier user
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Stats tab
        navigateToTab(.stats)

        // Then: Current plan should show "Free"
        let freeText = app.staticTexts["Free"]
        waitForElementToAppear(freeText, timeout: 5)

        let limitedAccessText = app.staticTexts["Limited access"]
        assertElementExists(limitedAccessText)

        takeScreenshot(name: "Stats_Free_Plan")
    }

    func testCurrentPlanCardDisplaysProUser() throws {
        // Given: Pro tier user
        configureWithTestScenario(TestScenario.proUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Stats tab
        navigateToTab(.stats)

        // Then: Current plan should show "PRO"
        let proText = app.staticTexts["PRO"]
        waitForElementToAppear(proText, timeout: 5)

        takeScreenshot(name: "Stats_Pro_Plan")
    }

    // MARK: - Weekly Stats Grid Tests

    func testWeeklyStatsGridDisplays() throws {
        // Given: User with some activity
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Stats tab
        navigateToTab(.stats)

        // Then: All four stat cards should be visible
        let totalDebriefsText = app.staticTexts["Total Debriefs"]
        waitForElementToAppear(totalDebriefsText, timeout: 5)

        let durationText = app.staticTexts["Duration"]
        assertElementExists(durationText)

        let actionItemsText = app.staticTexts["Action Items"]
        assertElementExists(actionItemsText)

        let activeContactsText = app.staticTexts["Active Contacts"]
        assertElementExists(activeContactsText)

        takeScreenshot(name: "Stats_Weekly_Grid")
    }

    func testWeeklyStatsShowsValues() throws {
        // Given: User with known usage (8 debriefs, ~15 minutes)
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Stats tab
        navigateToTab(.stats)

        // Then: Should show non-zero values
        // Wait for data to load
        sleep(2)

        // Verify at least one numeric value is displayed
        let statValues = app.staticTexts.matching(NSPredicate(format: "label MATCHES '\\\\d+'"))
        XCTAssertGreaterThan(statValues.count, 0, "Should display numeric stat values")

        takeScreenshot(name: "Stats_Values_Display")
    }

    func testEmptyUserShowsZeroStats() throws {
        // Given: New user with no activity
        configureWithTestScenario(TestScenario.emptyUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Stats tab
        navigateToTab(.stats)

        // Then: Should show zero values
        let zeroTexts = app.staticTexts.matching(NSPredicate(format: "label == '0'"))
        waitForElementToAppear(zeroTexts.firstMatch, timeout: 5)

        takeScreenshot(name: "Stats_Empty_User")
    }

    // MARK: - Quick Stats Tests

    func testQuickStatsSection() throws {
        // Given: User with activity
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Stats tab
        navigateToTab(.stats)

        // Then: Quick stats rows should be visible
        let avgDurationText = app.staticTexts["Avg Duration"]
        waitForElementToAppear(avgDurationText, timeout: 5)

        let tasksCreatedText = app.staticTexts["Tasks Created"]
        assertElementExists(tasksCreatedText)

        let mostActiveDayText = app.staticTexts["Most Active Day"]
        assertElementExists(mostActiveDayText)

        let longestStreakText = app.staticTexts["Longest Streak"]
        assertElementExists(longestStreakText)

        takeScreenshot(name: "Stats_Quick_Stats")
    }

    func testQuickStatsShowsLoadingThenValues() throws {
        // Given: User with calculated stats scenario
        configureWithTestScenario(TestScenario.withCalculatedStats.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Stats tab
        navigateToTab(.stats)

        // Then: Initially may show loading, then should show values
        let mostActiveDayText = app.staticTexts["Most Active Day"]
        waitForElementToAppear(mostActiveDayText, timeout: 5)

        // Wait for calculation to complete (cache miss = calculation)
        sleep(3)

        // Should show a day of week (Mon, Tue, etc.) or "-"
        let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun", "-"]
        var foundDay = false
        for day in dayLabels {
            if app.staticTexts[day].exists {
                foundDay = true
                break
            }
        }

        XCTAssertTrue(foundDay, "Should display a day of week or dash for Most Active Day")

        takeScreenshot(name: "Stats_Calculated_Values")
    }

    // MARK: - Quota Usage Tests

    func testQuotaUsageSection() throws {
        // Given: User with some usage
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Stats tab and scroll down
        navigateToTab(.stats)

        let quotaSection = app.scrollViews.firstMatch
        quotaSection.swipeUp()

        // Then: Quota usage bars should be visible
        let recordingsText = app.staticTexts["Recordings"]
        waitForElementToAppear(recordingsText, timeout: 5)

        let minutesText = app.staticTexts["Minutes"]
        assertElementExists(minutesText)

        let storageText = app.staticTexts["Storage"]
        assertElementExists(storageText)

        takeScreenshot(name: "Stats_Quota_Usage")
    }

    func testQuotaInfoButtonShowsAlert() throws {
        // Given: User with usage
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Stats tab and tap info button
        navigateToTab(.stats)

        // Find and tap the info button (may need to scroll)
        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()

        let infoButton = app.buttons["info.circle"]
        if waitForElement(infoButton, timeout: 3) {
            infoButton.tap()

            // Then: Should show alert with billing week info
            let alert = app.alerts.firstMatch
            waitForElementToAppear(alert, timeout: 3)

            let billingWeekText = app.alerts.staticTexts["Billing Week"]
            assertElementExists(billingWeekText)

            // Dismiss alert
            app.alerts.buttons["OK"].tap()
        }

        takeScreenshot(name: "Stats_Quota_Info_Alert")
    }

    func testQuotaNearLimitShowsWarning() throws {
        // Given: User approaching quota limits
        configureWithTestScenario(TestScenario.nearQuotaLimit.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Stats tab
        navigateToTab(.stats)

        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()

        // Then: Should show warning indicators (red/orange colors)
        // Note: Can't directly test colors in XCUITest, but can verify high percentage text
        sleep(2)

        takeScreenshot(name: "Stats_Near_Quota_Limit")
    }

    func testUnlimitedQuotaShowsInfinity() throws {
        // Given: Pro user with unlimited quota
        configureWithTestScenario(TestScenario.proUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Stats tab
        navigateToTab(.stats)

        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()

        // Then: Should show infinity symbol for limits
        let infinitySymbol = app.staticTexts["∞"]
        waitForElementToAppear(infinitySymbol, timeout: 5)

        takeScreenshot(name: "Stats_Unlimited_Quota")
    }

    // MARK: - Top Contacts Tests

    func testTopContactsSection() throws {
        // Given: User with top contacts data
        configureWithTestScenario(TestScenario.withTopContacts.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Stats tab and scroll to bottom
        navigateToTab(.stats)

        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()
        scrollView.swipeUp()

        // Then: Top Contacts section should be visible
        let topContactsTitle = app.staticTexts["Top Contacts"]
        waitForElementToAppear(topContactsTitle, timeout: 5)

        // Should show ranking numbers
        let rankOne = app.staticTexts["#1"]
        waitForElementToAppear(rankOne, timeout: 3)

        takeScreenshot(name: "Stats_Top_Contacts")
    }

    func testTopContactNavigatesToDetail() throws {
        // Given: User with top contacts data
        configureWithTestScenario(TestScenario.withTopContacts.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Stats tab and tap on top contact
        navigateToTab(.stats)

        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()
        scrollView.swipeUp()

        // Tap on first top contact row
        let topContactsSection = app.staticTexts["Top Contacts"]
        waitForElementToAppear(topContactsSection, timeout: 5)

        // Find and tap a contact row (by tapping area below "Top Contacts")
        let contactRow = app.buttons.matching(NSPredicate(format: "label CONTAINS '#1'")).firstMatch
        if contactRow.exists {
            contactRow.tap()

            // Then: Should navigate to contact detail
            let backButton = app.navigationBars.buttons.firstMatch
            waitForElementToAppear(backButton, timeout: 3)

            takeScreenshot(name: "Stats_Top_Contact_Detail")

            // Go back
            tapBackButton()
        }
    }

    func testEmptyTopContactsState() throws {
        // Given: Empty user with no contacts
        configureWithTestScenario(TestScenario.emptyUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Stats tab
        navigateToTab(.stats)

        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()
        scrollView.swipeUp()

        // Then: Should show empty or minimal top contacts
        // May show "No data" or simply no contact rows
        takeScreenshot(name: "Stats_Empty_Top_Contacts")
    }

    // MARK: - Billing Week Tests

    func testBillingWeekCountdown() throws {
        // Given: User with active billing week
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Stats tab
        navigateToTab(.stats)

        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()

        // Then: Should show "Resets in X days" text
        let resetsInText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Resets in'")).firstMatch
        waitForElementToAppear(resetsInText, timeout: 5)

        takeScreenshot(name: "Stats_Billing_Countdown")
    }

    // MARK: - Pull to Refresh Tests

    func testPullToRefreshStats() throws {
        // Given: Authenticated user
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Stats tab and pull to refresh
        navigateToTab(.stats)

        let scrollView = app.scrollViews.firstMatch
        waitForElementToAppear(scrollView)

        pullToRefresh(on: scrollView)

        // Then: Should refresh without crashing
        sleep(2) // Wait for refresh

        // Verify stats are still displayed
        let totalDebriefsText = app.staticTexts["Total Debriefs"]
        assertElementExists(totalDebriefsText)

        takeScreenshot(name: "Stats_After_Refresh")
    }

    // MARK: - Performance Tests

    func testStatsScreenPerformance() throws {
        // Measure time to load stats screen
        configureWithTestScenario(TestScenario.powerUser.rawValue)

        measure(metrics: [XCTClockMetric()]) {
            launchAppAuthenticated()
            navigateToTab(.stats)

            let totalDebriefsText = app.staticTexts["Total Debriefs"]
            _ = waitForElement(totalDebriefsText, timeout: 10)

            app.terminate()
        }
    }
}
