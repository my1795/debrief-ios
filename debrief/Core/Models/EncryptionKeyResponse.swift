//
//  EncryptionKeyResponse.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 18/01/2026.
//

import Foundation

/// Response model for POST /v1/auth/exchange-key endpoint.
struct EncryptionKeyResponse: Codable {
    /// User-specific encryption key (base64 encoded 32-byte key).
    /// Store securely in Keychain.
    let userKey: String
    
    /// Encryption algorithm used (e.g., "AES-256-GCM")
    let algorithm: String
    
    /// Key version for future rotation support (e.g., "v1")
    let version: String
    
    /// Nonce/IV size in bytes (typically 12)
    let nonceSize: Int
    
    /// Auth tag size in bits (typically 128)
    let tagSize: Int
    
    /// Decodes the base64 userKey to raw Data.
    /// Returns nil if decoding fails.
    var keyData: Data? {
        Data(base64Encoded: userKey)
    }
}
