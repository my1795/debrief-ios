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
    // MARK: - Published State
    @Published var state: RecordingState = .recording
    @Published var recordingTime: TimeInterval = 0
    @Published var selectedContact: Contact?
    @Published var searchQuery: String = ""
    @Published var contacts: [Contact] = []
    @Published var filteredContacts: [Contact] = []
    
    // New Contact Form
    @Published var isNewContactFormVisible: Bool = false
    @Published var newContactName: String = ""
    @Published var newContactHandle: String = ""
    
    // MARK: - Dependencies
    private let recorderService: AudioRecorderServiceProtocol
    private let apiService = APIService.shared
    
    // MARK: - Internal State
    private var recordedFileURL: URL?
    private var timerTask: Task<Void, Never>?
    
    init(recorderService: AudioRecorderServiceProtocol = AudioRecorderService()) {
        self.recorderService = recorderService
        loadMockContacts()
        
        // Auto-start recording as per previous flow behavior
        Task {
            await startRecording()
        }
    }
    
    func loadMockContacts() {
        self.contacts = [
            Contact(id: UUID().uuidString, name: "Ahmet", handle: "TechCorp", totalDebriefs: 5),
            Contact(id: UUID().uuidString, name: "Sarah", handle: "Design Lead", totalDebriefs: 3),
            Contact(id: UUID().uuidString, name: "Mehmet", handle: "Engineering", totalDebriefs: 8),
            Contact(id: UUID().uuidString, name: "Elif", handle: "Product", totalDebriefs: 2)
        ]
        self.filteredContacts = self.contacts
    }
    
    // MARK: - Recording Actions
    
    func startRecording() async {
        let granted = await recorderService.requestPermission()
        guard granted else { return }
        
        do {
            try recorderService.startRecording()
            state = .recording
            startTimer()
        } catch {
            print("Failed to start: \(error)")
        }
    }
    
    func stopRecording() {
        timerTask?.cancel()
        timerTask = nil
        
        recordedFileURL = recorderService.stopRecording()
        state = .selectContact
    }
    
    private func startTimer() {
        timerTask?.cancel()
        
        timerTask = Task { [weak self] in
            guard let self = self else { return }
            
            while !Task.isCancelled {
                // Update time roughly every 0.1s ensures smooth UI without blocking main thread
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 sec
                
                guard !Task.isCancelled else { break }
                
                let currentTime = self.recorderService.currentTime
                await MainActor.run {
                    self.recordingTime = currentTime
                }
            }
        }
    }
    
    // MARK: - Contact Actions
    
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
        
        Task {
            do {
                let newContact = try await apiService.createContact(name: newContactName, handle: newContactHandle)
                contacts.append(newContact)
                selectContact(newContact)
                isNewContactFormVisible = false
                newContactName = ""
                newContactHandle = ""
                filterContacts()
            } catch {
                print("Failed to create contact: \(error)")
                let newContact = Contact(id: UUID().uuidString, name: newContactName, handle: newContactHandle, totalDebriefs: 0)
                contacts.append(newContact)
                selectContact(newContact)
                isNewContactFormVisible = false 
                newContactName = ""
                newContactHandle = ""
                filterContacts()
            }
        }
    }
    
    // MARK: - Processing Actions
    
    func saveDebrief(onComplete: @escaping () -> Void) {
        guard let url = recordedFileURL, let contact = selectedContact else { return }
        state = .processing
        
        Task {
            do {
                let _ = try await apiService.createDebrief(audioUrl: url, contactId: contact.id)
                state = .complete
                try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
                onComplete()
            } catch {
                print("Upload failed: \(error)")
                try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
                state = .complete
                try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
                onComplete()
            }
        }
    }
    
    func cleanup() {
        timerTask?.cancel()
        if let url = recordedFileURL {
            recorderService.cleanup(url: url)
        }
    }
    
    deinit {
        timerTask?.cancel()
    }
}
