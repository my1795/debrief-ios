//
//  RecordViewModel.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 13/01/2026.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth
import Contacts
import UserNotifications

enum RecordingState {
    case recording
    case selectContact
    case processing
    case complete
    case quotaExceeded(reason: QuotaExceededReason)
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
        // Pre-flight quota check - better UX than failing after long recording
        if let quotaReason = await checkQuotaBeforeRecording() {
            state = .quotaExceeded(reason: quotaReason)
            return
        }

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

    /// Pre-flight check: Can user start a new recording?
    /// Returns nil if OK, or QuotaExceededReason if blocked
    private func checkQuotaBeforeRecording() async -> QuotaExceededReason? {
        guard let userId = AuthSession.shared.user?.id else { return nil }

        // Ensure Firebase Auth is ready before making Firestore calls
        guard Auth.auth().currentUser != nil else {
            print("⚠️ [RecordViewModel] Firebase Auth not ready, skipping pre-flight check")
            return nil // Don't block recording, backend will validate
        }

        do {
            let plan = try await FirestoreService.shared.getUserPlan(userId: userId)

            // Check debrief count limit
            if !plan.isUnlimitedDebriefs && plan.weeklyUsage.debriefCount >= plan.weeklyDebriefLimit {
                return .weeklyDebriefLimit
            }

            // Check minutes limit (allow at least 1 minute buffer)
            let usedMinutes = plan.usedMinutes
            if !plan.isUnlimitedMinutes && usedMinutes >= plan.weeklyMinutesLimit {
                return .weeklyMinutesLimit
            }

            // Check storage limit (need at least ~10MB for a recording)
            if !plan.isUnlimitedStorage && plan.usedStorageMB >= (plan.storageLimitMB - 10) {
                return .storageLimit
            }

            return nil
        } catch {
            print("⚠️ [RecordViewModel] Pre-flight quota check failed: \(error)")
            // Don't block recording if check fails - backend will validate
            return nil
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

                    // Auto-stop at max duration (600 seconds / 10 minutes)
                    if currentTime >= AppConfig.shared.maxRecordingDurationSeconds {
                        print("⏱️ [RecordViewModel] Max duration reached (\(AppConfig.shared.maxRecordingDurationSeconds)s), auto-stopping")
                        self.stopRecording()
                    }
                }
            }
        }
    }

    /// Check if recording is approaching the limit (for UI warning)
    var isApproachingLimit: Bool {
        recordingTime >= (AppConfig.shared.maxRecordingDurationSeconds - 60) // Warning at 9 minutes
    }

    /// Remaining recording time in seconds
    var remainingTime: TimeInterval {
        max(0, AppConfig.shared.maxRecordingDurationSeconds - recordingTime)
    }
    
    // MARK: - Contact Actions
    
    // Filter logic handled in groupedContacts computed property
    
    func selectContact(_ contact: Contact) {
        if selectedContact?.id == contact.id {
            selectedContact = nil // Deselect if already selected
        } else {
            selectedContact = contact
        }
    }
    
    func discardRecording() {
        state = .complete // Will trigger view dismissal
        
        // 1. Stop active recording if any (e.g. if cancelled while recording)
        if let activeUrl = recorderService.stopRecording() {
            recorderService.cleanup(url: activeUrl)
        }
        
        // 2. Cleanup stored file (e.g. if cancelled from selection screen)
        cleanup()
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
            
            // Logic: Warn if storage exceeds threshold (User Requirement)
            let limitThreshold = AppConfig.shared.storageWarningThresholdMB
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
        content.body = "You have reached \(AppConfig.shared.storageWarningThresholdMB)MB of storage. Upgrade your plan or free up voice space to continue."
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
