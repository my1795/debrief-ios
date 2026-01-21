//
//  TestModeConfiguration.swift
//  debriefUITests
//
//  Created by Mustafa Yildirim on 21/01/2026.
//
//  This file should be included in the MAIN APP target (not UI test target)
//  to enable test mode support via launch arguments.
//

import Foundation

/// Configuration helper for UI testing mode
/// Add this to the app's launch sequence to enable test scenarios
public struct TestModeConfiguration {

    // MARK: - Singleton

    public static let shared = TestModeConfiguration()
    private init() {}

    // MARK: - Detection

    /// Check if running in UI test mode
    public var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("--uitesting")
    }

    /// Check if Firebase Emulator should be used
    public var useFirebaseEmulator: Bool {
        ProcessInfo.processInfo.arguments.contains("--use-firebase-emulator")
    }

    /// Check if state should be reset
    public var shouldResetState: Bool {
        ProcessInfo.processInfo.arguments.contains("--reset-state")
    }

    /// Check if mock auth should be used
    public var useMockAuth: Bool {
        ProcessInfo.processInfo.arguments.contains("--mock-auth")
    }

    /// Check if onboarding should be skipped
    public var skipOnboarding: Bool {
        ProcessInfo.processInfo.arguments.contains("--skip-onboarding")
    }

    // MARK: - Environment Variables

    public var firestoreEmulatorHost: String? {
        ProcessInfo.processInfo.environment["FIRESTORE_EMULATOR_HOST"]
    }

    public var authEmulatorHost: String? {
        ProcessInfo.processInfo.environment["AUTH_EMULATOR_HOST"]
    }

    public var mockUserId: String? {
        ProcessInfo.processInfo.environment["MOCK_USER_ID"]
    }

    public var mockUserEmail: String? {
        ProcessInfo.processInfo.environment["MOCK_USER_EMAIL"]
    }

    public var testScenario: String? {
        ProcessInfo.processInfo.environment["TEST_SCENARIO"]
    }

    // MARK: - Call Simulation

    public var simulateCallEnded: Bool {
        ProcessInfo.processInfo.arguments.contains("--simulate-call-ended")
    }

    public var simulatedCallDuration: Int {
        Int(ProcessInfo.processInfo.environment["SIMULATED_CALL_DURATION"] ?? "0") ?? 0
    }

    public var simulatedCallerNumber: String? {
        ProcessInfo.processInfo.environment["SIMULATED_CALLER_NUMBER"]
    }

    public var simulatedCallEndedSecondsAgo: Int {
        Int(ProcessInfo.processInfo.environment["SIMULATED_CALL_ENDED_AGO"] ?? "0") ?? 0
    }

    public var wasInBackground: Bool {
        ProcessInfo.processInfo.environment["SIMULATED_WAS_IN_BACKGROUND"] == "true"
    }

    // MARK: - Permission Simulation

    public var audioPermissionDenied: Bool {
        ProcessInfo.processInfo.environment["AUDIO_PERMISSION_DENIED"] == "true"
    }

    public var notificationsDisabled: Bool {
        ProcessInfo.processInfo.environment["NOTIFICATIONS_DISABLED"] == "true"
    }

    // MARK: - Configuration

    /// Configure Firebase to use emulator if in test mode
    public func configureFirebaseIfNeeded() {
        guard isUITesting && useFirebaseEmulator else { return }

        // Firebase Emulator configuration
        // This should be called before Firebase.configure()

        #if DEBUG
        if let firestoreHost = firestoreEmulatorHost {
            print("🧪 [TestMode] Using Firestore Emulator: \(firestoreHost)")
            // FirebaseFirestore settings would be configured here
            // Settings.defaultSettings().host = firestoreHost
            // Settings.defaultSettings().isSSLEnabled = false
        }

        if let authHost = authEmulatorHost {
            print("🧪 [TestMode] Using Auth Emulator: \(authHost)")
            // Auth.auth().useEmulator(withHost: "localhost", port: 9099)
        }
        #endif
    }

    /// Configure mock authentication if in test mode
    public func configureMockAuthIfNeeded() -> (userId: String, email: String)? {
        guard isUITesting && useMockAuth else { return nil }

        let userId = mockUserId ?? "test-user-\(UUID().uuidString.prefix(8))"
        let email = mockUserEmail ?? "test@example.com"

        print("🧪 [TestMode] Using Mock Auth: \(userId) / \(email)")

        return (userId, email)
    }

    /// Load test scenario data
    public func loadTestScenario() -> TestScenarioData? {
        guard isUITesting, let scenario = testScenario else { return nil }

        print("🧪 [TestMode] Loading scenario: \(scenario)")

        return TestScenarioData(rawValue: scenario)
    }

    /// Simulate call ended event if configured
    public func handleCallSimulationIfNeeded(callObserver: AnyObject?) {
        guard isUITesting && simulateCallEnded else { return }

        let duration = simulatedCallDuration
        let callerNumber = simulatedCallerNumber ?? ""
        let endedAgo = simulatedCallEndedSecondsAgo

        print("🧪 [TestMode] Simulating call ended:")
        print("   Duration: \(duration)s")
        print("   Caller: \(callerNumber)")
        print("   Ended ago: \(endedAgo)s")
        print("   Was in background: \(wasInBackground)")

        // Trigger simulated call ended event
        // This would call into CallObserverService with mock data
    }
}

// MARK: - Test Scenario Data

public enum TestScenarioData: String {
    case emptyUser = "EMPTY_USER"
    case basicUser = "BASIC_USER"
    case powerUser = "POWER_USER"
    case nearQuotaLimit = "NEAR_QUOTA_LIMIT"
    case quotaExceeded = "QUOTA_EXCEEDED"
    case proUser = "PRO_USER"
    case personalUser = "PERSONAL_USER"
    case mixedDebriefStates = "MIXED_DEBRIEF_STATES"
    case processingDebrief = "PROCESSING_DEBRIEF"
    case failedDebrief = "FAILED_DEBRIEF"
    case manyContacts = "MANY_CONTACTS"
    case noContacts = "NO_CONTACTS"
    case contactPermissionDenied = "CONTACT_PERMISSION_DENIED"
    case offlineMode = "OFFLINE_MODE"
    case slowNetwork = "SLOW_NETWORK"
    case networkError = "NETWORK_ERROR"
    case withCalculatedStats = "WITH_CALCULATED_STATS"
    case withTopContacts = "WITH_TOP_CONTACTS"
    case streakScenario = "STREAK_SCENARIO"

    // MARK: - Mock Data Properties

    public var debriefCount: Int {
        switch self {
        case .emptyUser: return 0
        case .basicUser: return 8
        case .powerUser: return 75
        case .nearQuotaLimit: return 45
        case .quotaExceeded: return 51
        default: return 10
        }
    }

    public var usedMinutes: Int {
        switch self {
        case .emptyUser: return 0
        case .basicUser: return 15
        case .powerUser: return 120
        case .nearQuotaLimit: return 27
        case .quotaExceeded: return 35
        default: return 20
        }
    }

    public var tier: String {
        switch self {
        case .proUser: return "PRO"
        case .personalUser: return "PERSONAL"
        default: return "FREE"
        }
    }

    public var storageUsedMB: Int {
        switch self {
        case .nearQuotaLimit: return 450
        case .quotaExceeded: return 510
        default: return 125
        }
    }

    public var contactCount: Int {
        switch self {
        case .noContacts: return 0
        case .manyContacts: return 150
        default: return 25
        }
    }

    public var shouldSimulateNetworkDelay: Bool {
        return self == .slowNetwork
    }

    public var shouldSimulateNetworkError: Bool {
        return self == .networkError
    }

    public var shouldSimulateOffline: Bool {
        return self == .offlineMode
    }
}
