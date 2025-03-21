import Foundation
import FirebaseFirestore
import FirebaseAuth
import OSLog

// MARK: - Models
struct UserProfile: Codable {
    let id: String
    var name: String
    var email: String
    var createdAt: Date
    var updatedAt: Date
    var profileImageData: Data?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case profileImageData = "profile_image_data"
    }
}

// MARK: - FirestoreService
final class FirestoreService {
    static let shared = FirestoreService()
    
    private let db = Firestore.firestore()
    private let logger = Logger(subsystem: "com.application", category: "FirestoreService")
    
    private init() {
        logger.info("FirestoreService initialized")
    }
    
    // MARK: - Collections
    private var usersCollection: CollectionReference {
        return db.collection("users")
    }
    
    private func userFavoritesCollection(userId: String) -> CollectionReference {
        return usersCollection.document(userId).collection("favorites")
    }
    
    // MARK: - User Profile Methods
    func fetchUserProfile() async throws -> UserProfile? {
        guard let currentUser = Auth.auth().currentUser else {
            logger.error("User not logged in")
            return nil
        }
        
        do {
            let document = try await usersCollection.document(currentUser.uid).getDocument()
            
            if document.exists {
                logger.info("User profile found")
                let data = document.data()!
                
                var profileImageData: Data? = nil
                if let base64String = data["profile_image_data"] as? String {
                    profileImageData = Data(base64Encoded: base64String)
                }
                
                return UserProfile(
                    id: currentUser.uid,
                    name: data["name"] as? String ?? "",
                    email: data["email"] as? String ?? currentUser.email ?? "",
                    createdAt: (data["created_at"] as? Timestamp)?.dateValue() ?? Date(),
                    updatedAt: (data["updated_at"] as? Timestamp)?.dateValue() ?? Date(),
                    profileImageData: profileImageData
                )
            } else {
                // Create user record if it doesn't exist
                let newUser = UserProfile(
                    id: currentUser.uid,
                    name: currentUser.displayName ?? "",
                    email: currentUser.email ?? "",
                    createdAt: Date(),
                    updatedAt: Date(),
                    profileImageData: nil
                )
                
                try await createUserProfile(newUser)
                return newUser
            }
        } catch {
            logger.error("Error fetching user profile: \(error.localizedDescription)")
            throw error
        }
    }
    
    func createUserProfile(_ user: UserProfile) async throws {
        do {
            var userData: [String: Any] = [
                "name": user.name,
                "email": user.email,
                "created_at": Timestamp(date: user.createdAt),
                "updated_at": Timestamp(date: user.updatedAt)
            ]
            
            if let imageData = user.profileImageData {
                userData["profile_image_data"] = imageData.base64EncodedString()
            }
            
            try await usersCollection.document(user.id).setData(userData)
            logger.info("User profile created: \(user.id)")
        } catch {
            logger.error("Error creating user profile: \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateUserProfile(name: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            logger.error("User not logged in")
            throw NSError(domain: "FirestoreService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        do {
            try await usersCollection.document(currentUser.uid).updateData([
                "name": name,
                "updated_at": Timestamp(date: Date())
            ])
            logger.info("User profile updated: \(currentUser.uid)")
        } catch {
            logger.error("Error updating user profile: \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateUserProfileImage(imageData: Data) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            logger.error("User not logged in")
            throw NSError(domain: "FirestoreService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        do {
            try await usersCollection.document(currentUser.uid).updateData([
                "profile_image_data": imageData.base64EncodedString(),
                "updated_at": Timestamp(date: Date())
            ])
            logger.info("User profile image updated: \(currentUser.uid)")
        } catch {
            logger.error("Error updating user profile image: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Favorites Methods
    func addFavorite(collectionId: String, collection: NFTCollection) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            logger.error("User not logged in")
            throw NSError(domain: "FirestoreService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        do {
            // CoinGecko API'den gelen koleksiyon verilerini Firestore'a kaydet
            var data: [String: Any] = [
                "id": collection.id,
                "name": collection.name,
                "contract_address": collection.contractAddress,
                "asset_platform_id": collection.assetPlatformId,
                "symbol": collection.symbol,
                "added_at": Timestamp(date: Date())
            ]
            
            // Opsiyonel alanları ekle
            if let imageSmall = collection.image?.small {
                data["image_small"] = imageSmall
            }
            
            if let description = collection.description {
                data["description"] = description
            }
            
            if let nativeCurrencySymbol = collection.nativeCurrencySymbol {
                data["native_currency_symbol"] = nativeCurrencySymbol
            }
            
            try await userFavoritesCollection(userId: currentUser.uid).document(collectionId).setData(data)
            logger.info("Collection added to favorites: \(collectionId)")
        } catch {
            logger.error("Error adding to favorites: \(error.localizedDescription)")
            throw error
        }
    }
    
    func removeFavorite(collectionId: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            logger.error("User not logged in")
            throw NSError(domain: "FirestoreService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        do {
            try await userFavoritesCollection(userId: currentUser.uid).document(collectionId).delete()
            logger.info("Collection removed from favorites: \(collectionId)")
        } catch {
            logger.error("Error removing from favorites: \(error.localizedDescription)")
            throw error
        }
    }
    
    func isFavorite(collectionId: String) async throws -> Bool {
        guard let currentUser = Auth.auth().currentUser else {
            logger.error("User not logged in")
            return false
        }
        
        do {
            let document = try await userFavoritesCollection(userId: currentUser.uid).document(collectionId).getDocument()
            return document.exists
        } catch {
            logger.error("Error checking favorite status: \(error.localizedDescription)")
            return false
        }
    }
    
    // Favori koleksiyon ID'lerini getir
    func getFavoriteCollectionIds() async throws -> [String] {
        guard let currentUser = Auth.auth().currentUser else {
            logger.error("User not logged in")
            return []
        }
        
        do {
            let snapshot = try await userFavoritesCollection(userId: currentUser.uid).order(by: "added_at", descending: true).getDocuments()
            
            let favoriteIds = snapshot.documents.compactMap { document -> String? in
                return document.data()["id"] as? String
            }
            
            logger.info("Favorite collection IDs fetched: \(favoriteIds.count) collections")
            return favoriteIds
        } catch {
            logger.error("Error fetching favorite collection IDs: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Bu metod artık kullanılmayacak, yerine getFavoriteCollectionIds kullanılacak
    // ve CoinGeckoManager ile detaylar alınacak
    func fetchFavorites() async throws -> [NFTCollection] {
        guard let currentUser = Auth.auth().currentUser else {
            logger.error("User not logged in")
            return []
        }
        
        do {
            let snapshot = try await userFavoritesCollection(userId: currentUser.uid).order(by: "added_at", descending: true).getDocuments()
            
            var favorites: [NFTCollection] = []
            
            for document in snapshot.documents {
                let data = document.data()
                let id = data["id"] as? String ?? ""
                let name = data["name"] as? String ?? ""
                let contractAddress = data["contract_address"] as? String ?? ""
                let assetPlatformId = data["asset_platform_id"] as? String ?? ""
                let symbol = data["symbol"] as? String ?? ""
                
                // Temel NFTCollection modeli oluştur
                let collection = NFTCollection(
                    id: id,
                    contractAddress: contractAddress,
                    assetPlatformId: assetPlatformId,
                    name: name,
                    symbol: symbol
                )
                
                favorites.append(collection)
            }
            
            logger.info("Favorites fetched: \(favorites.count) collections")
            return favorites
        } catch {
            logger.error("Error fetching favorites: \(error.localizedDescription)")
            throw error
        }
    }
} 