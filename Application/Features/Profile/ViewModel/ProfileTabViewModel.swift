import Foundation
import OSLog
import FirebaseAuth
import SwiftUI

@Observable
final class ProfileTabViewModel {
    private(set) var userProfile: UserProfile?
    private(set) var isLoading = false
    private(set) var error: Error?
    
    @MainActor var name: String = ""
    @MainActor var profileImage: UIImage?
    @MainActor var isEditingName: Bool = false
    @MainActor var hasNameBeenSet: Bool = false
    
    private let firestoreService: FirestoreService
    private let logger = Logger(subsystem: "com.application", category: "ProfileTabViewModel")
    
    init(firestoreService: FirestoreService = .shared) {
        self.firestoreService = firestoreService
        logger.info("ProfileTabViewModel initialized")
    }
    
    @MainActor
    func fetchUserProfile() async {
        isLoading = true
        error = nil
        
        do {
            logger.info("Fetching user profile")
            guard let profile = try await firestoreService.fetchUserProfile() else {
                logger.warning("User profile not found")
                isLoading = false
                return
            }
            
            userProfile = profile
            name = profile.name
            hasNameBeenSet = !profile.name.isEmpty
            
            // Load profile image if exists
            if let imageData = profile.profileImageData, 
               let image = UIImage(data: imageData) {
                profileImage = image
            }
            
            logger.info("User profile successfully retrieved: \(profile.name)")
        } catch {
            logger.error("Error fetching user profile: \(error.localizedDescription)")
            self.error = error
        }
        
        isLoading = false
    }
    
    @MainActor
    func updateUserName() async {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            logger.warning("Username cannot be empty")
            self.error = NSError(domain: "ProfileTabViewModel", code: 400, userInfo: [
                NSLocalizedDescriptionKey: "Name field cannot be empty!"
            ])
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            logger.info("Updating username: \(self.name)")
            try await firestoreService.updateUserProfile(name: self.name)
            
            // Refresh profile
            await fetchUserProfile()
            isEditingName = false
            hasNameBeenSet = true
            
            logger.info("Username successfully updated")
        } catch {
            logger.error("Error updating username: \(error.localizedDescription)")
            self.error = error
            isLoading = false
        }
    }
    
    @MainActor
    func uploadProfileImage(image: UIImage) async {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            logger.error("Failed to convert image to data")
            self.error = NSError(domain: "ProfileTabViewModel", code: 400, userInfo: [
                NSLocalizedDescriptionKey: "Failed to process image"
            ])
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            logger.info("Uploading profile image")
            try await firestoreService.updateUserProfileImage(imageData: imageData)
            profileImage = image
            
            // Refresh profile
            await fetchUserProfile()
            
            logger.info("Profile image successfully uploaded")
        } catch {
            logger.error("Error uploading profile image: \(error.localizedDescription)")
            self.error = error
            isLoading = false
        }
    }
    
    @MainActor
    func toggleNameEditing() {
        isEditingName = !isEditingName
    }
    
    func handleLogout(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try Auth.auth().signOut()
            logger.info("User logged out")
            completion(.success(()))
        } catch {
            logger.error("Error logging out: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
} 