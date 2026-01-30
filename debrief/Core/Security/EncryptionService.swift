//
//  EncryptionService.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 18/01/2026.
//

import Foundation
import CryptoKit

// MARK: - Protocol

protocol EncryptionServiceProtocol {
    func decrypt(_ base64String: String, using key: Data) throws -> String
    func encrypt(_ plaintext: String, using key: Data) throws -> String
    func decryptAudioData(_ encryptedData: Data, using key: Data) throws -> Data
}

/// Handles AES-256-GCM decryption of encrypted debrief fields.
/// Encrypted format:
/// - Text: base64(nonce + ciphertext + tag)
/// - Audio: nonce + ciphertext + tag (raw binary)
final class EncryptionService: EncryptionServiceProtocol {
    static let shared = EncryptionService()
    
    // MARK: - Constants
    
    private let nonceSize = 12    // bytes
    private let tagSize = 16      // bytes (128 bits / 8)
    
    private init() {}
    
    // MARK: - Public API
    
    /// Decrypts a base64 encoded encrypted string using the provided key.
    /// Format: base64(nonce + ciphertext + tag)
    func decrypt(_ base64String: String, using key: Data) throws -> String {
        // 1. Base64 decode
        guard let combinedData = Data(base64Encoded: base64String) else {
            throw EncryptionError.invalidFormat("Invalid base64 encoding")
        }
        
        // 2. Decrypt binary data
        let decryptedData = try decryptData(combinedData, using: key)
        
        // 3. Convert to UTF-8
        guard let plaintext = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.invalidFormat("Decrypted data is not valid UTF-8")
        }
        
        return plaintext
    }
    
    /// Encrypts a plaintext string using the provided key.
    /// Returns: base64(nonce + ciphertext + tag)
    func encrypt(_ plaintext: String, using key: Data) throws -> String {
        guard let data = plaintext.data(using: .utf8) else {
            throw EncryptionError.encryptionFailed("Failed to encode string as UTF-8")
        }
        
        let symmetricKey = SymmetricKey(data: key)
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
            guard let combined = sealedBox.combined else {
                throw EncryptionError.encryptionFailed("Failed to get sealed box data")
            }
            return combined.base64EncodedString()
        } catch {
            throw EncryptionError.encryptionFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Audio / Binary
    
    /// Decrypts audio data (from file/download).
    /// Format: nonce (12) + ciphertext (N) + tag (16)
    func decryptAudioData(_ encryptedData: Data, using key: Data) throws -> Data {
        return try decryptData(encryptedData, using: key)
    }
    
    /// Downloads encrypted audio from URL, decrypts it, and saves to a temporary file.
    func downloadAndDecryptAudio(from url: URL, using key: Data) async throws -> URL {
        Logger.auth("Downloading: \(url.lastPathComponent)")

        // 1. Download
        let (encryptedData, _) = try await URLSession.shared.data(from: url)

        Logger.auth("Downloaded \(encryptedData.count) bytes")

        // 2. Decrypt
        let decryptedData = try decryptAudioData(encryptedData, using: key)

        Logger.auth("Decrypted to \(decryptedData.count) bytes")
        
        // 3. Save
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent(UUID().uuidString + ".m4a")
        try decryptedData.write(to: tempFile)
        
        return tempFile
    }
    
    // MARK: - Core Logic
    
    /// Shared decryption logic for binary data (nonce + ciphertext + tag)
    /// Uses CryptoKit's standard combined format: Nonce (12) + Ciphertext + Tag (16)
    private func decryptData(_ data: Data, using key: Data) throws -> Data {
        let symmetricKey = SymmetricKey(data: key)
        
        do {
            // Use the combined initializer which handles the standard format automatically
            // Standard format: [Nonce (12)] [Ciphertext] [Tag (16)]
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            
            return try AES.GCM.open(sealedBox, using: symmetricKey)
        } catch {
            throw EncryptionError.decryptionFailed(error)
        }
    }
}

// MARK: - Errors

enum EncryptionError: Error, LocalizedError {
    case invalidFormat(String)
    case decryptionFailed(Error)
    case encryptionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat(let reason):
            return "Invalid encrypted format: \(reason)"
        case .decryptionFailed(let underlyingError):
            return "Decryption failed: \(underlyingError.localizedDescription)"
        case .encryptionFailed(let reason):
            return "Encryption failed: \(reason)"
        }
    }
}
