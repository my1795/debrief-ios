import Foundation
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

class FirebaseAuthService: AuthServiceProtocol {
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    var currentUser: AuthUser? {
        guard let user = Auth.auth().currentUser else { return nil }
        return mapUser(user)
    }
    
    // MARK: - Sign In
    
    @MainActor
    func signInWithGoogle() async throws -> AuthUser {
        print("🔐 [FirebaseAuthService] Starting Google Sign-In...")
        
        // 1. Get client ID
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("❌ [FirebaseAuthService] Missing Client ID")
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing Client ID"])
        }
        
        // 2. Create config
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // 3. Prompt user (must be on MainActor)
        // Find root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("❌ [FirebaseAuthService] No Root View Controller")
            throw NSError(domain: "AuthError", code: -2, userInfo: [NSLocalizedDescriptionKey: "No Root UI"])
        }
        
        print("🔐 [FirebaseAuthService] Presenting Google UI...")
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        
        // 4. Get credentials
        guard let idToken = result.user.idToken?.tokenString else {
            print("❌ [FirebaseAuthService] Missing ID Token")
            throw NSError(domain: "AuthError", code: -3, userInfo: [NSLocalizedDescriptionKey: "Missing ID Token"])
        }
        let accessToken = result.user.accessToken.tokenString
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                       accessToken: accessToken)
        
        // 5. Sign in to Firebase
        print("🔐 [FirebaseAuthService] Signing in to Firebase...")
        let authResult = try await Auth.auth().signIn(with: credential)
        print("✅ [FirebaseAuthService] Success! User ID: \(authResult.user.uid)")
        
        return mapUser(authResult.user)
    }
    
    func signOut() throws {
        print("👋 [FirebaseAuthService] Signing out...")
        try Auth.auth().signOut()
    }
    
    // MARK: - Listener
    
    func listenToAuthState(onChange: @escaping (AuthUser?) -> Void) -> AnyObject {
        let handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            print("👀 [FirebaseAuthService] Auth State Changed: \(user?.uid ?? "nil")")
            let mapped = user.map { self.mapUser($0) }
            onChange(mapped)
        }
        return handle // Return handle as opaque object
    }
    
    // MARK: - Helper
    
    private func mapUser(_ user: FirebaseAuth.User) -> AuthUser {
        return AuthUser(
            id: user.uid,
            email: user.email,
            displayName: user.displayName,
            photoURL: user.photoURL,
            isAnonymous: user.isAnonymous
        )
    }
}
