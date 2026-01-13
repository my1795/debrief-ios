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
    let contactName: String
    let occurredAt: Date
    let duration: TimeInterval // seconds
    let status: DebriefStatus
    let summary: String?
    let transcript: String?
    let actionItems: [String]?
    
    // For mock data convenience
    var debriefId: String { id }
}
