//
//  RecordViewModel.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 13/01/2026.
//

import Foundation
import Combine
import Contacts

enum RecordingState {
    case recording
    case selectContact
    case processing
    case complete
}

@MainActor
class RecordViewModel: ObservableObject {
    // MARK: - Published State
    // MARK: - Published State
    // MARK: - Published State
    @Published var state: RecordingState = .recording
    @Published var recordingTime: TimeInterval = 0
    @Published var selectedContact: Contact?
    @Published var searchQuery: String = ""
    @Published var contacts: [Contact] = []
    
    // Derived state for UI
    var groupedContacts: [(key: String, value: [Contact])] {
        let source = searchQuery.isEmpty ? contacts : contacts.filter {
            $0.name.localizedCaseInsensitiveContains(searchQuery) ||
            ($0.handle?.localizedCaseInsensitiveContains(searchQuery) ?? false)
        }
        
        let grouped = Dictionary(grouping: source) { contact in
            String(contact.name.prefix(1)).uppercased()
        }
        
        return grouped.sorted { $0.key < $1.key }
    }
    
    // MARK: - Dependencies
    private let recorderService: AudioRecorderServiceProtocol
    private let apiService = APIService.shared
    private let contactStoreService: ContactStoreServiceProtocol
    
    // MARK: - Internal State
    private var recordedFileURL: URL?
    private var timerTask: Task<Void, Never>?
    private var contactStoreObserver: NSObjectProtocol?
    
    init(recorderService: AudioRecorderServiceProtocol = AudioRecorderService(),
         contactStoreService: ContactStoreServiceProtocol = ContactStoreService()) {
        self.recorderService = recorderService
        self.contactStoreService = contactStoreService
        
        setupContactObserver()
        
        Task {
            await fetchContacts()
            await startRecording()
        }
    }
    
    private func setupContactObserver() {
        contactStoreObserver = NotificationCenter.default.addObserver(
            forName: .CNContactStoreDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { [weak self] in
                await self?.fetchContacts()
            }
        }
    }
    
    func fetchContacts() async {
        guard await contactStoreService.requestAccess() else {
            print("Access denied")
            return
        }
        
        do {
            let fetched = try await contactStoreService.fetchContacts()
            await MainActor.run {
                self.contacts = fetched.sorted { $0.name < $1.name }
            }
        } catch {
            print("Failed to fetch contacts: \(error)")
        }
    }
    
    // MARK: - Recording Actions
    
    func startRecording() async {
        let granted = await recorderService.requestPermission()
        guard granted else { return }
        
        do {
            try await recorderService.startRecording()
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
    
    // Filter logic handled in groupedContacts computed property
    
    func selectContact(_ contact: Contact) {
        selectedContact = contact
    }
    

    
    // MARK: - Processing Actions
    
    func saveDebrief(onComplete: @escaping () -> Void) {
        guard let url = recordedFileURL, let contact = selectedContact else { return }
        state = .processing
        
        Task {
            do {
                let _ = try await apiService.createDebrief(audioUrl: url, contactId: contact.id, duration: recordingTime)
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
        if let observer = contactStoreObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
