//
//  TestFixtures.swift
//  debriefTests
//
//  Test data factory for unit tests
//

import Foundation
@testable import debrief

enum TestFixtures {

    // MARK: - Debrief

    static func makeDebrief(
        id: String = "debrief-001",
        userId: String = "user-123",
        contactId: String = "contact-456",
        contactName: String = "John Doe",
        occurredAt: Date = Date(),
        duration: TimeInterval = 120,
        status: DebriefStatus = .ready,
        summary: String? = "Test summary",
        transcript: String? = "Test transcript",
        actionItems: [String]? = ["Item 1", "Item 2"],
        actionItemsCount: Int? = nil,
        audioUrl: String? = "https://example.com/audio.m4a",
        audioStoragePath: String? = nil,
        encrypted: Bool = false,
        encryptionVersion: String? = nil,
        phoneNumber: String? = nil,
        email: String? = nil,
        retryCount: Int = 0,
        nextRetryAt: Date? = nil,
        errorMessage: String? = nil
    ) -> Debrief {
        Debrief(
            id: id,
            userId: userId,
            contactId: contactId,
            contactName: contactName,
            occurredAt: occurredAt,
            duration: duration,
            status: status,
            summary: summary,
            transcript: transcript,
            actionItems: actionItems,
            actionItemsCount: actionItemsCount,
            audioUrl: audioUrl,
            audioStoragePath: audioStoragePath,
            encrypted: encrypted,
            encryptionVersion: encryptionVersion,
            phoneNumber: phoneNumber,
            email: email,
            retryCount: retryCount,
            nextRetryAt: nextRetryAt,
            errorMessage: errorMessage
        )
    }

    // MARK: - Contact

    static func makeContact(
        id: String = "contact-456",
        name: String = "John Doe",
        handle: String? = "Acme Corp",
        totalDebriefs: Int = 5,
        phoneNumbers: [String] = ["+1234567890"],
        emailAddresses: [String] = ["john@example.com"]
    ) -> Contact {
        Contact(
            id: id,
            name: name,
            handle: handle,
            totalDebriefs: totalDebriefs,
            phoneNumbers: phoneNumbers,
            emailAddresses: emailAddresses
        )
    }

    // MARK: - UserPlan

    static func makeUserPlan(
        userId: String = "user-123",
        tier: String = "FREE",
        billingWeekStart: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        billingWeekEnd: Int64 = Int64(Date().addingTimeInterval(7 * 24 * 3600).timeIntervalSince1970 * 1000),
        debriefCount: Int = 5,
        totalSeconds: Int = 300,
        actionItemsCount: Int? = 10,
        uniqueContactIds: [String]? = ["c1", "c2"],
        usedStorageMB: Int = 100,
        subscriptionEnd: Int64? = nil,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        updatedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) -> UserPlan {
        UserPlan(
            userId: userId,
            tier: tier,
            billingWeekStart: billingWeekStart,
            billingWeekEnd: billingWeekEnd,
            weeklyUsage: UserPlanWeeklyUsage(
                debriefCount: debriefCount,
                totalSeconds: totalSeconds,
                actionItemsCount: actionItemsCount,
                uniqueContactIds: uniqueContactIds
            ),
            usedStorageMB: usedStorageMB,
            subscriptionEnd: subscriptionEnd,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    // MARK: - JSON Payloads

    static let debriefFullJSON: String = """
    {
        "debriefId": "d-001",
        "userId": "u-123",
        "contactId": "c-456",
        "contactName": "Jane Smith",
        "occurredAt": 1706000000,
        "audioDurationSec": 180,
        "status": "READY",
        "summary": "Meeting went well",
        "transcript": "Full transcript here",
        "actionItems": ["Follow up", "Send email"],
        "actionItemsCount": 2,
        "audioUrl": "https://example.com/audio.m4a",
        "audioStoragePath": "debriefs/u-123/d-001/audio.m4a",
        "encrypted": false,
        "encryptionVersion": null,
        "phoneNumber": "+1234567890",
        "email": "jane@example.com",
        "retryCount": 0,
        "nextRetryAt": null,
        "errorMessage": null
    }
    """

    static let debriefMinimalJSON: String = """
    {
        "debriefId": "d-002",
        "status": "CREATED",
        "occurredAt": 1706000000
    }
    """

    static let debriefMillisTimestampJSON: String = """
    {
        "debriefId": "d-003",
        "userId": "u-123",
        "contactId": "c-789",
        "contactName": "Bob",
        "occurredAt": 1706000000000,
        "audioDurationSec": 60,
        "status": "PROCESSING",
        "encrypted": false,
        "retryCount": 0
    }
    """

    static let debriefRetryingJSON: String = """
    {
        "debriefId": "d-004",
        "status": "FAILED",
        "occurredAt": 1706000000,
        "retryCount": 1,
        "nextRetryAt": 1706100000000,
        "errorMessage": "Temporary failure"
    }
    """

    static let debriefPermanentlyFailedJSON: String = """
    {
        "debriefId": "d-005",
        "status": "FAILED",
        "occurredAt": 1706000000,
        "retryCount": 3,
        "errorMessage": "Permanent failure"
    }
    """

    static let debriefEncryptedJSON: String = """
    {
        "debriefId": "d-006",
        "status": "READY",
        "occurredAt": 1706000000,
        "encrypted": false,
        "encryptionVersion": "v1",
        "summary": "encrypted_summary",
        "retryCount": 0
    }
    """

    static let debriefNegativeDurationJSON: String = """
    {
        "debriefId": "d-007",
        "status": "READY",
        "audioDurationSec": -5,
        "occurredAt": 1706000000,
        "retryCount": 0
    }
    """

    // MARK: - CallStat

    static func makeCallStat(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        duration: TimeInterval = 60
    ) -> CallStat {
        CallStat(id: id, timestamp: timestamp, duration: duration)
    }
}
