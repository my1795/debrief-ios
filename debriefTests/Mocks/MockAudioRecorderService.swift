//
//  MockAudioRecorderService.swift
//  debriefTests
//

import Foundation
@testable import debrief

final class MockAudioRecorderService: AudioRecorderServiceProtocol {

    // MARK: - Stubs

    var requestPermissionResult = true
    var startRecordingError: Error?
    var stopRecordingURL: URL? = URL(fileURLWithPath: "/tmp/test_audio.m4a")
    var mockCurrentTime: TimeInterval = 0

    // MARK: - Call Tracking

    var startRecordingCallCount = 0
    var stopRecordingCallCount = 0
    var cleanupCallCount = 0

    // MARK: - Protocol Conformance

    func requestPermission() async -> Bool {
        return requestPermissionResult
    }

    func startRecording() async throws {
        startRecordingCallCount += 1
        if let error = startRecordingError { throw error }
    }

    func stopRecording() -> URL? {
        stopRecordingCallCount += 1
        return stopRecordingURL
    }

    func cleanup(url: URL) {
        cleanupCallCount += 1
    }

    var currentTime: TimeInterval {
        return mockCurrentTime
    }
}
