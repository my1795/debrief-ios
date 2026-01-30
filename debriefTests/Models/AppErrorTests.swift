//
//  AppErrorTests.swift
//  debriefTests
//

import XCTest
@testable import debrief

final class AppErrorTests: XCTestCase {

    // MARK: - Factory Method from NSError

    func test_from_nsURLErrorDomain_returnsNetwork() {
        let nsError = NSError(domain: NSURLErrorDomain, code: -1009, userInfo: nil)
        let appError = AppError.from(nsError)

        if case .network = appError {
            // pass
        } else {
            XCTFail("Expected .network, got \(appError)")
        }
    }

    func test_from_firebaseCode7_returnsUnauthorized() {
        let nsError = NSError(domain: "com.firebase.Firestore", code: 7, userInfo: nil)
        let appError = AppError.from(nsError)

        XCTAssertEqual(appError, .unauthorized)
    }

    func test_from_firebaseCode5_returnsNotFound() {
        let nsError = NSError(domain: "FIRFirestoreErrorDomain", code: 5, userInfo: nil)
        let appError = AppError.from(nsError)

        XCTAssertEqual(appError, .notFound)
    }

    func test_from_firebaseOtherCode_returnsServerError() {
        let nsError = NSError(domain: "Firebase.Auth", code: 17020, userInfo: nil)
        let appError = AppError.from(nsError)

        if case .serverError(let code) = appError {
            XCTAssertEqual(code, 17020)
        } else {
            XCTFail("Expected .serverError, got \(appError)")
        }
    }

    func test_from_unknownError_returnsUnknown() {
        let nsError = NSError(domain: "SomeOtherDomain", code: 42, userInfo: [NSLocalizedDescriptionKey: "Something broke"])
        let appError = AppError.from(nsError)

        if case .unknown(let message) = appError {
            XCTAssertFalse(message.isEmpty)
        } else {
            XCTFail("Expected .unknown, got \(appError)")
        }
    }

    func test_from_alreadyAppError_returnsSelf() {
        let original = AppError.unauthorized
        let result = AppError.from(original)
        XCTAssertEqual(result, .unauthorized)
    }

    // MARK: - User Messages

    func test_userMessage_network() {
        let error = AppError.network(message: "timeout")
        XCTAssertEqual(error.userMessage, "Unable to connect. Please check your internet connection.")
    }

    func test_userMessage_unauthorized() {
        XCTAssertEqual(AppError.unauthorized.userMessage, "Your session has expired. Please sign in again.")
    }

    func test_userMessage_notFound() {
        XCTAssertEqual(AppError.notFound.userMessage, "The requested content was not found.")
    }

    func test_userMessage_serverError_includesCode() {
        let error = AppError.serverError(statusCode: 503)
        XCTAssertTrue(error.userMessage.contains("503"))
    }

    func test_userMessage_unknownEmpty_fallback() {
        let error = AppError.unknown(message: "")
        XCTAssertEqual(error.userMessage, "An unexpected error occurred.")
    }

    func test_userMessage_unknownWithMessage() {
        let error = AppError.unknown(message: "Custom message")
        XCTAssertEqual(error.userMessage, "Custom message")
    }

    // MARK: - isRetryable

    func test_isRetryable_network() {
        XCTAssertTrue(AppError.network(message: "").isRetryable)
    }

    func test_isRetryable_serverError() {
        XCTAssertTrue(AppError.serverError(statusCode: 500).isRetryable)
    }

    func test_isRetryable_unauthorized_false() {
        XCTAssertFalse(AppError.unauthorized.isRetryable)
    }

    func test_isRetryable_notFound_false() {
        XCTAssertFalse(AppError.notFound.isRetryable)
    }

    func test_isRetryable_unknown_false() {
        XCTAssertFalse(AppError.unknown(message: "").isRetryable)
    }

    // MARK: - Equatable

    func test_equatable_sameCases() {
        XCTAssertEqual(AppError.unauthorized, AppError.unauthorized)
        XCTAssertEqual(AppError.notFound, AppError.notFound)
        XCTAssertEqual(AppError.serverError(statusCode: 500), AppError.serverError(statusCode: 500))
        XCTAssertEqual(AppError.unknown(message: "a"), AppError.unknown(message: "a"))
    }

    func test_equatable_networkIgnoresMessage() {
        // Network cases are equal regardless of message
        XCTAssertEqual(AppError.network(message: "a"), AppError.network(message: "b"))
    }

    func test_equatable_differentCases() {
        XCTAssertNotEqual(AppError.unauthorized, AppError.notFound)
        XCTAssertNotEqual(AppError.serverError(statusCode: 500), AppError.serverError(statusCode: 404))
    }

    // MARK: - Icon

    func test_icon_allCases() {
        XCTAssertEqual(AppError.network(message: "").icon, "wifi.slash")
        XCTAssertEqual(AppError.unauthorized.icon, "lock.fill")
        XCTAssertEqual(AppError.notFound.icon, "magnifyingglass")
        XCTAssertEqual(AppError.serverError(statusCode: 500).icon, "exclamationmark.triangle")
        XCTAssertEqual(AppError.unknown(message: "").icon, "questionmark.circle")
    }
}
