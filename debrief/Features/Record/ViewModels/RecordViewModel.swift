//
//  RecordViewModel.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 13/01/2026.
//

import Foundation
import Combine
import FirebaseFirestore
import Contacts
import UserNotifications

enum RecordingState {
    case recording
    case selectContact
    case processing
    case complete
}

@MainActor
class RecordViewModel: ObservableObject {
    // ... (Existing properties) ...
    // MARK: - Published State
    @Published var state: RecordingState = .recording
    @Published var recordingTime: TimeInterval = 0
    @Published var selectedContact: Contact?
    @Published var searchQuery: String = ""
    @Published var contacts: [Contact] = []
    @Published var processingStatusMessage: String = "Uploading..."
    
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
    
    // ... (Existing Dependencies) ...
    // MARK: - Dependencies
    private let recorderService: AudioRecorderServiceProtocol
    private let apiService = APIService.shared
    private let contactStoreService: ContactStoreServiceProtocol
    
    // ... (Existing Init) ...
    
    // MARK: - Internal State
    private var recordedFileURL: URL?
    private var timerTask: Task<Void, Never>?
    private var contactStoreObserver: NSObjectProtocol?
    
    init(recorderService: AudioRecorderServiceProtocol = AudioRecorderService(),
         contactStoreService: ContactStoreServiceProtocol = ContactStoreService()) {
        self.recorderService = recorderService
        self.contactStoreService = contactStoreService
        
        setupContactObserver()
        
        // Request Notification Permissions lazily
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        
        Task {
            await fetchContacts()
            await startRecording()
        }
    }
    
    // MARK: - Helper Methods
    
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
    
    // Listener Registration
    private var debriefListener: ListenerRegistration?
    
    func saveDebrief(onComplete: @escaping () -> Void) {
        guard let url = recordedFileURL, let contact = selectedContact else { return }
        
        // 1. Fire-and-Forget via Singleton Manager
        DebriefUploadManager.shared.save(audioUrl: url, contact: contact, duration: recordingTime)
        
        // 2. Instant Dismissal
        onComplete()
        
        // 3. Check Quota (Side Effect - still good to trigger here or in manager)
        Task {
           await checkStorageLimit()
        }
    }
    
    private func handleError() {
        state = .complete // Or error state if UI supports it
        // Could show toast/alert here
    }
    
    private func checkStorageLimit() async {
        guard let userId = AuthSession.shared.user?.id else { return }
        
        do {
            let quota = try await FirestoreService.shared.getUserQuota(userId: userId)
            
            // Logic: Warn if used >= 450 MB (User Requirement)
            let limitThreshold = 450
            let hasWarnedKey = "hasWarnedStorageLimit"
            
            if quota.usedStorageMB >= limitThreshold {
                if !UserDefaults.standard.bool(forKey: hasWarnedKey) {
                    sendStorageNotification()
                    UserDefaults.standard.set(true, forKey: hasWarnedKey)
                }
            } else {
                // Reset warning if space is cleared below threshold
                UserDefaults.standard.set(false, forKey: hasWarnedKey)
            }
            
        } catch {
            print("Failed to check quota logic: \(error)")
        }
    }
    
    private func sendStorageNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Storage Almost Full"
        content.body = "You have reached 450MB of storage. Upgrade your plan or free up voice space to continue."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "storage_warning", content: content, trigger: nil) // Deliver immediately
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error)")
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
        debriefListener?.remove()
        if let observer = contactStoreObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
