//
//  CallModels.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 15/01/2026.
//

import Foundation

// MARK: - Core Domain Models

/// Represents a completed call stat to be synced
struct CallStat: Codable, Identifiable {
    var id: UUID = UUID()
    let timestamp: Date // End time
    let duration: TimeInterval
}

// MARK: - API DTOs

/// Request payload for call sync
struct CallSyncRequest: Codable {
    let calls: [CallSyncItem]
}

struct CallSyncItem: Codable {
    let timestamp: Int64
    let durationSec: Int
}

struct CallSyncResponse: Codable {
    let syncedCount: Int
}
