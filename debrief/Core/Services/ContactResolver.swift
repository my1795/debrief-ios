//
//  ContactResolver.swift
//  debrief
//
//  Created for Production Refactoring
//

import Foundation

/// Centralized contact name resolution with in-memory caching.
/// Eliminates duplicated resolution logic across ViewModels.
final class ContactResolver {
    static let shared = ContactResolver()
    
    private let contactStore: ContactStoreServiceProtocol
    
    // LRU-style cache (simple dictionary for now, can upgrade to NSCache if needed)
    private var cache: [String: String] = [:]
    private let cacheLimit = 100
    
    private init(contactStore: ContactStoreServiceProtocol = ContactStoreService.shared) {
        self.contactStore = contactStore
    }
    
    // MARK: - Public API
    
    /// Resolve a single contact name with caching
    func resolveName(for contactId: String) async -> String {
        guard !contactId.isEmpty else { return "Unknown" }
        
        // Check cache first
        if let cached = cache[contactId] {
            return cached
        }
        
        // Lookup from device contacts
        let name = await contactStore.getContactName(for: contactId) ?? "Deleted Contact"
        
        // Cache the result
        cacheResult(contactId: contactId, name: name)
        
        return name
    }
    
    /// Resolve contact names for an array of debriefs
    /// Returns new Debrief instances with resolved contactName
    func resolveDebriefs(_ debriefs: [Debrief]) async -> [Debrief] {
        var resolved: [Debrief] = []
        resolved.reserveCapacity(debriefs.count)
        
        for debrief in debriefs {
            let resolvedDebrief = await resolveDebrief(debrief)
            resolved.append(resolvedDebrief)
        }
        
        return resolved
    }
    
    /// Resolve contact name for a single debrief
    func resolveDebrief(_ debrief: Debrief) async -> Debrief {
        guard !debrief.contactId.isEmpty else {
            return debrief.withContactName("Unknown")
        }
        
        let name = await resolveName(for: debrief.contactId)
        return debrief.withContactName(name)
    }
    
    /// Clear the cache (e.g., when contacts are updated)
    func clearCache() {
        cache.removeAll()
    }
    
    // MARK: - Private Helpers
    
    private func cacheResult(contactId: String, name: String) {
        // Simple eviction: if at limit, remove a random entry
        if cache.count >= cacheLimit {
            if let keyToRemove = cache.keys.first {
                cache.removeValue(forKey: keyToRemove)
            }
        }
        cache[contactId] = name
    }
}

// MARK: - Debrief Extension for immutable updates

extension Debrief {
    /// Returns a new Debrief with updated contactName
    func withContactName(_ name: String) -> Debrief {
        Debrief(
            id: id,
            userId: userId,
            contactId: contactId,
            contactName: name,
            occurredAt: occurredAt,
            duration: duration,
            status: status,
            summary: summary,
            transcript: transcript,
            actionItems: actionItems,
            audioUrl: audioUrl,
            audioStoragePath: audioStoragePath
        )
    }
}
