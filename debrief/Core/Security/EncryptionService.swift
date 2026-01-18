//
//  EncryptionService.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 18/01/2026.
//

import Foundation
import CryptoKit

/// Handles AES-256-GCM decryption of encrypted debrief fields.
/// Encrypted format: v1:base64(nonce + ciphertext + tag)
final class EncryptionService {
    static let shared = EncryptionService()
    
    // MARK: - Constants (from API spec)
    
    private let versionPrefix = "v1:"
    private let nonceSize = 12    // bytes
    private let tagSize = 16      // bytes (128 bits / 8)
    
    private init() {}
    
    // MARK: - Public API
    
    /// Checks if a string value is encrypted (starts with v1: prefix).
    func isEncrypted(_ value: String?) -> Bool {
        guard let value = value else { return false }
        return value.hasPrefix(versionPrefix)
    }
    
    /// Decrypts an encrypted string using the provided key.
    /// - Parameters:
    ///   - ciphertext: The encrypted string in format "v1:base64(...)"
    ///   - key: The 32-byte AES key
    /// - Returns: The decrypted plaintext string
    func decrypt(_ ciphertext: String, using key: Data) throws -> String {
        // 1. Validate and strip prefix
        guard ciphertext.hasPrefix(versionPrefix) else {
            throw EncryptionError.invalidFormat("Missing v1: prefix")
        }
        
        let base64String = String(ciphertext.dropFirst(versionPrefix.count))
        
        // 2. Base64 decode
        guard let combinedData = Data(base64Encoded: base64String) else {
            throw EncryptionError.invalidFormat("Invalid base64 encoding")
        }
        
        // 3. Validate minimum length (nonce + tag)
        let minLength = nonceSize + tagSize
        guard combinedData.count >= minLength else {
            throw EncryptionError.invalidFormat("Data too short: \(combinedData.count) bytes")
        }
        
        // 4. Extract components: nonce (12) + ciphertext (variable) + tag (16)
        let nonce = combinedData.prefix(nonceSize)
        let ciphertextAndTag = combinedData.suffix(from: nonceSize)
        
        // 5. Create AES-GCM key
        let symmetricKey = SymmetricKey(data: key)
        
        // 6. Create sealed box and decrypt
        do {
            let sealedBox = try AES.GCM.SealedBox(
                nonce: AES.GCM.Nonce(data: nonce),
                ciphertext: ciphertextAndTag.dropLast(tagSize),
                tag: ciphertextAndTag.suffix(tagSize)
            )
            
            let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
            
            guard let plaintext = String(data: decryptedData, encoding: .utf8) else {
                throw EncryptionError.invalidFormat("Decrypted data is not valid UTF-8")
            }
            
            return plaintext
            
        } catch let error as EncryptionError {
            throw error
        } catch {
            throw EncryptionError.decryptionFailed(error)
        }
    }
    
    /// Decrypts a string if it's encrypted, otherwise returns the original value.
    /// Returns nil if the input is nil.
    func decryptIfNeeded(_ value: String?, using key: Data) -> String? {
        guard let value = value else { return nil }
        
        guard isEncrypted(value) else {
            return value // Not encrypted, return as-is
        }
        
        do {
            return try decrypt(value, using: key)
        } catch {
            print("⚠️ [EncryptionService] Decryption failed: \(error). Returning original value.")
            return value // Graceful degradation
        }
    }
    
    /// Decrypts an array of strings if they're encrypted.
    func decryptIfNeeded(_ values: [String]?, using key: Data) -> [String]? {
        guard let values = values else { return nil }
        
        return values.map { value in
            decryptIfNeeded(value, using: key) ?? value
        }
    }
}

// MARK: - Errors

enum EncryptionError: Error, LocalizedError {
    case invalidFormat(String)
    case decryptionFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat(let reason):
            return "Invalid encrypted format: \(reason)"
        case .decryptionFailed(let underlyingError):
            return "Decryption failed: \(underlyingError.localizedDescription)"
        }
    }
}
