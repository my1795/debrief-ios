//
//  DebriefUITestCase.swift
//  debriefUITests
//
//  Created by Mustafa Yildirim on 21/01/2026.
//

import XCTest

/// Base class for all UI tests with common setup and helpers
class DebriefUITestCase: XCTestCase {

    var app: XCUIApplication!

    // MARK: - Launch Arguments

    enum LaunchArgument: String {
        case uiTesting = "--uitesting"
        case useEmulator = "--use-firebase-emulator"
        case resetState = "--reset-state"
        case mockAuth = "--mock-auth"
        case skipOnboarding = "--skip-onboarding"
    }

    enum LaunchEnvironment: String {
        case firestoreEmulatorHost = "FIRESTORE_EMULATOR_HOST"
        case authEmulatorHost = "AUTH_EMULATOR_HOST"
        case mockUserId = "MOCK_USER_ID"
        case mockUserEmail = "MOCK_USER_EMAIL"
        case testScenario = "TEST_SCENARIO"
    }

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        configureForUITesting()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Configuration

    func configureForUITesting() {
        app.launchArguments.append(LaunchArgument.uiTesting.rawValue)
        // Note: Firebase Emulator is optional - only enable if emulator is running
        // app.launchArguments.append(LaunchArgument.useEmulator.rawValue)
    }

    /// Enable Firebase Emulator for tests (call this only if emulator is running)
    func configureWithFirebaseEmulator() {
        app.launchArguments.append(LaunchArgument.useEmulator.rawValue)
        app.launchEnvironment[LaunchEnvironment.firestoreEmulatorHost.rawValue] = "localhost:8080"
        app.launchEnvironment[LaunchEnvironment.authEmulatorHost.rawValue] = "localhost:9099"
    }

    func configureWithMockAuth(userId: String = "test-user-123", email: String = "test@example.com") {
        app.launchArguments.append(LaunchArgument.mockAuth.rawValue)
        app.launchEnvironment[LaunchEnvironment.mockUserId.rawValue] = userId
        app.launchEnvironment[LaunchEnvironment.mockUserEmail.rawValue] = email
    }

    func configureWithTestScenario(_ scenario: String) {
        app.launchEnvironment[LaunchEnvironment.testScenario.rawValue] = scenario
    }

    func launchAppAuthenticated() {
        configureWithMockAuth()
        app.launchArguments.append(LaunchArgument.skipOnboarding.rawValue)
        app.launch()
    }

    func launchAppUnauthenticated() {
        app.launch()
    }

    // MARK: - Wait Helpers

    /// Default timeout for UI tests (reduced from 10s for faster feedback)
    static let defaultTimeout: TimeInterval = 5

    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = defaultTimeout) -> Bool {
        element.waitForExistence(timeout: timeout)
    }

    @discardableResult
    func waitForElementToAppear(_ element: XCUIElement, timeout: TimeInterval = defaultTimeout, file: StaticString = #file, line: UInt = #line) -> XCUIElement {
        let exists = element.waitForExistence(timeout: timeout)
        XCTAssertTrue(exists, "Element \(element) did not appear within \(timeout) seconds", file: file, line: line)
        return element
    }

    func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = defaultTimeout, file: StaticString = #file, line: UInt = #line) {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, "Element \(element) did not disappear within \(timeout) seconds", file: file, line: line)
    }

    func waitForElementToBeHittable(_ element: XCUIElement, timeout: TimeInterval = defaultTimeout) -> Bool {
        let predicate = NSPredicate(format: "isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }

    // MARK: - Tab Navigation

    /// Navigate to a tab using the custom tab bar
    /// Note: The app uses a custom tab bar (not native UITabBar), so we find buttons by label
    func navigateToTab(_ tab: TabIdentifier) {
        // First, try the standard tab bar (fallback)
        let standardTabButton = app.tabBars.buttons[tab.rawValue]
        if standardTabButton.waitForExistence(timeout: 2) {
            standardTabButton.tap()
            return
        }

        // For custom tab bar, find button by its label text
        // The custom TabBarButton has a Text with the label
        let customTabButton = app.buttons[tab.rawValue]
        if customTabButton.waitForExistence(timeout: 5) {
            customTabButton.tap()
            return
        }

        // Alternative: Find by accessibility identifier or static text
        let tabText = app.staticTexts[tab.rawValue]
        if tabText.waitForExistence(timeout: 3) {
            tabText.tap()
            return
        }

        // Last resort: fail with helpful message
        XCTFail("Could not find tab button for '\(tab.rawValue)'")
    }

    enum TabIdentifier: String {
        case debriefs = "Debriefs"
        case stats = "Stats"
        case record = "Record"
        case contacts = "Contacts"
        case settings = "Settings"
    }

    // MARK: - Common Actions

    func tapBackButton() {
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        if backButton.exists && backButton.isHittable {
            backButton.tap()
        }
    }

    func pullToRefresh(on element: XCUIElement) {
        let start = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let end = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        start.press(forDuration: 0.1, thenDragTo: end)
    }

    func scrollToElement(_ element: XCUIElement, in scrollView: XCUIElement, maxSwipes: Int = 10) {
        var swipeCount = 0
        while !element.isHittable && swipeCount < maxSwipes {
            scrollView.swipeUp()
            swipeCount += 1
        }
    }

    func dismissKeyboard() {
        if app.keyboards.count > 0 {
            app.keyboards.buttons["Return"].tap()
        }
    }

    func clearAndType(in textField: XCUIElement, text: String) {
        textField.tap()
        if let currentValue = textField.value as? String, !currentValue.isEmpty {
            textField.tap(withNumberOfTaps: 3, numberOfTouches: 1) // Select all
            textField.typeText(XCUIKeyboardKey.delete.rawValue)
        }
        textField.typeText(text)
    }

    // MARK: - Assertion Helpers

    func assertElementExists(_ element: XCUIElement, message: String = "", file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(element.exists, message.isEmpty ? "Element \(element) does not exist" : message, file: file, line: line)
    }

    func assertElementNotExists(_ element: XCUIElement, message: String = "", file: StaticString = #file, line: UInt = #line) {
        XCTAssertFalse(element.exists, message.isEmpty ? "Element \(element) should not exist" : message, file: file, line: line)
    }

    func assertElementEnabled(_ element: XCUIElement, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(element.isEnabled, "Element \(element) is not enabled", file: file, line: line)
    }

    func assertElementDisabled(_ element: XCUIElement, file: StaticString = #file, line: UInt = #line) {
        XCTAssertFalse(element.isEnabled, "Element \(element) should be disabled", file: file, line: line)
    }

    func assertTextExists(_ text: String, file: StaticString = #file, line: UInt = #line) {
        let element = app.staticTexts[text]
        XCTAssertTrue(element.exists, "Text '\(text)' not found", file: file, line: line)
    }

    func assertTextNotExists(_ text: String, file: StaticString = #file, line: UInt = #line) {
        let element = app.staticTexts[text]
        XCTAssertFalse(element.exists, "Text '\(text)' should not exist", file: file, line: line)
    }

    // MARK: - Async Helpers

    /// Wait for a condition to become true (use instead of sleep())
    /// - Parameters:
    ///   - timeout: Maximum time to wait
    ///   - interval: How often to check the condition
    ///   - condition: The condition to wait for
    /// - Returns: Whether the condition became true
    @discardableResult
    func waitForCondition(timeout: TimeInterval = defaultTimeout, interval: TimeInterval = 0.1, condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(interval))
        }
        return condition()
    }

    /// Brief pause for UI to settle (use sparingly, prefer waitForElement)
    func briefPause(_ seconds: TimeInterval = 0.5) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    // MARK: - Screenshot Helpers

    func takeScreenshot(name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
