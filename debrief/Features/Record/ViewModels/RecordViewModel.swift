//
//  RecordViewModel.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 13/01/2026.
//

import Foundation
import Combine

enum RecordingState {
    case recording
    case selectContact
    case processing
    case complete
}

@MainActor
class RecordViewModel: ObservableObject {
    @Published var state: RecordingState = .recording
    @Published var recordingTime: Int = 0
    @Published var selectedContact: Contact?
    @Published var searchQuery: String = ""
    @Published var contacts: [Contact] = []
    @Published var filteredContacts: [Contact] = []
    @Published var isNewContactFormVisible: Bool = false
    
    // New Contact Form
    @Published var newContactName: String = ""
    @Published var newContactHandle: String = ""
    
    private var timer: Timer?
    
    init() {
        startRecording() // Auto-start as per React effect
        loadMockContacts()
    }
    
    func loadMockContacts() {
        self.contacts = [
            Contact(id: "c1", name: "Ahmet", handle: "TechCorp", totalDebriefs: 5),
            Contact(id: "c2", name: "Sarah", handle: "Design Lead", totalDebriefs: 3),
            Contact(id: "c3", name: "Mehmet", handle: "Engineering", totalDebriefs: 8),
            Contact(id: "c4", name: "Elif", handle: "Product", totalDebriefs: 2)
        ]
        self.filteredContacts = self.contacts
    }
    
    func startRecording() {
        print("Starting recording...")
        state = .recording
        recordingTime = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.recordingTime += 1
            }
        }
    }
    
    func stopRecording() {
        print("Stopping recording...")
        timer?.invalidate()
        timer = nil
        state = .selectContact
    }
    
    func filterContacts() {
        if searchQuery.isEmpty {
            filteredContacts = contacts
        } else {
            filteredContacts = contacts.filter {
                $0.name.localizedCaseInsensitiveContains(searchQuery) ||
                ($0.handle?.localizedCaseInsensitiveContains(searchQuery) ?? false)
            }
        }
    }
    
    func selectContact(_ contact: Contact) {
        selectedContact = contact
    }
    
    func createContact() {
        guard !newContactName.isEmpty else { return }
        let newContact = Contact(id: UUID().uuidString, name: newContactName, handle: newContactHandle.isEmpty ? nil : newContactHandle, totalDebriefs: 0)
        contacts.append(newContact)
        selectContact(newContact)
        isNewContactFormVisible = false
        newContactName = ""
        newContactHandle = ""
        filterContacts()
    }
    
    func saveDebrief(onComplete: @escaping () -> Void) {
        state = .processing
        
        // Simulate processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.state = .complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                onComplete()
            }
        }
    }
}
