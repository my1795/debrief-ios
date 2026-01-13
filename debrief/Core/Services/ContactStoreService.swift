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
}

class ContactStoreService: ContactStoreServiceProtocol {
    private let store = CNContactStore()
    
    func requestAccess() async -> Bool {
        return await withCheckedContinuation { continuation in
            store.requestAccess(for: .contacts) { granted, error in
                continuation.resume(returning: granted)
            }
        }
    }
    
    func fetchContacts() async throws -> [Contact] {
        let keys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactOrganizationNameKey,
            CNContactIdentifierKey,
            CNContactJobTitleKey
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
            
            // Note: CNContact.identifier is unique per device (e.g., "CD0033...")
            let contact = Contact(
                id: cnContact.identifier,
                name: displayName,
                handle: handle.isEmpty ? nil : handle,
                totalDebriefs: 0 // Local contacts start with 0 history until matched
            )
            contacts.append(contact)
        }
        
        return contacts
    }
}
