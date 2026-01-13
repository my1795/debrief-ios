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

    init() {
        // Check for existing session (mock implementation)
        // In real app, check Keychain/UserDefaults or Firebase.auth.currentUser
    }
    
    func signInWithGoogle() async {
        isLoading = true
        error = nil
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        
        // Mock successful sign in
        self.user = User(id: "mock_user_123", email: "test@example.com", displayName: "Test User", photoURL: nil)
        self.isAuthenticated = true
        self.isLoading = false
    }
    
    func signOut() {
        self.user = nil
        self.isAuthenticated = false
    }
}
