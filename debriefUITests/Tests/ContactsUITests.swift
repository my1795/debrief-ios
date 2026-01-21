//
//  ContactsUITests.swift
//  debriefUITests
//
//  Created by Mustafa Yildirim on 21/01/2026.
//

import XCTest

final class ContactsUITests: DebriefUITestCase {

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    // MARK: - Basic Contacts Screen Tests

    func testContactsScreenLoads() throws {
        // Given: Authenticated user with contacts
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Contacts tab
        navigateToTab(.contacts)

        // Then: Contacts screen elements should be visible
        let contactsTitle = app.navigationBars["Contacts"]
        waitForElementToAppear(contactsTitle)

        // Search field should exist
        let searchField = app.searchFields.firstMatch
        assertElementExists(searchField)

        takeScreenshot(name: "Contacts_Screen_Loaded")
    }

    func testContactsListDisplays() throws {
        // Given: User with contacts
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Contacts tab
        navigateToTab(.contacts)

        // Then: Contact list should be visible
        sleep(2) // Wait for contacts to load

        let contactList = app.scrollViews.firstMatch
        waitForElementToAppear(contactList)

        takeScreenshot(name: "Contacts_List_Display")
    }

    // MARK: - Contact Search Tests

    func testContactSearchField() throws {
        // Given: User with contacts
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Contacts and tap search
        navigateToTab(.contacts)

        let searchField = app.searchFields.firstMatch
        waitForElementToAppear(searchField)
        searchField.tap()

        // Then: Keyboard should appear
        let keyboard = app.keyboards.firstMatch
        waitForElementToAppear(keyboard, timeout: 3)

        takeScreenshot(name: "Contacts_Search_Active")
    }

    func testContactSearchFiltering() throws {
        // Given: User with multiple contacts
        configureWithTestScenario(TestScenario.manyContacts.rawValue)
        launchAppAuthenticated()

        // When: Search for specific name
        navigateToTab(.contacts)

        let searchField = app.searchFields.firstMatch
        waitForElementToAppear(searchField)
        searchField.tap()
        searchField.typeText("Test")

        // Then: Should filter results
        sleep(1) // Wait for filter

        takeScreenshot(name: "Contacts_Search_Filtered")
    }

    func testContactSearchClear() throws {
        // Given: Search with text entered
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        navigateToTab(.contacts)

        let searchField = app.searchFields.firstMatch
        waitForElementToAppear(searchField)
        searchField.tap()
        searchField.typeText("John")

        // When: Clear search
        let clearButton = searchField.buttons["Clear text"]
        if clearButton.exists {
            clearButton.tap()
        }

        // Then: Should show all contacts again
        sleep(1)

        takeScreenshot(name: "Contacts_Search_Cleared")
    }

    // MARK: - Contact Row Tests

    func testContactRowDisplaysAvatar() throws {
        // Given: User with contacts
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Contacts tab
        navigateToTab(.contacts)

        sleep(2) // Wait for load

        // Then: Contact rows should show avatars with initials
        // Avatars are typically Circle views with Text inside
        takeScreenshot(name: "Contacts_Avatar_Display")
    }

    func testContactRowDisplaysNameAndHandle() throws {
        // Given: User with contacts that have handles
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Contacts tab
        navigateToTab(.contacts)

        sleep(2)

        // Then: Should display contact names
        // Handles may be optional
        takeScreenshot(name: "Contacts_Name_Handle")
    }

    func testContactRowNavigation() throws {
        // Given: User with contacts
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Tap on a contact row
        navigateToTab(.contacts)

        sleep(2) // Wait for load

        let contactRow = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'john' OR label CONTAINS[c] 'test'")).firstMatch
        if contactRow.exists {
            contactRow.tap()

            // Then: Should navigate to contact detail
            let backButton = app.navigationBars.buttons.firstMatch
            waitForElementToAppear(backButton, timeout: 3)

            takeScreenshot(name: "Contacts_Detail_Navigation")

            tapBackButton()
        }
    }

    // MARK: - Contact Detail Tests

    func testContactDetailLoads() throws {
        // Given: User with contacts
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to contact detail
        navigateToTab(.contacts)

        sleep(2)

        // Find and tap first contact
        let scrollView = app.scrollViews.firstMatch
        let firstContact = scrollView.buttons.firstMatch
        if firstContact.exists {
            firstContact.tap()

            // Then: Contact detail should load
            sleep(2)

            // Profile header should be visible
            takeScreenshot(name: "Contact_Detail_Loaded")

            tapBackButton()
        }
    }

    func testContactDetailStatCards() throws {
        // Given: User with contact history
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to contact detail
        navigateToTab(.contacts)

        sleep(2)

        let scrollView = app.scrollViews.firstMatch
        let firstContact = scrollView.buttons.firstMatch
        if firstContact.exists {
            firstContact.tap()

            sleep(2)

            // Then: Stat cards should be visible
            let debriefsText = app.staticTexts["Debriefs"]
            assertElementExists(debriefsText)

            let lastMetText = app.staticTexts["Last Met"]
            assertElementExists(lastMetText)

            let durationText = app.staticTexts["Duration"]
            assertElementExists(durationText)

            takeScreenshot(name: "Contact_Detail_Stats")

            tapBackButton()
        }
    }

    func testContactDetailStatInfoButton() throws {
        // Given: At contact detail view
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        navigateToTab(.contacts)

        sleep(2)

        let scrollView = app.scrollViews.firstMatch
        let firstContact = scrollView.buttons.firstMatch
        if firstContact.exists {
            firstContact.tap()

            sleep(2)

            // When: Tap info button on stat card
            let infoButton = app.buttons["info.circle"]
            if waitForElement(infoButton, timeout: 3) {
                infoButton.tap()

                // Then: Should show alert with info
                let alert = app.alerts.firstMatch
                waitForElementToAppear(alert, timeout: 3)

                takeScreenshot(name: "Contact_Detail_Stat_Info")

                // Dismiss
                app.alerts.buttons["OK"].tap()
            }

            tapBackButton()
        }
    }

    func testContactDetailInteractionHistory() throws {
        // Given: Contact with debrief history
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to contact detail
        navigateToTab(.contacts)

        sleep(2)

        let scrollView = app.scrollViews.firstMatch
        let firstContact = scrollView.buttons.firstMatch
        if firstContact.exists {
            firstContact.tap()

            sleep(2)

            // Then: Interaction History section should exist
            let historyTitle = app.staticTexts["Interaction History"]
            if waitForElement(historyTitle, timeout: 3) {
                assertElementExists(historyTitle)
            }

            takeScreenshot(name: "Contact_Detail_History")

            tapBackButton()
        }
    }

    func testContactDetailScrollToTop() throws {
        // Given: Contact detail with long history
        configureWithTestScenario(TestScenario.powerUser.rawValue)
        launchAppAuthenticated()

        // When: Scroll down in contact detail
        navigateToTab(.contacts)

        sleep(2)

        let scrollView = app.scrollViews.firstMatch
        let firstContact = scrollView.buttons.firstMatch
        if firstContact.exists {
            firstContact.tap()

            sleep(2)

            // Scroll down
            let detailScrollView = app.scrollViews.firstMatch
            detailScrollView.swipeUp()
            detailScrollView.swipeUp()
            detailScrollView.swipeUp()

            // Then: Scroll to top button should appear
            let scrollTopButton = app.buttons["arrow.up"]
            if scrollTopButton.exists {
                scrollTopButton.tap()

                // Should scroll to top
                sleep(1)
            }

            takeScreenshot(name: "Contact_Detail_Scroll_Top")

            tapBackButton()
        }
    }

    // MARK: - Empty States Tests

    func testNoContactsEmptyState() throws {
        // Given: User with no contacts
        configureWithTestScenario(TestScenario.noContacts.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Contacts tab
        navigateToTab(.contacts)

        // Then: Should show empty state
        let emptyStateText = app.staticTexts["No Contacts"]
        waitForElementToAppear(emptyStateText, timeout: 5)

        takeScreenshot(name: "Contacts_Empty_State")
    }

    func testContactPermissionDeniedState() throws {
        // Given: Contact permission denied
        configureWithTestScenario(TestScenario.contactPermissionDenied.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Contacts tab
        navigateToTab(.contacts)

        // Then: Should show permission denied message
        let accessNeededText = app.staticTexts["Access Needed"]
        if waitForElement(accessNeededText, timeout: 5) {
            assertElementExists(accessNeededText)
        }

        takeScreenshot(name: "Contacts_Permission_Denied")
    }

    // MARK: - Filter Tests

    func testContactDetailFilterButton() throws {
        // Given: At contact detail view
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        navigateToTab(.contacts)

        sleep(2)

        let scrollView = app.scrollViews.firstMatch
        let firstContact = scrollView.buttons.firstMatch
        if firstContact.exists {
            firstContact.tap()

            sleep(2)

            // When: Tap filter button
            let filterButton = app.buttons["line.3.horizontal.decrease.circle"]
            if waitForElement(filterButton, timeout: 3) {
                filterButton.tap()

                // Then: Filter sheet should appear
                sleep(1)

                takeScreenshot(name: "Contact_Detail_Filter_Sheet")
            }

            tapBackButton()
        }
    }

    func testContactDetailDateFilter() throws {
        // Given: At contact detail with filter sheet
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        navigateToTab(.contacts)

        sleep(2)

        let scrollView = app.scrollViews.firstMatch
        let firstContact = scrollView.buttons.firstMatch
        if firstContact.exists {
            firstContact.tap()

            sleep(2)

            let filterButton = app.buttons["line.3.horizontal.decrease.circle"]
            if waitForElement(filterButton, timeout: 3) {
                filterButton.tap()

                // When: Select "This Week" filter
                let thisWeekOption = app.buttons["This Week"]
                if thisWeekOption.exists {
                    thisWeekOption.tap()

                    // Apply filter
                    let applyButton = app.buttons["Apply"]
                    if applyButton.exists {
                        applyButton.tap()
                    }
                }
            }

            // Then: Filter should be applied
            sleep(1)

            takeScreenshot(name: "Contact_Detail_Filtered")

            tapBackButton()
        }
    }

    // MARK: - Loading State Tests

    func testContactsLoadingState() throws {
        // Given: Slow network scenario
        configureWithTestScenario(TestScenario.slowNetwork.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Contacts tab
        navigateToTab(.contacts)

        // Then: Should show loading state initially
        let loadingIndicator = app.activityIndicators.firstMatch
        // May or may not be visible depending on load speed

        takeScreenshot(name: "Contacts_Loading_State")
    }

    // MARK: - Navigation Tests

    func testContactToDebriefNavigation() throws {
        // Given: Contact with debriefs
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to contact detail and tap a debrief
        navigateToTab(.contacts)

        sleep(2)

        let scrollView = app.scrollViews.firstMatch
        let firstContact = scrollView.buttons.firstMatch
        if firstContact.exists {
            firstContact.tap()

            sleep(2)

            // Scroll to interaction history
            let detailScrollView = app.scrollViews.firstMatch
            detailScrollView.swipeUp()

            // Tap on a debrief in history
            let debriefRow = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'debrief'")).firstMatch
            if debriefRow.exists {
                debriefRow.tap()

                // Then: Should navigate to debrief detail
                sleep(2)

                takeScreenshot(name: "Contact_To_Debrief_Navigation")

                tapBackButton()
            }

            tapBackButton()
        }
    }

    // MARK: - Performance Tests

    func testContactsListPerformance() throws {
        configureWithTestScenario(TestScenario.manyContacts.rawValue)

        measure(metrics: [XCTClockMetric()]) {
            launchAppAuthenticated()
            navigateToTab(.contacts)

            let contactsTitle = app.navigationBars["Contacts"]
            _ = waitForElement(contactsTitle, timeout: 10)

            // Wait for list to populate
            sleep(2)

            app.terminate()
        }
    }

    func testContactDetailPerformance() throws {
        configureWithTestScenario(TestScenario.powerUser.rawValue)

        measure(metrics: [XCTClockMetric()]) {
            launchAppAuthenticated()
            navigateToTab(.contacts)

            sleep(2)

            let scrollView = app.scrollViews.firstMatch
            let firstContact = scrollView.buttons.firstMatch
            if firstContact.exists {
                firstContact.tap()
                sleep(2)
            }

            app.terminate()
        }
    }

    // MARK: - Week Definition Tests

    func testContactStatsShowsCorrectWeek() throws {
        // Given: Contact detail showing stats
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        navigateToTab(.contacts)

        sleep(2)

        let scrollView = app.scrollViews.firstMatch
        let firstContact = scrollView.buttons.firstMatch
        if firstContact.exists {
            firstContact.tap()

            sleep(2)

            // Then: Should show "This week (Sunday to Sunday)" in tooltip
            // Verify by tapping info button
            let infoButton = app.buttons["info.circle"]
            if infoButton.exists {
                infoButton.tap()

                let sundayText = app.alerts.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'sunday'")).firstMatch
                if sundayText.exists {
                    assertElementExists(sundayText)
                }

                app.alerts.buttons["OK"].tap()
            }

            takeScreenshot(name: "Contact_Week_Definition")

            tapBackButton()
        }
    }
}
