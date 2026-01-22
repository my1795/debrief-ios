//
//  ContactResolver.swift
//  debrief
//
//  Created for Production Refactoring
//

import Foundation

/// Centralized contact name resolution with cascade lookup and Firebase sync.
/// Resolution order: contactId → phone → email → fallback to debrief.contactName
final class ContactResolver {
    static let shared = ContactResolver()
    
    private let contactStore: ContactStoreServiceProtocol
    private let firestoreService: FirestoreService
    
    // LRU-style cache (simple dictionary for now, can upgrade to NSCache if needed)
    private var cache: [String: String] = [:]
    private let cacheLimit = 100
    
    private init(
        contactStore: ContactStoreServiceProtocol = ContactStoreService.shared,
        firestoreService: FirestoreService = FirestoreService.shared
    ) {
        self.contactStore = contactStore
        self.firestoreService = firestoreService
    }
    
    // MARK: - Public API
    
    /// Resolve a single contact name with caching (by ID only)
    func resolveName(for contactId: String) async -> String {
        guard !contactId.isEmpty else { return "Unknown" }
        
        // Check cache first
        if let cached = cache[contactId] {
            return cached
        }
        
        // Lookup from device contacts by ID
        if let name = await contactStore.getContactName(for: contactId) {
            cacheResult(contactId: contactId, name: name)
            return name
        }
        
        return "Unknown"
    }
    
    /// Resolve contact names for an array of debriefs with cascade logic.
    /// Updates Firebase when a phone/email match is found.
    func resolveDebriefs(_ debriefs: [Debrief]) async -> [Debrief] {
        var resolved: [Debrief] = []
        resolved.reserveCapacity(debriefs.count)
        
        for debrief in debriefs {
            let resolvedDebrief = await resolveDebrief(debrief)
            resolved.append(resolvedDebrief)
        }
        
        return resolved
    }
    
    /// Resolve contact name for a single debrief with cascade lookup.
    /// Order: contactId → phoneNumber → email → fallback to stored contactName
    func resolveDebrief(_ debrief: Debrief) async -> Debrief {
        // 1. Try contactId lookup first
        if !debrief.contactId.isEmpty {
            if let name = await contactStore.getContactName(for: debrief.contactId) {
                cacheResult(contactId: debrief.contactId, name: name)
                return debrief.withContactName(name)
            }
        }
        
        // 2. Try phone number match
        if let phone = debrief.phoneNumber, !phone.isEmpty {
            if let matchedContact = await contactStore.findContact(byPhone: phone) {
                let name = matchedContact.name
                Logger.info("Matched by phone: \(phone) → \(name)")
                
                // Update Firebase in background
                Task {
                    await updateFirebaseContactName(debriefId: debrief.id, contactName: name)
                }
                
                cacheResult(contactId: debrief.contactId, name: name)
                return debrief.withContactName(name)
            }
        }
        
        // 3. Try email match
        if let email = debrief.email, !email.isEmpty {
            if let matchedContact = await contactStore.findContact(byEmail: email) {
                let name = matchedContact.name
                Logger.info("Matched by email: \(email) → \(name)")
                
                // Update Firebase in background
                Task {
                    await updateFirebaseContactName(debriefId: debrief.id, contactName: name)
                }
                
                cacheResult(contactId: debrief.contactId, name: name)
                return debrief.withContactName(name)
            }
        }
        
        // 4. Fallback: Use the stored contactName from Firebase
        // If contactName is empty or "Unknown", keep it as is (already set in model)
        let fallbackName = debrief.contactName.isEmpty ? "Unknown" : debrief.contactName
        return debrief.withContactName(fallbackName)
    }
    
    /// Clear the cache (e.g., when contacts are updated)
    func clearCache() {
        cache.removeAll()
    }
    
    // MARK: - Private Helpers
    
    private func cacheResult(contactId: String, name: String) {
        guard !contactId.isEmpty else { return }
        
        // Simple eviction: if at limit, remove a random entry
        if cache.count >= cacheLimit {
            if let keyToRemove = cache.keys.first {
                cache.removeValue(forKey: keyToRemove)
            }
        }
        cache[contactId] = name
    }
    
    private func updateFirebaseContactName(debriefId: String, contactName: String) async {
        do {
            try await firestoreService.updateDebriefContactName(
                debriefId: debriefId,
                contactName: contactName
            )
        } catch {
            Logger.warning("Failed to update Firebase: \(error)")
        }
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
            audioStoragePath: audioStoragePath,
            encrypted: encrypted,
            phoneNumber: phoneNumber,
            email: email
        )
    }
}
