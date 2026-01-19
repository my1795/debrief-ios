import SwiftUI
import SwiftData
import FirebaseCore
import GoogleSignIn

@main
struct debriefApp: App {
    
    init() {
        configureFirebase()
        
        // Initialize Background Services
        _ = CallObserverService.shared
        NotificationService.shared.requestAuthorization()
    }
    
    /// Configure Firebase with environment-specific config file
    private func configureFirebase() {
        let configFileName = AppConfig.shared.firebaseConfigFileName
        
        if let path = Bundle.main.path(forResource: configFileName, ofType: "plist"),
           let options = FirebaseOptions(contentsOfFile: path) {
            FirebaseApp.configure(options: options)
            print("🔥 [Firebase] Configured with: \(configFileName).plist")
        } else {
            // Fallback to default GoogleService-Info.plist
            FirebaseApp.configure()
            print("🔥 [Firebase] Configured with default GoogleService-Info.plist")
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
