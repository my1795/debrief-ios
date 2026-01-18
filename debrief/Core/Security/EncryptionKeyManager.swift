//
//  EncryptionKeyManager.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 18/01/2026.
//

import Foundation

/// Orchestrates encryption key exchange, caching, and lifecycle management.
/// Integrates with AuthSession for login/logout flows.
final class EncryptionKeyManager {
    static let shared = EncryptionKeyManager()
    
    private let keychainService = KeychainService.shared
    private let apiService = APIService.shared
    
    /// In-memory cache of the current user's key.
    /// Avoid repeated Keychain reads during a session.
    private var cachedKey: Data?
    private var cachedUserId: String?
    
    private init() {}
    
    // MARK: - Public API
    
    /// Fetches the encryption key from the backend and stores it in Keychain.
    /// Call this after successful login.
    /// - Parameter userId: The authenticated user's ID (for Keychain account)
    func fetchAndStoreKey(userId: String) async throws {
        print("🔐 [EncryptionKeyManager] Fetching encryption key for user: \(userId)")
        
        do {
            let response = try await apiService.exchangeKey()
            
            guard let keyData = response.keyData else {
                throw EncryptionKeyError.invalidKeyData
            }
            
            // Validate key size (should be 32 bytes for AES-256)
            guard keyData.count == 32 else {
                throw EncryptionKeyError.invalidKeySize(keyData.count)
            }
            
            // Store in Keychain
            try keychainService.save(key: keyData, account: userId)
            
            // Update cache
            cachedKey = keyData
            cachedUserId = userId
            
            print("✅ [EncryptionKeyManager] Key stored in Keychain")
            
        } catch let error as APIError where error.isEncryptionNotEnabled {
            // Encryption not enabled on server - this is OK, just log and continue
            print("⚠️ [EncryptionKeyManager] Encryption not enabled on server")
            return
        }
    }
    
    /// Gets the current user's encryption key.
    /// First checks cache, then Keychain.
    /// - Parameter userId: The authenticated user's ID
    /// - Returns: The encryption key, or nil if not available
    func getKey(userId: String) -> Data? {
        // Check cache first
        if let cached = cachedKey, cachedUserId == userId {
            return cached
        }
        
        // Load from Keychain
        if let keyData = keychainService.load(account: userId) {
            cachedKey = keyData
            cachedUserId = userId
            return keyData
        }
        
        return nil
    }
    
    /// Ensures the encryption key is available.
    /// If not in Keychain, fetches from backend.
    /// Call this on app launch when user is already authenticated.
    /// - Parameter userId: The authenticated user's ID
    func ensureKeyAvailable(userId: String) async {
        // Already have key?
        if getKey(userId: userId) != nil {
            print("✅ [EncryptionKeyManager] Key already available")
            return
        }
        
        // Need to fetch
        print("🔄 [EncryptionKeyManager] Key not found, fetching...")
        do {
            try await fetchAndStoreKey(userId: userId)
        } catch {
            print("⚠️ [EncryptionKeyManager] Failed to fetch key: \(error)")
            // Non-fatal: app can still work, decryption will gracefully degrade
        }
    }
    
    /// Clears the encryption key from Keychain and cache.
    /// Call this on logout.
    /// - Parameter userId: The user ID to clear key for (optional, clears cache regardless)
    func clearKey(userId: String?) {
        // Clear cache
        cachedKey = nil
        cachedUserId = nil
        
        // Clear from Keychain
        if let userId = userId {
            do {
                try keychainService.delete(account: userId)
                print("🗑 [EncryptionKeyManager] Key deleted from Keychain")
            } catch {
                print("⚠️ [EncryptionKeyManager] Failed to delete key: \(error)")
            }
        }
    }
}

// MARK: - Errors

enum EncryptionKeyError: Error, LocalizedError {
    case invalidKeyData
    case invalidKeySize(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidKeyData:
            return "Failed to decode encryption key from base64"
        case .invalidKeySize(let size):
            return "Invalid key size: \(size) bytes (expected 32)"
        }
    }
}

// MARK: - APIError Extension

extension APIError {
    /// Returns true if this error indicates encryption is not enabled on the server.
    var isEncryptionNotEnabled: Bool {
        if case .serverError(503) = self {
            return true
        }
        return false
    }
}
