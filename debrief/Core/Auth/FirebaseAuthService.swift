import Foundation
import FirebaseAuth
import GoogleSignIn
import FirebaseCore
import AuthenticationServices
import CryptoKit

class FirebaseAuthService: NSObject, AuthServiceProtocol {
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?
    private var appleSignInContinuation: CheckedContinuation<AuthUser, Error>?
    
    var currentUser: AuthUser? {
        guard let user = Auth.auth().currentUser else { return nil }
        return mapUser(user)
    }
    
    // MARK: - Sign In
    
    @MainActor
    func signInWithGoogle() async throws -> AuthUser {
        Logger.auth("Starting Google Sign-In...")
        
        // 1. Get client ID
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            Logger.error("Missing Client ID")
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing Client ID"])
        }
        
        // 2. Create config
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // 3. Prompt user (must be on MainActor)
        // Find root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            Logger.error("No Root View Controller")
            throw NSError(domain: "AuthError", code: -2, userInfo: [NSLocalizedDescriptionKey: "No Root UI"])
        }
        
        Logger.auth("Presenting Google UI...")
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        
        // 4. Get credentials
        guard let idToken = result.user.idToken?.tokenString else {
            Logger.error("Missing ID Token")
            throw NSError(domain: "AuthError", code: -3, userInfo: [NSLocalizedDescriptionKey: "Missing ID Token"])
        }
        let accessToken = result.user.accessToken.tokenString
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                       accessToken: accessToken)
        
        // 5. Sign in to Firebase
        Logger.auth("Signing in to Firebase...")
        let authResult = try await Auth.auth().signIn(with: credential)
        Logger.success("Success! User ID: \(authResult.user.uid)")
        
        return mapUser(authResult.user)
    }
    
    func signOut() throws {
        Logger.info("Signing out...")
        try Auth.auth().signOut()
    }

    // MARK: - Apple Sign In

    @MainActor
    func signInWithApple() async throws -> AuthUser {
        Logger.auth("Starting Apple Sign-In...")

        let nonce = randomNonceString()
        currentNonce = nonce

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            throw NSError(domain: "AuthError", code: -2, userInfo: [NSLocalizedDescriptionKey: "No Root UI"])
        }

        authorizationController.presentationContextProvider = ApplePresentationContext(window: window)

        return try await withCheckedThrowingContinuation { continuation in
            self.appleSignInContinuation = continuation
            authorizationController.performRequests()
        }
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Listener
    
    func listenToAuthState(onChange: @escaping (AuthUser?) -> Void) -> AnyObject {
        let handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            Logger.auth("Auth State Changed: \(user?.uid ?? "nil")")
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

// MARK: - ASAuthorizationControllerDelegate

extension FirebaseAuthService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            appleSignInContinuation?.resume(throwing: NSError(domain: "AuthError", code: -4, userInfo: [NSLocalizedDescriptionKey: "Invalid credential type"]))
            appleSignInContinuation = nil
            return
        }

        guard let nonce = currentNonce else {
            appleSignInContinuation?.resume(throwing: NSError(domain: "AuthError", code: -5, userInfo: [NSLocalizedDescriptionKey: "Invalid state: missing nonce"]))
            appleSignInContinuation = nil
            return
        }

        guard let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            appleSignInContinuation?.resume(throwing: NSError(domain: "AuthError", code: -6, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token"]))
            appleSignInContinuation = nil
            return
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        Task {
            do {
                Logger.auth("Signing in to Firebase with Apple credential...")
                let authResult = try await Auth.auth().signIn(with: credential)
                Logger.success("Apple Sign-In Success! User ID: \(authResult.user.uid)")
                appleSignInContinuation?.resume(returning: mapUser(authResult.user))
            } catch {
                Logger.error("Firebase Apple Sign-In Error: \(error)")
                appleSignInContinuation?.resume(throwing: error)
            }
            appleSignInContinuation = nil
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Logger.error("Apple Sign-In Error: \(error)")
        appleSignInContinuation?.resume(throwing: error)
        appleSignInContinuation = nil
    }
}

// MARK: - Apple Presentation Context

private class ApplePresentationContext: NSObject, ASAuthorizationControllerPresentationContextProviding {
    private let window: UIWindow

    init(window: UIWindow) {
        self.window = window
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return window
    }
}
