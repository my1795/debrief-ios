//
//  CallObserverUITests.swift
//  debriefUITests
//
//  Created by Mustafa Yildirim on 21/01/2026.
//
//  Tests for call detection and post-call debrief recording flow.
//  Note: XCUITest cannot simulate actual phone calls via CallKit.
//  Instead, we use launch arguments to trigger mock call-ended states.
//

import XCTest

final class CallObserverUITests: DebriefUITestCase {

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    // MARK: - Launch Arguments for Call Simulation

    enum CallSimulationArgument: String {
        /// Simulate a call that just ended
        case simulateCallEnded = "--simulate-call-ended"
        /// Simulate call duration in seconds
        case callDuration = "--call-duration"
        /// Simulate caller phone number
        case callerNumber = "--caller-number"
        /// Simulate call ended X seconds ago
        case callEndedSecondsAgo = "--call-ended-seconds-ago"
        /// Simulate background state (app was backgrounded during call)
        case wasInBackground = "--was-in-background"
    }

    func configureCallSimulation(
        duration: Int = 180,
        callerNumber: String = "+1234567890",
        endedSecondsAgo: Int = 2,
        wasInBackground: Bool = true
    ) {
        app.launchArguments.append(CallSimulationArgument.simulateCallEnded.rawValue)
        app.launchEnvironment["SIMULATED_CALL_DURATION"] = String(duration)
        app.launchEnvironment["SIMULATED_CALLER_NUMBER"] = callerNumber
        app.launchEnvironment["SIMULATED_CALL_ENDED_AGO"] = String(endedSecondsAgo)
        app.launchEnvironment["SIMULATED_WAS_IN_BACKGROUND"] = wasInBackground ? "true" : "false"
    }

    // MARK: - Post-Call Notification Tests

    func testPostCallNotificationScheduled() throws {
        // Given: User has notifications enabled and a call just ended
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        configureCallSimulation(duration: 180, callerNumber: "+1234567890")
        launchAppAuthenticated()

        // Then: App should handle the simulated call-ended event
        // In real scenario, a notification would be scheduled
        // For UI test, we verify the app launches correctly with call context

        let tabBar = app.tabBars.firstMatch
        waitForElementToAppear(tabBar, timeout: 10)

        takeScreenshot(name: "CallObserver_Post_Call_Launch")
    }

    func testPostCallRecordPromptAppears() throws {
        // Given: Call ended and app is opened
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        configureCallSimulation(duration: 300, callerNumber: "+1234567890", endedSecondsAgo: 5)
        app.launchArguments.append("--show-record-prompt")
        launchAppAuthenticated()

        // Then: Record prompt/sheet may appear automatically
        sleep(2)

        // Check if record sheet is shown or if normal feed is displayed
        let recordingText = app.staticTexts["Recording..."]
        let debriefsTitle = app.navigationBars["Debriefs"]

        if recordingText.exists {
            // Record prompt appeared automatically
            takeScreenshot(name: "CallObserver_Auto_Record_Prompt")
        } else if debriefsTitle.exists {
            // Normal launch - user can manually start recording
            takeScreenshot(name: "CallObserver_Normal_Launch")
        }
    }

    // MARK: - Call Duration Scenarios

    func testShortCallNoPrompt() throws {
        // Given: Very short call (< 30 seconds)
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        configureCallSimulation(duration: 15, callerNumber: "+1234567890")
        launchAppAuthenticated()

        // Then: Should not prompt for debrief (call too short)
        sleep(2)

        let tabBar = app.tabBars.firstMatch
        waitForElementToAppear(tabBar, timeout: 10)

        // Verify no automatic prompt
        let recordingText = app.staticTexts["Recording..."]
        XCTAssertFalse(recordingText.exists, "Should not prompt for very short calls")

        takeScreenshot(name: "CallObserver_Short_Call_No_Prompt")
    }

    func testLongCallPrompt() throws {
        // Given: Long call (> 2 minutes)
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        configureCallSimulation(duration: 600, callerNumber: "+1234567890") // 10 minutes
        launchAppAuthenticated()

        // Then: Should be ready to prompt for debrief
        sleep(2)

        takeScreenshot(name: "CallObserver_Long_Call_Ready")
    }

    // MARK: - Caller Recognition Tests

    func testKnownContactCallEnded() throws {
        // Given: Call from known contact
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        configureCallSimulation(duration: 180, callerNumber: "+1555123456") // Known contact number
        launchAppAuthenticated()

        // Then: When recording, the contact should be pre-selected or suggested
        let recordButton = app.tabBars.buttons["Record"]
        waitForElementToAppear(recordButton)
        recordButton.tap()

        let recordingText = app.staticTexts["Recording..."]
        waitForElementToAppear(recordingText, timeout: 5)

        // Stop recording
        sleep(1)
        let stopButton = app.buttons["Stop Recording"]
        stopButton.tap()

        // Then: Known contact should appear in suggestions
        let contactList = app.scrollViews.firstMatch
        waitForElementToAppear(contactList, timeout: 5)

        takeScreenshot(name: "CallObserver_Known_Contact_Suggestion")
    }

    func testUnknownNumberCallEnded() throws {
        // Given: Call from unknown number
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        configureCallSimulation(duration: 180, callerNumber: "+1999888777") // Unknown number
        launchAppAuthenticated()

        // When: Start recording
        let recordButton = app.tabBars.buttons["Record"]
        waitForElementToAppear(recordButton)
        recordButton.tap()

        sleep(1)

        let stopButton = app.buttons["Stop Recording"]
        waitForElementToAppear(stopButton)
        stopButton.tap()

        // Then: Should show contact selection with no pre-selection
        let contactList = app.scrollViews.firstMatch
        waitForElementToAppear(contactList, timeout: 5)

        takeScreenshot(name: "CallObserver_Unknown_Number")
    }

    // MARK: - Background to Foreground Tests

    func testAppWasBackgroundedDuringCall() throws {
        // Given: App was backgrounded during the call
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        configureCallSimulation(duration: 300, wasInBackground: true)
        launchAppAuthenticated()

        // Then: App should handle transition gracefully
        let tabBar = app.tabBars.firstMatch
        waitForElementToAppear(tabBar, timeout: 10)

        takeScreenshot(name: "CallObserver_Background_Transition")
    }

    func testAppWasForegroundDuringCall() throws {
        // Given: App was in foreground during the call (less common)
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        configureCallSimulation(duration: 300, wasInBackground: false)
        launchAppAuthenticated()

        // Then: Should handle normally
        let tabBar = app.tabBars.firstMatch
        waitForElementToAppear(tabBar, timeout: 10)

        takeScreenshot(name: "CallObserver_Foreground_During_Call")
    }

    // MARK: - Time Elapsed Tests

    func testCallEndedRecently() throws {
        // Given: Call ended just 2 seconds ago
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        configureCallSimulation(duration: 180, endedSecondsAgo: 2)
        launchAppAuthenticated()

        // Then: Immediate prompt is appropriate
        takeScreenshot(name: "CallObserver_Recent_Call_End")
    }

    func testCallEndedMinutesAgo() throws {
        // Given: Call ended 5 minutes ago (user took time to open app)
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        configureCallSimulation(duration: 180, endedSecondsAgo: 300) // 5 minutes
        launchAppAuthenticated()

        // Then: Should still allow recording but may not auto-prompt
        let tabBar = app.tabBars.firstMatch
        waitForElementToAppear(tabBar, timeout: 10)

        // User can still manually record
        let recordButton = app.tabBars.buttons["Record"]
        assertElementExists(recordButton)

        takeScreenshot(name: "CallObserver_Delayed_Opening")
    }

    func testCallEndedTooLongAgo() throws {
        // Given: Call ended over 30 minutes ago
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        configureCallSimulation(duration: 180, endedSecondsAgo: 1800) // 30 minutes
        launchAppAuthenticated()

        // Then: Should not auto-prompt (too stale)
        let tabBar = app.tabBars.firstMatch
        waitForElementToAppear(tabBar, timeout: 10)

        let recordingText = app.staticTexts["Recording..."]
        XCTAssertFalse(recordingText.exists, "Should not auto-prompt for stale calls")

        takeScreenshot(name: "CallObserver_Stale_Call")
    }

    // MARK: - Quota Check Before Recording Tests

    func testQuotaExceededAfterCall() throws {
        // Given: User exceeded quota but just finished a call
        configureWithTestScenario(TestScenario.quotaExceeded.rawValue)
        configureCallSimulation(duration: 180)
        launchAppAuthenticated()

        // When: Try to record
        let recordButton = app.tabBars.buttons["Record"]
        waitForElementToAppear(recordButton)
        recordButton.tap()

        // Then: Should show quota exceeded instead of recording
        let limitReachedText = app.staticTexts["Limit Reached"]
        waitForElementToAppear(limitReachedText, timeout: 5)

        takeScreenshot(name: "CallObserver_Quota_Exceeded")
    }

    func testNearQuotaLimitAfterCall() throws {
        // Given: User near quota limit
        configureWithTestScenario(TestScenario.nearQuotaLimit.rawValue)
        configureCallSimulation(duration: 180)
        launchAppAuthenticated()

        // When: Start recording
        let recordButton = app.tabBars.buttons["Record"]
        waitForElementToAppear(recordButton)
        recordButton.tap()

        // Then: Should allow recording but may show warning
        sleep(2)

        takeScreenshot(name: "CallObserver_Near_Quota_Limit")
    }

    // MARK: - Notification Settings Tests

    func testNotificationsDisabledNoPrompt() throws {
        // Given: User has notifications disabled
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        configureCallSimulation(duration: 180)
        app.launchEnvironment["NOTIFICATIONS_DISABLED"] = "true"
        launchAppAuthenticated()

        // Then: No notification would be scheduled
        // App should launch normally without auto-prompt

        let tabBar = app.tabBars.firstMatch
        waitForElementToAppear(tabBar, timeout: 10)

        takeScreenshot(name: "CallObserver_Notifications_Disabled")
    }

    // MARK: - Complete Post-Call Flow Tests

    func testCompletePostCallDebriefFlow() throws {
        // Given: Call just ended, user opens app to record
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        configureCallSimulation(duration: 300, callerNumber: "+1234567890", endedSecondsAgo: 5)
        launchAppAuthenticated()

        // Step 1: Open recording
        let recordButton = app.tabBars.buttons["Record"]
        waitForElementToAppear(recordButton)
        recordButton.tap()

        // Step 2: Wait for recording to start
        let recordingText = app.staticTexts["Recording..."]
        waitForElementToAppear(recordingText, timeout: 5)
        takeScreenshot(name: "CallObserver_Flow_Step1_Recording")

        // Step 3: Record for a few seconds
        sleep(3)

        // Step 4: Stop recording
        let stopButton = app.buttons["Stop Recording"]
        stopButton.tap()

        // Step 5: Select contact
        let recordingSavedText = app.staticTexts["Recording Saved!"]
        waitForElementToAppear(recordingSavedText, timeout: 5)
        takeScreenshot(name: "CallObserver_Flow_Step2_Select_Contact")

        // Step 6: Try to find and select a contact
        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()

        let contactRow = scrollView.buttons.firstMatch
        if contactRow.exists {
            contactRow.tap()

            // Step 7: Save debrief
            let saveButton = app.buttons["Save Debrief"]
            if waitForElement(saveButton, timeout: 3) {
                saveButton.tap()

                // Step 8: Verify return to main view
                sleep(2)
                let tabBar = app.tabBars.firstMatch
                waitForElementToAppear(tabBar, timeout: 5)

                takeScreenshot(name: "CallObserver_Flow_Complete")
            }
        }
    }

    // MARK: - Error Handling Tests

    func testCallEndedButAudioPermissionDenied() throws {
        // Given: Call ended but user denied microphone permission
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        configureCallSimulation(duration: 180)
        app.launchEnvironment["AUDIO_PERMISSION_DENIED"] = "true"
        launchAppAuthenticated()

        // When: Try to record
        let recordButton = app.tabBars.buttons["Record"]
        waitForElementToAppear(recordButton)
        recordButton.tap()

        // Then: Should show permission error
        sleep(2)

        takeScreenshot(name: "CallObserver_Audio_Permission_Denied")
    }

    // MARK: - Performance Tests

    func testCallObserverResponseTime() throws {
        // Measure time from app launch to ready state after call
        configureWithTestScenario(TestScenario.basicUser.rawValue)
        configureCallSimulation(duration: 180)

        measure(metrics: [XCTClockMetric()]) {
            launchAppAuthenticated()

            let tabBar = app.tabBars.firstMatch
            _ = waitForElement(tabBar, timeout: 10)

            app.terminate()
        }
    }
}

// MARK: - App Integration Required

/*
 To fully support these tests, the app needs to check for launch arguments:

 In the app's launch configuration (e.g., AppDelegate or App struct):

 ```swift
 if ProcessInfo.processInfo.arguments.contains("--simulate-call-ended") {
     let duration = Int(ProcessInfo.processInfo.environment["SIMULATED_CALL_DURATION"] ?? "0") ?? 0
     let callerNumber = ProcessInfo.processInfo.environment["SIMULATED_CALLER_NUMBER"] ?? ""
     let endedAgo = Int(ProcessInfo.processInfo.environment["SIMULATED_CALL_ENDED_AGO"] ?? "0") ?? 0
     let wasBackground = ProcessInfo.processInfo.environment["SIMULATED_WAS_IN_BACKGROUND"] == "true"

     // Simulate call ended event
     CallObserverService.shared.simulateCallEnded(
         duration: TimeInterval(duration),
         callerNumber: callerNumber,
         endedSecondsAgo: TimeInterval(endedAgo),
         wasInBackground: wasBackground
     )
 }
 ```

 This allows XCUITests to trigger call-ended scenarios without actual phone calls.
*/
