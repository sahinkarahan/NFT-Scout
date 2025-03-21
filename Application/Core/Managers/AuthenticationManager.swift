import Foundation
import FirebaseAuth
import Alamofire

enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case userNotFound
    case wrongPassword
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .weakPassword:
            return "Password should be at least 6 characters"
        case .userNotFound:
            return "No user found with this email"
        case .wrongPassword:
            return "Incorrect password"
        case .unknown(let message):
            return message
        }
    }
}

// Dinleyici sınıfını actor dışında tanımlıyoruz
private final class AuthStateHandler {
    static let shared = AuthStateHandler()
    private init() {}
    
    var listener: AuthStateDidChangeListenerHandle?
    
    func setup(callback: @escaping (User?) -> Void) {
        // Önce varolan dinleyiciyi temizle
        removeListener()
        
        // Yeni dinleyici oluştur
        listener = Auth.auth().addStateDidChangeListener { _, user in
            callback(user)
        }
    }
    
    func removeListener() {
        if let handle = listener {
            Auth.auth().removeStateDidChangeListener(handle)
            listener = nil
        }
    }
    
    deinit {
        removeListener()
    }
}

@Observable
@MainActor
final class AuthenticationManager {
    static let shared = AuthenticationManager()
    
    private init() {
        setupAuthStateListener()
    }
    
    private(set) var currentUser: User? = Auth.auth().currentUser {
        didSet {
            print("Current user updated: \(String(describing: currentUser?.email))")
        }
    }
    
    private func setupAuthStateListener() {
        // Actor dışında tanımlanmış handler'ı kullanıyoruz
        AuthStateHandler.shared.setup { [weak self] user in
            Task { @MainActor in
                self?.currentUser = user
            }
        }
    }
    
    deinit {
        // Dinleyici yönetimi artık AuthStateHandler sınıfı tarafından yapılıyor
        print("AuthenticationManager deinit called")
    }
    
    func createUser(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            currentUser = result.user
            print("User created: \(result.user.uid)")
        } catch {
            throw handleError(error)
        }
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            guard FormValidator.isValidEmail(email) else {
                throw AuthError.invalidEmail
            }
            
            guard FormValidator.isValidPassword(password) else {
                throw AuthError.weakPassword
            }
            
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            currentUser = result.user
            print("User signed in: \(result.user.uid)")
        } catch {
            throw handleError(error)
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        currentUser = nil
    }
    
    func handleLogout(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try signOut()
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    private func handleError(_ error: Error) -> AuthError {
        let nsError = error as NSError
        
        switch nsError.code {
        case AuthErrorCode.invalidEmail.rawValue:
            return .invalidEmail
        case AuthErrorCode.weakPassword.rawValue:
            return .weakPassword
        case AuthErrorCode.userNotFound.rawValue:
            return .userNotFound
        case AuthErrorCode.wrongPassword.rawValue:
            return .wrongPassword
        default:
            return .unknown(nsError.localizedDescription)
        }
    }
} 
