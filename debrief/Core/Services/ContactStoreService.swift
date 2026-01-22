//
//  ContactStoreService.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 13/01/2026.
//

import Foundation
import Contacts

protocol ContactStoreServiceProtocol {
    func requestAccess() async -> Bool
    func fetchContacts() async throws -> [Contact]
    func getContactName(for id: String) async -> String?
    func findContact(byPhone phone: String) async -> Contact?
    func findContact(byEmail email: String) async -> Contact?
}

class ContactStoreService: ContactStoreServiceProtocol {
    static let shared = ContactStoreService()
    private let store = CNContactStore()
    
    // Cache contacts for faster phone/email lookup
    private var cachedContacts: [Contact]?
    private var cacheTimestamp: Date?
    private let cacheValiditySeconds: TimeInterval = 60 // 1 minute cache
    
    func requestAccess() async -> Bool {
        return await withCheckedContinuation { continuation in
            store.requestAccess(for: .contacts) { granted, error in
                continuation.resume(returning: granted)
            }
        }
    }
    
    func fetchContacts() async throws -> [Contact] {
        // Run on background thread to avoid main thread blocking
        return try await Task.detached(priority: .userInitiated) { [store = self.store] in
            let keys = [
                CNContactGivenNameKey,
                CNContactFamilyNameKey,
                CNContactOrganizationNameKey,
                CNContactIdentifierKey,
                CNContactJobTitleKey,
                CNContactPhoneNumbersKey,
                CNContactEmailAddressesKey
            ] as [CNKeyDescriptor]
            
            let request = CNContactFetchRequest(keysToFetch: keys)
            request.sortOrder = .userDefault
            
            var contacts: [Contact] = []
            
            try store.enumerateContacts(with: request) { cnContact, _ in
                let fullName = [cnContact.givenName, cnContact.familyName]
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                
                let displayName = fullName.isEmpty ? cnContact.organizationName : fullName
                let handle = cnContact.organizationName.isEmpty ? cnContact.jobTitle : cnContact.organizationName
                
                let contact = Contact(
                    id: cnContact.identifier,
                    name: displayName,
                    handle: handle.isEmpty ? nil : handle,
                    totalDebriefs: 0,
                    phoneNumbers: cnContact.phoneNumbers.map { $0.value.stringValue },
                    emailAddresses: cnContact.emailAddresses.map { $0.value as String }
                )
                contacts.append(contact)
            }
            
            return contacts
        }.value
        
        // Update cache after background work completes
        // Note: Cache update happens in getOrRefreshCache after this returns
    }
    
    func getContactName(for id: String) async -> String? {
        guard !id.isEmpty else { return nil }
        
        // Use cache-based lookup to avoid CNErrorDomain errors for deleted contacts
        let contacts = await getOrRefreshCache()
        
        if let contact = contacts.first(where: { $0.id == id }) {
            return contact.name.isEmpty ? nil : contact.name
        }
        
        return nil
    }
    
    // MARK: - Phone/Email Lookup
    
    /// Find a contact by phone number (normalized match)
    func findContact(byPhone phone: String) async -> Contact? {
        guard !phone.isEmpty else { return nil }
        
        let contacts = await getOrRefreshCache()
        let normalizedSearch = normalizePhoneNumber(phone)
        
        return contacts.first { contact in
            contact.phoneNumbers.contains { contactPhone in
                normalizePhoneNumber(contactPhone) == normalizedSearch
            }
        }
    }
    
    /// Find a contact by email address (case-insensitive match)
    func findContact(byEmail email: String) async -> Contact? {
        guard !email.isEmpty else { return nil }
        
        let contacts = await getOrRefreshCache()
        let lowercasedSearch = email.lowercased()
        
        return contacts.first { contact in
            contact.emailAddresses.contains { contactEmail in
                contactEmail.lowercased() == lowercasedSearch
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func getOrRefreshCache() async -> [Contact] {
        // Check if cache is valid
        if let cached = cachedContacts,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheValiditySeconds {
            return cached
        }
        
        // Refresh cache (runs off main thread)
        do {
            let contacts = try await fetchContacts()
            // Update cache after background work completes
            cachedContacts = contacts
            cacheTimestamp = Date()
            return contacts
        } catch {
            Logger.warning("Failed to fetch contacts: \(error)")
            return cachedContacts ?? []
        }
    }
    
    private func normalizePhoneNumber(_ phone: String) -> String {
        // Remove all non-digit characters for comparison
        return phone.filter { $0.isNumber }
    }
}
