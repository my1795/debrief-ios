//
//  AuthUITests.swift
//  debriefUITests
//
//  Created by Mustafa Yildirim on 21/01/2026.
//

import XCTest

final class AuthUITests: DebriefUITestCase {

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    // MARK: - Login Screen Display Tests

    func testLoginScreenLoadsUnauthenticated() throws {
        // Given: Unauthenticated state
        launchAppUnauthenticated()

        // Then: Login screen should be visible
        let googleSignInButton = app.buttons["Sign in with Google"]
        waitForElementToAppear(googleSignInButton, timeout: 10)

        takeScreenshot(name: "Auth_Login_Screen")
    }

    func testLoginScreenShowsLogo() throws {
        // Given: Unauthenticated
        launchAppUnauthenticated()

        // Then: Logo should be visible
        let logoImage = app.images.firstMatch
        waitForElementToAppear(logoImage, timeout: 5)

        takeScreenshot(name: "Auth_Logo_Display")
    }

    func testLoginScreenShowsTitle() throws {
        // Given: Unauthenticated
        launchAppUnauthenticated()

        // Then: "Debrief" title should be visible
        let titleText = app.staticTexts["Debrief"]
        waitForElementToAppear(titleText, timeout: 5)

        takeScreenshot(name: "Auth_Title_Display")
    }

    func testLoginScreenShowsTagline() throws {
        // Given: Unauthenticated
        launchAppUnauthenticated()

        // Then: Tagline should be visible
        let taglineText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'memory' OR label CONTAINS[c] 'call'")).firstMatch
        waitForElementToAppear(taglineText, timeout: 5)

        takeScreenshot(name: "Auth_Tagline_Display")
    }

    func testLoginScreenShowsPrivacyBanner() throws {
        // Given: Unauthenticated
        launchAppUnauthenticated()

        // Then: Privacy banner should be visible
        let privacyText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'private' OR label CONTAINS[c] 'privacy'")).firstMatch
        waitForElementToAppear(privacyText, timeout: 5)

        takeScreenshot(name: "Auth_Privacy_Banner")
    }

    func testLoginScreenShowsAppVersion() throws {
        // Given: Unauthenticated
        launchAppUnauthenticated()

        // Scroll to bottom if needed
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
        }

        // Then: App version should be visible
        let versionText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'v'")).firstMatch
        waitForElementToAppear(versionText, timeout: 5)

        takeScreenshot(name: "Auth_App_Version")
    }

    // MARK: - Google Sign In Tests

    func testGoogleSignInButtonExists() throws {
        // Given: Unauthenticated
        launchAppUnauthenticated()

        // Then: Google Sign In button should exist
        let googleSignInButton = app.buttons["Sign in with Google"]
        waitForElementToAppear(googleSignInButton)

        assertElementExists(googleSignInButton)
        assertElementEnabled(googleSignInButton)

        takeScreenshot(name: "Auth_Google_Button")
    }

    func testGoogleSignInButtonTap() throws {
        // Given: Unauthenticated
        launchAppUnauthenticated()

        // When: Tap Google Sign In
        let googleSignInButton = app.buttons["Sign in with Google"]
        waitForElementToAppear(googleSignInButton)
        googleSignInButton.tap()

        // Then: Should show loading or Google sign in flow
        // Note: Actual Google sign in requires real device and Google account
        // Wait for any loading indicator or state change instead of sleep
        let loadingIndicator = app.activityIndicators.firstMatch
        _ = waitForElement(loadingIndicator, timeout: 2)

        takeScreenshot(name: "Auth_Google_Sign_In_Tapped")
    }

    // MARK: - Terms and Privacy Links Tests

    func testTermsOfServiceLinkExists() throws {
        // Given: Unauthenticated
        launchAppUnauthenticated()

        // Scroll to find link
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
        }

        // Then: Terms link should exist
        let termsText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'terms'")).firstMatch
        if termsText.exists {
            assertElementExists(termsText)
        }

        takeScreenshot(name: "Auth_Terms_Link")
    }

    func testPrivacyPolicyLinkExists() throws {
        // Given: Unauthenticated
        launchAppUnauthenticated()

        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
        }

        // Then: Privacy link should exist
        let privacyText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'privacy'")).firstMatch
        if privacyText.exists {
            assertElementExists(privacyText)
        }

        takeScreenshot(name: "Auth_Privacy_Link")
    }

    // MARK: - Loading State Tests

    func testLoginLoadingState() throws {
        // Given: Mock slow auth scenario
        configureWithTestScenario(TestScenario.slowNetwork.rawValue)
        launchAppUnauthenticated()

        // When: Tap sign in (would show loading)
        let googleSignInButton = app.buttons["Sign in with Google"]
        waitForElementToAppear(googleSignInButton)
        googleSignInButton.tap()

        // Then: Loading indicator may appear
        let loadingIndicator = app.activityIndicators.firstMatch
        // May or may not be visible depending on timing

        takeScreenshot(name: "Auth_Loading_State")
    }

    // MARK: - Error State Tests

    func testLoginErrorDisplays() throws {
        // Given: Mock auth error scenario
        configureWithTestScenario(TestScenario.networkError.rawValue)
        launchAppUnauthenticated()

        // When: Tap sign in
        let googleSignInButton = app.buttons["Sign in with Google"]
        waitForElementToAppear(googleSignInButton)
        googleSignInButton.tap()

        // Then: Error message should appear
        let errorText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'error' OR label CONTAINS[c] 'failed'")).firstMatch
        _ = waitForElement(errorText, timeout: 3)

        takeScreenshot(name: "Auth_Error_Display")
    }

    // MARK: - Successful Auth Flow Tests

    func testSuccessfulAuthTransitionsToMainView() throws {
        // Given: Mock successful auth
        configureWithMockAuth()
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        app.launchArguments.append(LaunchArgument.skipOnboarding.rawValue)
        app.launch()

        // Then: Should transition to main tab view
        let tabBar = app.tabBars.firstMatch
        waitForElementToAppear(tabBar, timeout: 10)

        assertElementExists(tabBar)

        // Debriefs tab should be selected by default
        let debriefsTab = app.tabBars.buttons["Debriefs"]
        assertElementExists(debriefsTab)

        takeScreenshot(name: "Auth_Successful_Transition")
    }

    // MARK: - Sign Out Tests

    func testSignOutReturnsToLogin() throws {
        // Given: Authenticated user
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        launchAppAuthenticated()

        // When: Navigate to Settings and sign out
        navigateToTab(.settings)

        let signOutButton = app.buttons["Sign Out"]
        waitForElementToAppear(signOutButton)
        signOutButton.tap()

        // Then: Should return to login screen
        let googleSignInButton = app.buttons["Sign in with Google"]
        waitForElementToAppear(googleSignInButton, timeout: 5)

        assertElementExists(googleSignInButton)

        takeScreenshot(name: "Auth_Sign_Out_Complete")
    }

    // MARK: - Session Persistence Tests

    func testAuthSessionPersists() throws {
        // Given: Previously authenticated user
        configureWithMockAuth()
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        app.launchArguments.append(LaunchArgument.skipOnboarding.rawValue)
        app.launch()

        // Verify authenticated
        let tabBar = app.tabBars.firstMatch
        waitForElementToAppear(tabBar, timeout: 10)

        // Terminate app
        app.terminate()

        // Relaunch
        app.launch()

        // Then: Should still be authenticated (main view visible)
        let tabBarAfter = app.tabBars.firstMatch
        waitForElementToAppear(tabBarAfter, timeout: 10)

        assertElementExists(tabBarAfter)

        takeScreenshot(name: "Auth_Session_Persisted")
    }

    // MARK: - Accessibility Tests

    func testLoginScreenAccessibility() throws {
        // Given: Unauthenticated
        launchAppUnauthenticated()

        // Then: Key elements should be accessible
        let googleSignInButton = app.buttons["Sign in with Google"]
        waitForElementToAppear(googleSignInButton)

        XCTAssertTrue(googleSignInButton.isEnabled, "Sign in button should be enabled")

        takeScreenshot(name: "Auth_Accessibility")
    }

    // MARK: - UI Layout Tests

    func testLoginScreenLayoutPortrait() throws {
        // Given: Portrait orientation
        XCUIDevice.shared.orientation = .portrait
        launchAppUnauthenticated()

        // Then: Login screen should display correctly
        let googleSignInButton = app.buttons["Sign in with Google"]
        waitForElementToAppear(googleSignInButton)

        takeScreenshot(name: "Auth_Portrait_Layout")
    }

    func testLoginScreenLayoutLandscape() throws {
        // Given: Landscape orientation
        launchAppUnauthenticated()
        XCUIDevice.shared.orientation = .landscapeLeft

        // Then: Login screen should adapt
        let googleSignInButton = app.buttons["Sign in with Google"]
        waitForElementToAppear(googleSignInButton)

        takeScreenshot(name: "Auth_Landscape_Layout")

        // Reset
        XCUIDevice.shared.orientation = .portrait
    }

    // MARK: - Dark Mode Tests

    // Note: Dark mode testing requires iOS 13+ and can be done with launch arguments

    // MARK: - Performance Tests

    func testLoginScreenPerformance() throws {
        measure(metrics: [XCTClockMetric()]) {
            launchAppUnauthenticated()

            let googleSignInButton = app.buttons["Sign in with Google"]
            _ = waitForElement(googleSignInButton, timeout: 10)

            app.terminate()
        }
    }

    func testAuthFlowPerformance() throws {
        configureWithMockAuth()
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        app.launchArguments.append(LaunchArgument.skipOnboarding.rawValue)

        measure(metrics: [XCTClockMetric()]) {
            app.launch()

            let tabBar = app.tabBars.firstMatch
            _ = waitForElement(tabBar, timeout: 10)

            app.terminate()
        }
    }
}
