import Foundation
import OSLog

@Observable
final class FavoritesViewModel {
    private(set) var favoriteCollections: [NFTCollection] = []
    private(set) var filteredFavoriteCollections: [NFTCollection] = [] // Filtrelenmiş koleksiyonlar
    private(set) var isLoading = false
    private(set) var error: Error?
    
    private let coinGeckoManager: CoinGeckoManager
    private let firestoreService: FirestoreService
    private let logger = Logger(subsystem: "com.application", category: "FavoritesViewModel")
    
    // Mevcut seçili zincir filtresi
    private var currentChainFilter: String = "All Chains"
    
    init(coinGeckoManager: CoinGeckoManager = .shared, firestoreService: FirestoreService = .shared) {
        self.coinGeckoManager = coinGeckoManager
        self.firestoreService = firestoreService
        logger.info("FavoritesViewModel initialized")
        
        // Favori değişiklik bildirimlerini dinle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFavoriteStatusChanged),
            name: .favoriteStatusChanged,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleFavoriteStatusChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let collectionId = userInfo["collectionId"] as? String,
              let isFavorite = userInfo["isFavorite"] as? Bool else {
            return
        }
        
        Task { @MainActor in
            if !isFavorite {
                // Favorilerden kaldırıldıysa, listeden çıkar
                favoriteCollections.removeAll { $0.id == collectionId }
                // Filtrelenmiş listeyi de güncelle
                filterCollectionsByChain(chain: currentChainFilter)
                logger.info("Collection removed from favorites view: \(collectionId)")
            } else {
                // Favorilere eklendiyse, listeyi yeniden yükle
                await loadFavorites()
            }
        }
    }
    
    // Zincir filtresine göre koleksiyonları filtrele
    @MainActor
    func filterCollectionsByChain(chain: String) {
        currentChainFilter = chain
        logger.info("Filtering favorite collections by chain: \(chain)")
        
        if chain == "All Chains" {
            // Tüm koleksiyonları göster
            filteredFavoriteCollections = favoriteCollections
        } else {
            // Belirli bir zincire sahip koleksiyonları filtrele
            let chainSymbol = chainToSymbol(chain: chain)
            filteredFavoriteCollections = favoriteCollections.filter { collection in
                collection.nativeCurrencySymbol == chainSymbol
            }
        }
        
        logger.info("Filtered favorite collections count: \(self.filteredFavoriteCollections.count)")
    }
    
    // Zincir adından sembol elde et
    private func chainToSymbol(chain: String) -> String {
        switch chain {
        case "Ethereum":
            return "ETH"
        case "Solana":
            return "SOL"
        case "Bitcoin":
            return "BTC"
        case "BNB Smart Chain":
            return "BNB"
        default:
            return ""
        }
    }
    
    @MainActor
    func loadFavorites() async {
        isLoading = true
        error = nil
        
        do {
            logger.info("Loading favorite collections")
            
            // Favori koleksiyon ID'lerini al
            let favoriteIds = try await firestoreService.getFavoriteCollectionIds()
            
            if favoriteIds.isEmpty {
                favoriteCollections = []
                filteredFavoriteCollections = []
                isLoading = false
                return
            }
            
            // Her bir favori koleksiyon için detayları yükle
            var collections: [NFTCollection] = []
            
            for id in favoriteIds {
                do {
                    let collection = try await coinGeckoManager.fetchNFTCollectionDetails(id: id)
                    collections.append(collection)
                } catch {
                    logger.error("Error loading collection details for \(id): \(error.localizedDescription)")
                    // Hata durumunda diğer koleksiyonları yüklemeye devam et
                }
            }
            
            favoriteCollections = collections
            
            // Zincir filtresini uygula
            filterCollectionsByChain(chain: currentChainFilter)
            
            logger.info("Loaded \(collections.count) favorite collections")
        } catch {
            logger.error("Error loading favorites: \(error.localizedDescription)")
            self.error = error
        }
        
        isLoading = false
    }
    
    @MainActor
    func removeFavorite(collectionId: String) async {
        do {
            try await firestoreService.removeFavorite(collectionId: collectionId)
            
            // Koleksiyonu listeden kaldır
            favoriteCollections.removeAll { $0.id == collectionId }
            
            // Filtrelenmiş listeyi güncelle
            filterCollectionsByChain(chain: currentChainFilter)
            
            // Notification gönder
            NotificationCenter.default.post(
                name: .favoriteStatusChanged,
                object: nil,
                userInfo: ["collectionId": collectionId, "isFavorite": false]
            )
            
            logger.info("Collection removed from favorites: \(collectionId)")
        } catch {
            logger.error("Error removing favorite: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    @MainActor
    func loadCollectionDetails(for collectionId: String) async {
        guard let index = favoriteCollections.firstIndex(where: { $0.id == collectionId }) else {
            logger.error("Collection not found for details: \(collectionId)")
            return
        }
        
        do {
            let detailedCollection = try await coinGeckoManager.fetchNFTCollectionDetails(id: collectionId)
            favoriteCollections[index] = detailedCollection
            
            // Filtrelenmiş koleksiyonları da güncelle
            if let filteredIndex = filteredFavoriteCollections.firstIndex(where: { $0.id == collectionId }) {
                filteredFavoriteCollections[filteredIndex] = detailedCollection
            }
            
            logger.info("Updated collection details for: \(collectionId)")
        } catch {
            logger.error("Error loading collection details: \(error.localizedDescription)")
            // Hata durumunda UI'ı bozmamak için koleksiyonu silmiyoruz
        }
    }
} 
