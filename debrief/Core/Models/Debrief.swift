//
//  Debrief.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 13/01/2026.
//

import Foundation

enum DebriefStatus: String, Codable {
    case draft = "DRAFT"
    case uploaded = "UPLOADED"
    case processing = "PROCESSING"
    case ready = "READY"
    case failed = "FAILED"
}

struct Debrief: Identifiable, Codable {
    let id: String
    let userId: String
    let contactId: String
    let contactName: String
    let occurredAt: Date
    let duration: TimeInterval
    let status: DebriefStatus
    let summary: String?
    let transcript: String?
    let actionItems: [String]?
    let audioUrl: String?
    let audioStoragePath: String?
    
    // Alias `id` to `debriefId` for easier access when checking raw data consistency
    var debriefId: String { id }
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id = "debriefId"
        case userId, contactId, contactName, occurredAt, duration, status, summary, transcript, actionItems, audioUrl, audioStoragePath
        case audioDurationSec // Legacy/Alternate key from backend
    }
    
    // MARK: - Decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required Fields
        id = try container.decode(String.self, forKey: .id)
        status = try container.decode(DebriefStatus.self, forKey: .status)
        
        // Optional Fields (with Robust Defaults)
        userId = try container.decodeIfPresent(String.self, forKey: .userId) ?? ""
        contactId = try container.decodeIfPresent(String.self, forKey: .contactId) ?? ""
        contactName = try container.decodeIfPresent(String.self, forKey: .contactName) ?? "Unknown"
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        transcript = try container.decodeIfPresent(String.self, forKey: .transcript)
        actionItems = try container.decodeIfPresent([String].self, forKey: .actionItems)
        audioUrl = try container.decodeIfPresent(String.self, forKey: .audioUrl)
        audioStoragePath = try container.decodeIfPresent(String.self, forKey: .audioStoragePath)
        
        // Complex Decoding Helpers
        occurredAt = try Debrief.decodeDate(from: container)
        duration = Debrief.decodeDuration(from: container)
    }
    
    // MARK: - Encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(contactId, forKey: .contactId)
        try container.encode(contactName, forKey: .contactName)
        try container.encode(occurredAt, forKey: .occurredAt)
        try container.encode(duration, forKey: .duration)
        try container.encode(status, forKey: .status)
        
        try container.encodeIfPresent(summary, forKey: .summary)
        try container.encodeIfPresent(transcript, forKey: .transcript)
        try container.encodeIfPresent(actionItems, forKey: .actionItems)
        try container.encodeIfPresent(audioUrl, forKey: .audioUrl)
        try container.encodeIfPresent(audioStoragePath, forKey: .audioStoragePath)
    }
    
    // MARK: - Manual Initializer
    init(id: String, userId: String, contactId: String, contactName: String, occurredAt: Date, duration: TimeInterval, status: DebriefStatus, summary: String?, transcript: String?, actionItems: [String]?, audioUrl: String?, audioStoragePath: String? = nil) {
        self.id = id
        self.userId = userId
        self.contactId = contactId
        self.contactName = contactName
        self.occurredAt = occurredAt
        self.duration = duration
        self.status = status
        self.summary = summary
        self.transcript = transcript
        self.actionItems = actionItems
        self.audioUrl = audioUrl
        self.audioStoragePath = audioStoragePath
    }
}

// MARK: - Private Decoding Helpers
private extension Debrief {
    /// Tries multiple formats for Date (Double seconds, Int64 milliseconds, or Standard Date)
    static func decodeDate(from container: KeyedDecodingContainer<CodingKeys>) throws -> Date {
        if let timestamp = try? container.decode(Double.self, forKey: .occurredAt) {
            return Date(timeIntervalSince1970: timestamp)
        } else if let millis = try? container.decode(Int64.self, forKey: .occurredAt) {
            return Date(timeIntervalSince1970: TimeInterval(millis) / 1000.0)
        } else {
            return try container.decode(Date.self, forKey: .occurredAt)
        }
    }
    
    /// Tries to decode duration from standard or legacy keys, defaulting to 0
    static func decodeDuration(from container: KeyedDecodingContainer<CodingKeys>) -> TimeInterval {
        if let d = try? container.decode(TimeInterval.self, forKey: .duration) {
            return d
        } else if let d = try? container.decode(TimeInterval.self, forKey: .audioDurationSec) {
            return d
        }
        return 0
    }
}
