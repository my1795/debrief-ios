import SwiftUI
import SwiftData
import FirebaseCore
import GoogleSignIn
import RevenueCat

@main
struct debriefApp: App {

    init() {
        configureFirebase()
        configureRevenueCat()

        // Initialize Background Services
        _ = CallObserverService.shared
        NotificationService.shared.requestAuthorization()
    }

    /// Configure RevenueCat SDK
    private func configureRevenueCat() {
        // Configure with anonymous user initially
        // Will login with Firebase UID after auth
        SubscriptionService.shared.configure(appUserID: nil)
    }
    
    /// Configure Firebase with environment-specific config file
    private func configureFirebase() {
        let configFileName = AppConfig.shared.firebaseConfigFileName
        
        if let path = Bundle.main.path(forResource: configFileName, ofType: "plist"),
           let options = FirebaseOptions(contentsOfFile: path) {
            FirebaseApp.configure(options: options)
            Logger.info("Firebase configured with: \(configFileName).plist")
        } else {
            // Fallback to default GoogleService-Info.plist
            FirebaseApp.configure()
            Logger.info("Firebase configured with default GoogleService-Info.plist")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
        .onChange(of: ScenePhase.active) { newPhase in
             if newPhase == .active {
                 Task {
                     try? await StatsService().syncPendingCalls()
                 }
             }
        }
    }
}
