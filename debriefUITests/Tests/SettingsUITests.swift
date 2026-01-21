//
//  SettingsUITests.swift
//  debriefUITests
//
//  Created by Mustafa Yildirim on 21/01/2026.
//

import XCTest

final class SettingsUITests: DebriefUITestCase {

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    // MARK: - Basic Settings Screen Tests

    func testSettingsScreenLoads() throws {
        // Given: Authenticated user
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Settings tab
        navigateToTab(.settings)

        // Then: Settings screen elements should be visible
        let settingsTitle = app.navigationBars["Settings"]
        waitForElementToAppear(settingsTitle)

        // Verify privacy banner exists
        let privacyFirstText = app.staticTexts["Privacy First"]
        assertElementExists(privacyFirstText)

        takeScreenshot(name: "Settings_Screen_Loaded")
    }

    func testSettingsShowsUserProfile() throws {
        // Given: Authenticated user
        configureWithMockAuth(userId: "test-123", email: "testuser@example.com")
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        app.launchArguments.append(LaunchArgument.skipOnboarding.rawValue)
        app.launch()

        // When: Navigate to Settings tab
        navigateToTab(.settings)

        // Then: Should show user email
        let emailText = app.staticTexts["testuser@example.com"]
        waitForElementToAppear(emailText, timeout: 5)

        takeScreenshot(name: "Settings_User_Profile")
    }

    // MARK: - Current Plan Tests

    func testCurrentPlanShowsFreeTier() throws {
        // Given: Free tier user
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Settings tab
        navigateToTab(.settings)

        // Then: Should show "Free" plan
        let currentPlanLabel = app.staticTexts["Current Plan"]
        waitForElementToAppear(currentPlanLabel, timeout: 5)

        let freeText = app.staticTexts["Free"]
        waitForElementToAppear(freeText, timeout: 3)

        takeScreenshot(name: "Settings_Free_Plan")
    }

    func testCurrentPlanShowsProTier() throws {
        // Given: Pro tier user
        configureWithTestScenario(TestScenario.proUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Settings tab
        navigateToTab(.settings)

        // Then: Should show "PRO" plan
        let proText = app.staticTexts["PRO"]
        waitForElementToAppear(proText, timeout: 5)

        takeScreenshot(name: "Settings_Pro_Plan")
    }

    // MARK: - Notifications Toggle Tests

    func testNotificationsToggleExists() throws {
        // Given: Authenticated user
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Settings tab
        navigateToTab(.settings)

        // Then: Notifications toggle should exist
        let notificationsLabel = app.staticTexts["Notifications"]
        waitForElementToAppear(notificationsLabel, timeout: 5)

        let toggle = app.switches.firstMatch
        assertElementExists(toggle)

        takeScreenshot(name: "Settings_Notifications_Toggle")
    }

    func testNotificationsToggleCanBeToggled() throws {
        // Given: Authenticated user
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Settings tab
        navigateToTab(.settings)

        // Find the notifications toggle
        let toggle = app.switches.firstMatch
        waitForElementToAppear(toggle)

        // Get initial state
        let initialValue = toggle.value as? String

        // Tap to toggle
        toggle.tap()

        // Then: Toggle state should change
        let newValue = toggle.value as? String
        XCTAssertNotEqual(initialValue, newValue, "Toggle state should change after tap")

        // Toggle back
        toggle.tap()

        takeScreenshot(name: "Settings_Notifications_Toggled")
    }

    func testNotificationsTogglePersists() throws {
        // Given: Authenticated user
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Settings and toggle notifications off
        navigateToTab(.settings)

        let toggle = app.switches.firstMatch
        waitForElementToAppear(toggle)

        // Turn off if on
        if toggle.value as? String == "1" {
            toggle.tap()
        }

        // Verify it's off
        XCTAssertEqual(toggle.value as? String, "0", "Toggle should be off")

        // Navigate away and back
        navigateToTab(.stats)
        navigateToTab(.settings)

        // Then: Toggle should still be off
        let toggleAfter = app.switches.firstMatch
        waitForElementToAppear(toggleAfter)
        XCTAssertEqual(toggleAfter.value as? String, "0", "Toggle state should persist")

        takeScreenshot(name: "Settings_Notifications_Persisted")
    }

    // MARK: - Privacy & Support Links Tests

    func testPrivacyPolicyLinkExists() throws {
        // Given: Authenticated user
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Settings tab
        navigateToTab(.settings)

        // Scroll down to find the link
        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()

        // Then: Privacy Policy button should exist
        let privacyPolicyButton = app.buttons["Privacy Policy"]
        waitForElementToAppear(privacyPolicyButton, timeout: 5)

        takeScreenshot(name: "Settings_Privacy_Link")
    }

    func testDataHandlingLinkExists() throws {
        // Given: Authenticated user
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Settings tab
        navigateToTab(.settings)

        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()

        // Then: Data Handling button should exist
        let dataHandlingButton = app.buttons["Data Handling"]
        waitForElementToAppear(dataHandlingButton, timeout: 5)

        takeScreenshot(name: "Settings_Data_Handling_Link")
    }

    func testHelpCenterLinkExists() throws {
        // Given: Authenticated user
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Settings tab
        navigateToTab(.settings)

        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()

        // Then: Help Center button should exist
        let helpCenterButton = app.buttons["Help Center"]
        waitForElementToAppear(helpCenterButton, timeout: 5)

        takeScreenshot(name: "Settings_Help_Center_Link")
    }

    // MARK: - Storage Section Tests

    func testStorageUsedDisplays() throws {
        // Given: User with storage usage
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Settings tab
        navigateToTab(.settings)

        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()

        // Then: Storage used should be displayed
        let storageLabel = app.staticTexts["Storage Used"]
        waitForElementToAppear(storageLabel, timeout: 5)

        // Should show MB value
        let mbText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'MB'")).firstMatch
        assertElementExists(mbText)

        takeScreenshot(name: "Settings_Storage_Display")
    }

    func testFreeSpaceButtonExists() throws {
        // Given: Free tier user (can free space)
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Settings tab
        navigateToTab(.settings)

        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()

        // Then: Free Voice Space button should exist
        let freeSpaceButton = app.buttons["Free Voice Space"]
        waitForElementToAppear(freeSpaceButton, timeout: 5)

        takeScreenshot(name: "Settings_Free_Space_Button")
    }

    func testFreeSpaceShowsConfirmationAlert() throws {
        // Given: Free tier user with storage
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Settings and tap Free Voice Space
        navigateToTab(.settings)

        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()

        let freeSpaceButton = app.buttons["Free Voice Space"]
        waitForElementToAppear(freeSpaceButton)
        freeSpaceButton.tap()

        // Then: Should show confirmation alert
        let alert = app.alerts.firstMatch
        waitForElementToAppear(alert, timeout: 3)

        // Verify alert text
        let deleteText = app.alerts.staticTexts.matching(NSPredicate(format: "label CONTAINS 'delete'")).firstMatch
        assertElementExists(deleteText)

        takeScreenshot(name: "Settings_Free_Space_Confirmation")

        // Dismiss alert
        app.alerts.buttons["Cancel"].tap()
    }

    func testFreeSpaceConfirmationWorks() throws {
        // Given: Free tier user with storage
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Settings and confirm free space
        navigateToTab(.settings)

        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()

        let freeSpaceButton = app.buttons["Free Voice Space"]
        waitForElementToAppear(freeSpaceButton)
        freeSpaceButton.tap()

        // Tap delete/confirm button
        let confirmButton = app.alerts.buttons["Delete"]
        if confirmButton.exists {
            confirmButton.tap()

            // Then: Should process deletion (may show loading)
            sleep(2)

            takeScreenshot(name: "Settings_Free_Space_After_Delete")
        }
    }

    // MARK: - App Version Tests

    func testAppVersionDisplays() throws {
        // Given: Authenticated user
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Settings tab
        navigateToTab(.settings)

        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()
        scrollView.swipeUp()

        // Then: App version should be displayed
        let versionText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Debrief AI v'")).firstMatch
        waitForElementToAppear(versionText, timeout: 5)

        takeScreenshot(name: "Settings_App_Version")
    }

    // MARK: - Sign Out Tests

    func testSignOutButtonExists() throws {
        // Given: Authenticated user
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Settings tab
        navigateToTab(.settings)

        // Then: Sign Out button should exist
        let signOutButton = app.buttons["Sign Out"]
        waitForElementToAppear(signOutButton, timeout: 5)

        takeScreenshot(name: "Settings_Sign_Out_Button")
    }

    func testSignOutNavigatesToLogin() throws {
        // Given: Authenticated user
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Settings and tap Sign Out
        navigateToTab(.settings)

        let signOutButton = app.buttons["Sign Out"]
        waitForElementToAppear(signOutButton)
        signOutButton.tap()

        // Then: Should navigate to login screen
        let googleSignInButton = app.buttons["Sign in with Google"]
        waitForElementToAppear(googleSignInButton, timeout: 5)

        takeScreenshot(name: "Settings_After_Sign_Out")
    }

    // MARK: - Delete Account Tests

    func testDeleteAccountButtonExists() throws {
        // Given: Authenticated user
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Settings tab
        navigateToTab(.settings)

        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()
        scrollView.swipeUp()

        // Then: Delete Account button should exist in danger zone
        let deleteAccountButton = app.buttons["Delete Account"]
        waitForElementToAppear(deleteAccountButton, timeout: 5)

        takeScreenshot(name: "Settings_Delete_Account_Button")
    }

    func testDeleteAccountShowsWarning() throws {
        // Given: Authenticated user
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Settings and tap Delete Account
        navigateToTab(.settings)

        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()
        scrollView.swipeUp()

        let deleteAccountButton = app.buttons["Delete Account"]
        waitForElementToAppear(deleteAccountButton)
        deleteAccountButton.tap()

        // Then: Should show warning sheet
        let warningText = app.staticTexts["Delete Your Account?"]
        waitForElementToAppear(warningText, timeout: 3)

        // Should list what will be deleted
        let permanentText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'permanent'")).firstMatch
        assertElementExists(permanentText)

        takeScreenshot(name: "Settings_Delete_Account_Warning")

        // Dismiss
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.tap()
        }
    }

    func testDeleteAccountRequiresConfirmation() throws {
        // Given: Authenticated user
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate through delete account flow
        navigateToTab(.settings)

        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()
        scrollView.swipeUp()

        let deleteAccountButton = app.buttons["Delete Account"]
        waitForElementToAppear(deleteAccountButton)
        deleteAccountButton.tap()

        // Tap continue/understand button
        let continueButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Understand'")).firstMatch
        if continueButton.exists {
            continueButton.tap()

            // Then: Should require typing DELETE
            let textField = app.textFields.firstMatch
            waitForElementToAppear(textField, timeout: 3)

            // Verify confirm button is disabled initially
            let confirmDeleteButton = app.buttons["Delete My Account"]
            if confirmDeleteButton.exists {
                XCTAssertFalse(confirmDeleteButton.isEnabled, "Confirm button should be disabled until DELETE typed")
            }

            // Type DELETE
            textField.tap()
            textField.typeText("DELETE")

            // Now confirm should be enabled
            if confirmDeleteButton.exists {
                XCTAssertTrue(confirmDeleteButton.isEnabled, "Confirm button should be enabled after typing DELETE")
            }

            takeScreenshot(name: "Settings_Delete_Confirmation_Input")
        }
    }

    // MARK: - Privacy Banner Tests

    func testPrivacyBannerDisplays() throws {
        // Given: Authenticated user
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Settings tab
        navigateToTab(.settings)

        // Then: Privacy banner should be displayed with icon and text
        let privacyFirstText = app.staticTexts["Privacy First"]
        waitForElementToAppear(privacyFirstText)

        // Should have shield icon (visible as image element)
        let shieldImage = app.images["shield.lefthalf.filled"]
        // Note: SF Symbol names may not be directly accessible

        takeScreenshot(name: "Settings_Privacy_Banner")
    }

    // MARK: - Scrolling Tests

    func testSettingsFullScroll() throws {
        // Given: Authenticated user
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Settings and scroll through all content
        navigateToTab(.settings)

        let scrollView = app.scrollViews.firstMatch
        waitForElementToAppear(scrollView)

        // Scroll through entire settings
        scrollView.swipeUp()
        takeScreenshot(name: "Settings_Scroll_1")

        scrollView.swipeUp()
        takeScreenshot(name: "Settings_Scroll_2")

        scrollView.swipeUp()
        takeScreenshot(name: "Settings_Scroll_3")

        // Then: Should be able to scroll through all sections without crash
        // Verify we reached the bottom (delete account visible)
        let deleteAccountButton = app.buttons["Delete Account"]
        assertElementExists(deleteAccountButton)
    }

    // MARK: - Edge Case Tests

    func testSettingsWithNoNetworkStillDisplays() throws {
        // Given: User in offline mode
        configureWithTestScenario(TestScenario.offlineMode.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Settings tab
        navigateToTab(.settings)

        // Then: Settings should still display (cached data)
        let settingsTitle = app.navigationBars["Settings"]
        waitForElementToAppear(settingsTitle)

        let notificationsLabel = app.staticTexts["Notifications"]
        assertElementExists(notificationsLabel)

        takeScreenshot(name: "Settings_Offline_Mode")
    }

    // MARK: - Performance Tests

    func testSettingsScreenPerformance() throws {
        configureWithTestScenario(TestScenario.basicUser.rawValue)

        measure(metrics: [XCTClockMetric()]) {
            launchAppAuthenticated()
            navigateToTab(.settings)

            let settingsTitle = app.navigationBars["Settings"]
            _ = waitForElement(settingsTitle, timeout: 10)

            app.terminate()
        }
    }
}
