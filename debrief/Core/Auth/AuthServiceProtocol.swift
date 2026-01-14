import Foundation

struct AuthUser {
    let id: String
    let email: String?
    let displayName: String?
    let photoURL: URL?
    let isAnonymous: Bool
}

protocol AuthServiceProtocol {
    var currentUser: AuthUser? { get }
    func signInWithGoogle() async throws -> AuthUser
    func signOut() throws
    func listenToAuthState(onChange: @escaping (AuthUser?) -> Void) -> AnyObject // Returns observer handle
}
