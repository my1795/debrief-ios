//
//  AuthSession.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 13/01/2026.
//

import Foundation
import Combine

// Placeholder for User model if not yet defined
struct User: Identifiable, Codable {
    let id: String
    let email: String?
    let displayName: String?
    let photoURL: URL?
}

@MainActor
class AuthSession: ObservableObject {
    static let shared = AuthSession() // Singleton for easier access in non-view contexts
    @Published var user: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var error: Error?

    private let authService: AuthServiceProtocol
    private var authListenerHandle: AnyObject?
    
    init(authService: AuthServiceProtocol = FirebaseAuthService()) {
        self.authService = authService
        
        // Listen to auth state changes immediately
        self.authListenerHandle = authService.listenToAuthState { [weak self] authUser in
            Task { @MainActor in
                self?.handleAuthStateChange(authUser)
            }
        }
    }
    
    deinit {
        // Handle cleanup if needed (FirebaseAuth listener is usually auto-managed but good practice)
    }
    
    private func handleAuthStateChange(_ authUser: AuthUser?) {
        if let authUser = authUser {
            Logger.success("User is signed in: \(authUser.id)")
            self.user = User(
                id: authUser.id,
                email: authUser.email,
                displayName: authUser.displayName,
                photoURL: authUser.photoURL
            )
            self.isAuthenticated = true
            
            // Ensure encryption key is available (recovery on app launch)
            Task {
                await EncryptionKeyManager.shared.ensureKeyAvailable(userId: authUser.id)
            }
        } else {
            Logger.info("User is signed out")
            self.user = nil
            self.isAuthenticated = false
        }
    }
    
    func signInWithGoogle() async {
        isLoading = true
        error = nil
        
        do {
            let authUser = try await authService.signInWithGoogle()
            // State update handled by listener
            
            // Fetch and store encryption key after successful login
            try await EncryptionKeyManager.shared.fetchAndStoreKey(userId: authUser.id)
        } catch {
            Logger.error("Sign In Error: \(error)")
            self.error = error
        }
        
        isLoading = false
    }
    
    func signOut() {
        // Get user ID before signing out for key cleanup
        let userId = user?.id
        
        do {
            // Clear encryption key first
            EncryptionKeyManager.shared.clearKey(userId: userId)
            
            try authService.signOut()
        } catch {
            Logger.error("Sign Out Error: \(error)")
            self.error = error
        }
    }
}
