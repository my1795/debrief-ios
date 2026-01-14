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
            print("✅ [AuthSession] User is signed in: \(authUser.id)")
            self.user = User(
                id: authUser.id,
                email: authUser.email,
                displayName: authUser.displayName,
                photoURL: authUser.photoURL
            )
            self.isAuthenticated = true
        } else {
            print("👋 [AuthSession] User is signed out")
            self.user = nil
            self.isAuthenticated = false
        }
    }
    
    func signInWithGoogle() async {
        isLoading = true
        error = nil
        
        do {
            let _ = try await authService.signInWithGoogle()
            // State update handled by listener
        } catch {
            print("❌ [AuthSession] Sign In Error: \(error)")
            self.error = error
        }
        
        isLoading = false
    }
    
    func signOut() {
        do {
            try authService.signOut()
        } catch {
            print("❌ [AuthSession] Sign Out Error: \(error)")
            self.error = error
        }
    }
}
