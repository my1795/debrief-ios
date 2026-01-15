import SwiftUI
import SwiftData
import FirebaseCore
import GoogleSignIn

@main
struct debriefApp: App {
    
    init() {
        FirebaseApp.configure()
        
        // Initialize Background Services
        _ = CallObserverService.shared
        NotificationService.shared.requestAuthorization()
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
