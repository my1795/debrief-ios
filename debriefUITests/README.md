# Debrief UI Tests

Comprehensive XCUITest suite for the Debrief iOS app with Firebase Emulator integration.

## Overview

This test suite provides:
- **150+ test scenarios** covering all major features
- **Firebase Emulator integration** for isolated testing
- **CallObserver simulation** via launch arguments
- **Performance benchmarks** for critical flows
- **Screenshot capture** at key steps

## Test Files

| File | Description | Test Count |
|------|-------------|------------|
| `AuthUITests.swift` | Login, logout, session persistence | ~20 |
| `RecordUITests.swift` | Recording flow, quota limits, contact selection | ~25 |
| `DebriefsFeedUITests.swift` | Feed display, search, filters, detail view | ~40 |
| `ContactsUITests.swift` | Contact list, search, detail, history | ~25 |
| `StatsUITests.swift` | Stats display, quota, top contacts, billing week | ~25 |
| `SettingsUITests.swift` | Settings, notifications, free space, delete account | ~25 |
| `CallObserverUITests.swift` | Post-call flows, notification triggers | ~20 |
| `IntegrationUITests.swift` | End-to-end user journeys | ~15 |

## Prerequisites

### 1. Firebase Emulator Suite

Install Firebase CLI and run emulators:

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Start emulators
firebase emulators:start --only firestore,auth
```

Default ports:
- Firestore: `localhost:8080`
- Auth: `localhost:9099`

### 2. Add UI Test Target

In Xcode:
1. File → New → Target → UI Testing Bundle
2. Name: `debriefUITests`
3. Add all `.swift` files from this directory

### 3. Seed Test Data

```bash
# Basic user scenario
./Scripts/seed_emulator.sh BASIC_USER

# Power user scenario
./Scripts/seed_emulator.sh POWER_USER

# Quota exceeded scenario
./Scripts/seed_emulator.sh QUOTA_EXCEEDED
```

## Running Tests

### From Xcode

1. Select `debriefUITests` scheme
2. Product → Test (⌘U)

### From Command Line

```bash
# Run all UI tests
xcodebuild test \
  -scheme debriefUITests \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -resultBundlePath ./TestResults

# Run specific test class
xcodebuild test \
  -scheme debriefUITests \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:debriefUITests/StatsUITests

# Run specific test
xcodebuild test \
  -scheme debriefUITests \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:debriefUITests/RecordUITests/testCompleteRecordingFlow
```

## Test Scenarios

Available scenarios via `TEST_SCENARIO` environment variable:

| Scenario | Description |
|----------|-------------|
| `EMPTY_USER` | New user, no data |
| `BASIC_USER` | Normal user, some activity |
| `POWER_USER` | Heavy user, lots of data |
| `NEAR_QUOTA_LIMIT` | User at 80%+ quota |
| `QUOTA_EXCEEDED` | User over quota limits |
| `PRO_USER` | Pro tier, unlimited quotas |
| `PERSONAL_USER` | Personal tier |
| `PROCESSING_DEBRIEF` | Debrief in processing state |
| `FAILED_DEBRIEF` | Debrief in failed state |
| `MANY_CONTACTS` | 100+ contacts for scroll tests |
| `NO_CONTACTS` | Zero contacts |
| `OFFLINE_MODE` | Simulated offline |
| `SLOW_NETWORK` | Simulated slow network |

## App Integration

Add to your app's launch configuration to support test modes:

```swift
// In App.swift or AppDelegate
import Foundation

func application(_ application: UIApplication, didFinishLaunchingWithOptions...) {
    #if DEBUG
    if ProcessInfo.processInfo.arguments.contains("--uitesting") {
        configureForUITesting()
    }
    #endif
}

func configureForUITesting() {
    // Use Firebase Emulator
    if ProcessInfo.processInfo.arguments.contains("--use-firebase-emulator") {
        let settings = Firestore.firestore().settings
        settings.host = "localhost:8080"
        settings.isSSLEnabled = false
        Firestore.firestore().settings = settings

        Auth.auth().useEmulator(withHost: "localhost", port: 9099)
    }

    // Mock authentication
    if ProcessInfo.processInfo.arguments.contains("--mock-auth") {
        let userId = ProcessInfo.processInfo.environment["MOCK_USER_ID"] ?? "test-user"
        let email = ProcessInfo.processInfo.environment["MOCK_USER_EMAIL"] ?? "test@example.com"
        // Set up mock auth session
    }

    // Handle call simulation
    if ProcessInfo.processInfo.arguments.contains("--simulate-call-ended") {
        let duration = Int(ProcessInfo.processInfo.environment["SIMULATED_CALL_DURATION"] ?? "0") ?? 0
        // Trigger simulated call ended
    }
}
```

## Accessibility Identifiers

For reliable UI testing, add accessibility identifiers to your views:

```swift
Button("Sign in with Google") {
    // action
}
.accessibilityIdentifier(AccessibilityIdentifiers.Login.googleSignInButton)
```

See `AccessibilityIdentifiers.swift` for the complete list.

## Screenshots

Tests automatically capture screenshots at key steps. Screenshots are stored in the test results bundle:

```bash
# View test results
open TestResults.xcresult
```

## Continuous Integration

### GitHub Actions

```yaml
name: UI Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      - name: Start Firebase Emulator
        run: |
          npm install -g firebase-tools
          firebase emulators:start --only firestore,auth &
          sleep 10

      - name: Seed Test Data
        run: ./debriefUITests/Scripts/seed_emulator.sh BASIC_USER

      - name: Run UI Tests
        run: |
          xcodebuild test \
            -scheme debriefUITests \
            -destination 'platform=iOS Simulator,name=iPhone 15' \
            -resultBundlePath ./TestResults
```

## Best Practices

1. **Use waitForElement** instead of sleep() where possible
2. **Take screenshots** at failure points for debugging
3. **Keep tests independent** - don't rely on test execution order
4. **Use test scenarios** to set up specific conditions
5. **Clean up after tests** using tearDown methods

## Troubleshooting

### XCTest module not found

The UI test files need to be in a UI Testing Bundle target, not the main app target.

### Firebase Emulator connection refused

Ensure emulators are running before tests:
```bash
firebase emulators:start --only firestore,auth
```

### Tests timing out

Increase timeout values in `DebriefUITestCase.swift` or use `waitForElementToAppear` with longer timeouts.

### Screenshots not capturing

Ensure the test is calling `takeScreenshot(name:)` and check the test results bundle.
