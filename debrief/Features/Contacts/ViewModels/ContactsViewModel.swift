//
//  ContactsViewModel.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 14/01/2026.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ContactsViewModel: ObservableObject {
    @Published var contacts: [Contact] = []
    @Published var isLoading = false
    @Published var error: AppError? = nil  // User-facing errors
    @Published var searchText: String = ""
    
    private let contactStoreService: ContactStoreServiceProtocol
    private var allContacts: [Contact] = []
    
    init(contactStoreService: ContactStoreServiceProtocol = ContactStoreService.shared) {
        self.contactStoreService = contactStoreService
    }
    
    func loadContacts() async {
        isLoading = true
        error = nil
        
        // Check permissions first
        let granted = await contactStoreService.requestAccess()
        guard granted else {
            self.error = .unknown(message: "Permission denied. Please enable contacts access in Settings.")
            self.isLoading = false
            return
        }
        
        do {
            let fetchedContacts = try await contactStoreService.fetchContacts()
            self.allContacts = fetchedContacts
            self.filterContacts()
        } catch {
            print("ERROR Loading Contacts: \(error)")
            self.error = AppError.from(error)
        }
        
        isLoading = false
    }
    
    func filterContacts() {
        if searchText.isEmpty {
            self.contacts = allContacts
        } else {
            self.contacts = allContacts.filter { contact in
                contact.name.localizedCaseInsensitiveContains(searchText) ||
                (contact.handle?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
}
