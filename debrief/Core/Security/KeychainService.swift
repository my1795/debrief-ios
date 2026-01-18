//
//  KeychainService.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 18/01/2026.
//

import Foundation
import Security

/// Keychain wrapper for secure storage of encryption keys.
/// Uses kSecClassGenericPassword for storing binary data.
final class KeychainService {
    static let shared = KeychainService()
    
    private let service = "com.debrief.encryption"
    
    private init() {}
    
    // MARK: - Public API
    
    /// Stores a key in the Keychain.
    /// - Parameters:
    ///   - key: The key data to store
    ///   - account: The account identifier (e.g., user ID)
    func save(key: Data, account: String) throws {
        // Delete existing item first (update pattern)
        try? delete(account: account)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            print("❌ [KeychainService] Failed to save key: \(status)")
            throw KeychainError.saveFailed(status)
        }
        
        print("✅ [KeychainService] Key saved for account: \(account)")
    }
    
    /// Loads a key from the Keychain.
    /// - Parameter account: The account identifier
    /// - Returns: The key data, or nil if not found
    func load(account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status != errSecItemNotFound {
                print("⚠️ [KeychainService] Load failed: \(status)")
            }
            return nil
        }
        
        return result as? Data
    }
    
    /// Deletes a key from the Keychain.
    /// - Parameter account: The account identifier
    func delete(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            print("❌ [KeychainService] Failed to delete key: \(status)")
            throw KeychainError.deleteFailed(status)
        }
        
        print("🗑 [KeychainService] Key deleted for account: \(account)")
    }
    
    /// Clears all keys stored by this service.
    func clearAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
        
        print("🗑 [KeychainService] All keys cleared")
    }
}

// MARK: - Errors

enum KeychainError: Error, LocalizedError {
    case saveFailed(OSStatus)
    case deleteFailed(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to Keychain (status: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete from Keychain (status: \(status))"
        }
    }
}
