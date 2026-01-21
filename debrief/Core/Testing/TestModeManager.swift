//
//  TestModeManager.swift
//  debrief
//
//  Manages test mode configuration for UI testing.
//  This file handles launch arguments and environment variables
//  passed by XCUITest to configure the app for testing.
//

import Foundation

#if DEBUG
/// Manages test mode configuration during UI testing
final class TestModeManager {
    static let shared = TestModeManager()

    // MARK: - Launch Arguments

    enum LaunchArgument: String {
        case uiTesting = "--uitesting"
        case useEmulator = "--use-firebase-emulator"
        case mockAuth = "--mock-auth"
        case skipOnboarding = "--skip-onboarding"
        case simulateCallEnded = "--simulate-call-ended"
        case resetOnLaunch = "--reset-on-launch"
    }

    // MARK: - Environment Variables

    enum EnvironmentKey: String {
        case testScenario = "TEST_SCENARIO"
        case mockUserId = "MOCK_USER_ID"
        case mockUserEmail = "MOCK_USER_EMAIL"
        case mockUserDisplayName = "MOCK_USER_DISPLAY_NAME"
        case simulatedCallDuration = "SIMULATED_CALL_DURATION"
        case simulatedCallerName = "SIMULATED_CALLER_NAME"
        case simulatedCallerNumber = "SIMULATED_CALLER_NUMBER"
    }

    // MARK: - Properties

    /// Whether the app is running in UI test mode
    var isUITestMode: Bool {
        hasLaunchArgument(.uiTesting)
    }

    /// Whether to use Firebase Emulator
    var shouldUseEmulator: Bool {
        hasLaunchArgument(.useEmulator)
    }

    /// Whether to use mock authentication
    var shouldUseMockAuth: Bool {
        hasLaunchArgument(.mockAuth)
    }

    /// Whether to skip onboarding
    var shouldSkipOnboarding: Bool {
        hasLaunchArgument(.skipOnboarding)
    }

    /// Whether to simulate a call ended event
    var shouldSimulateCallEnded: Bool {
        hasLaunchArgument(.simulateCallEnded)
    }

    /// Whether to reset app state on launch
    var shouldResetOnLaunch: Bool {
        hasLaunchArgument(.resetOnLaunch)
    }

    // MARK: - Mock User Properties

    /// Mock user ID for testing
    var mockUserId: String {
        environmentValue(.mockUserId) ?? "test-user-id"
    }

    /// Mock user email for testing
    var mockUserEmail: String {
        environmentValue(.mockUserEmail) ?? "test@example.com"
    }

    /// Mock user display name for testing
    var mockUserDisplayName: String {
        environmentValue(.mockUserDisplayName) ?? "Test User"
    }

    // MARK: - Test Scenario

    /// Current test scenario
    var testScenario: String? {
        environmentValue(.testScenario)
    }

    // MARK: - Simulated Call Properties

    /// Simulated call duration in seconds
    var simulatedCallDuration: Int {
        if let value = environmentValue(.simulatedCallDuration) {
            return Int(value) ?? 0
        }
        return 0
    }

    /// Simulated caller name
    var simulatedCallerName: String? {
        environmentValue(.simulatedCallerName)
    }

    /// Simulated caller number
    var simulatedCallerNumber: String? {
        environmentValue(.simulatedCallerNumber)
    }

    // MARK: - Private

    private init() {
        if isUITestMode {
            print("[TestMode] UI Test Mode Enabled")
            print("[TestMode] Mock Auth: \(shouldUseMockAuth)")
            print("[TestMode] Use Emulator: \(shouldUseEmulator)")
            if let scenario = testScenario {
                print("[TestMode] Test Scenario: \(scenario)")
            }
        }
    }

    private func hasLaunchArgument(_ argument: LaunchArgument) -> Bool {
        ProcessInfo.processInfo.arguments.contains(argument.rawValue)
    }

    private func environmentValue(_ key: EnvironmentKey) -> String? {
        ProcessInfo.processInfo.environment[key.rawValue]
    }

    // MARK: - Firebase Emulator Configuration

    /// Firestore emulator host
    var firestoreEmulatorHost: String {
        "localhost"
    }

    /// Firestore emulator port
    var firestoreEmulatorPort: Int {
        8080
    }

    /// Auth emulator host
    var authEmulatorHost: String {
        "localhost"
    }

    /// Auth emulator port
    var authEmulatorPort: Int {
        9099
    }
}

#else
// MARK: - Production Stub (all features disabled)

/// Production stub - all test features disabled
final class TestModeManager {
    static let shared = TestModeManager()

    var isUITestMode: Bool { false }
    var shouldUseEmulator: Bool { false }
    var shouldUseMockAuth: Bool { false }
    var shouldSkipOnboarding: Bool { false }
    var shouldSimulateCallEnded: Bool { false }
    var shouldResetOnLaunch: Bool { false }

    var mockUserId: String { "" }
    var mockUserEmail: String { "" }
    var mockUserDisplayName: String { "" }
    var testScenario: String? { nil }
    var simulatedCallDuration: Int { 0 }
    var simulatedCallerName: String? { nil }
    var simulatedCallerNumber: String? { nil }

    var firestoreEmulatorHost: String { "" }
    var firestoreEmulatorPort: Int { 0 }
    var authEmulatorHost: String { "" }
    var authEmulatorPort: Int { 0 }

    private init() {}
}
#endif
