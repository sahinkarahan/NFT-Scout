import Foundation
import OSLog
import Alamofire
import Kingfisher

@Observable
final class HomeTabViewModel {
    // Singleton instance ekle
    static let shared = HomeTabViewModel()
    
    private(set) var collections: [NFTCollection] = []
    private(set) var filteredCollections: [NFTCollection] = [] // Filtrelenmiş koleksiyonlar
    private(set) var error: Error?
    private(set) var isLoading = false
    private(set) var favoriteCollectionIds: Set<String> = []
    
    // Lazy loading için yeni değişkenler
    private(set) var currentPage = 1
    private(set) var isLoadingMoreData = false
    private(set) var hasMoreData = true
    private let pageSize = 35
    
    private let coinGeckoManager: CoinGeckoManager
    private let firestoreService: FirestoreService
    private let logger = Logger(subsystem: "com.application", category: "HomeTabViewModel")
    
    // Mevcut seçili zincir filtresi
    private var currentChainFilter: String = "All Chains"
    
    init(coinGeckoManager: CoinGeckoManager = .shared, firestoreService: FirestoreService = .shared) {
        self.coinGeckoManager = coinGeckoManager
        self.firestoreService = firestoreService
        logger.info("HomeTabViewModel initialized")
        
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
            if isFavorite {
                self.favoriteCollectionIds.insert(collectionId)
            } else {
                self.favoriteCollectionIds.remove(collectionId)
            }
            logger.info("Favorite status updated for collection: \(collectionId), isFavorite: \(isFavorite)")
            
            // Favori durumları değiştiğinde UI'ı güncellemeye zorla
            self.favoriteCollectionIds = self.favoriteCollectionIds
        }
    }
    
    // Zincir filtresine göre koleksiyonları filtrele
    @MainActor
    func filterCollectionsByChain(chain: String) {
        currentChainFilter = chain
        logger.info("Filtering collections by chain: \(chain)")
        
        if chain == "All Chains" {
            // Tüm koleksiyonları göster
            filteredCollections = collections
        } else {
            // Belirli bir zincire sahip koleksiyonları filtrele
            let chainSymbol = chainToSymbol(chain: chain)
            filteredCollections = collections.filter { collection in
                collection.nativeCurrencySymbol == chainSymbol
            }
        }
        
        logger.info("Filtered collections count: \(self.filteredCollections.count)")
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
    func fetchCollections(forceRefresh: Bool = false) async {
        if isLoading { return }
        
        isLoading = true
        error = nil
        
        // Eğer yenileme isteniyorsa, cache'i temizle
        if forceRefresh {
            // CoinGeckoManager'in cache'ini temizle (filtrelenen koleksiyonlar: synclub-s-snbnb-early-adopters, ordinal-maxi-biz-omb, runestone, chromie-squiggle-by-snowfro, bitcoin-puppets)
            coinGeckoManager.clearCache()
            // Mevcut sayfayı sıfırla
            currentPage = 1
            // Koleksiyonları temizle
            collections = []
            filteredCollections = []
            // Daha fazla veri olduğunu varsay
            hasMoreData = true
        }
        
        do {
            // Koleksiyonları çek
            let newCollections = try await coinGeckoManager.fetchNFTCollections(page: currentPage, pageSize: pageSize)
            
            // Koleksiyonları güncelle, maksimum 35 koleksiyon olacak şekilde
            collections = newCollections
            hasMoreData = newCollections.count == pageSize && collections.count < 35
            
            // Mevcut zincir filtresini uygula
            filterCollectionsByChain(chain: currentChainFilter)
            
            // Favori durumlarını yükle
            await loadFavoriteStates()
            
            // Detay bilgilerini yükle
            await loadInitialCollectionDetails()
        } catch {
            self.error = error
            print("Error fetching collections: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    @MainActor
    func loadMoreCollections() async {
        // Halihazırda yükleme yapılıyorsa veya tüm veriler yüklendiyse işlemi atla
        guard !isLoading && !isLoadingMoreData && hasMoreData else {
            return
        }
        
        // Toplam 35 koleksiyonu aşmayacağımızdan emin ol
        if collections.count >= 35 {
            hasMoreData = false
            logger.info("Maximum collection limit (35) reached. Not loading more data.")
            return
        }
        
        isLoadingMoreData = true
        currentPage += 1
        
        do {
            logger.info("Loading more collections - page \(self.currentPage)")
            let newCollections = try await coinGeckoManager.fetchNFTCollections(page: currentPage, pageSize: pageSize)
            
            // Yeni koleksiyonları mevcut listeye ekle
            if !newCollections.isEmpty {
                // Toplam 35 koleksiyonu aşmayacak şekilde ekle
                let remainingSlots = 35 - collections.count
                let collectionsToAdd = Array(newCollections.prefix(remainingSlots))
                collections.append(contentsOf: collectionsToAdd)
                
                // Toplam 35 koleksiyona ulaştık mı kontrol et
                hasMoreData = collections.count < 35 && newCollections.count == pageSize
                
                // Mevcut zincir filtresini uygula
                filterCollectionsByChain(chain: currentChainFilter)
            } else {
                // Yeni koleksiyon yoksa hasMoreData'yı false yap
                hasMoreData = false
            }
            
            // Yeni koleksiyonlar için favori durumunu yükle
            await loadFavoriteStatesForNewCollections(newCollections: newCollections)
            
            logger.info("Successfully loaded additional collections. Total: \(self.collections.count)/35")
        } catch {
            logger.error("Error loading more collections: \(error.localizedDescription)")
            self.error = error
            currentPage -= 1 // Hata durumunda sayfa numarasını geri al
        }
        
        isLoadingMoreData = false
    }
    
    @MainActor
    private func loadInitialCollectionDetails() async {
        // İlk sayfadaki koleksiyonlar için özet detayları yükle
        let initialCollections = collections.prefix(min(5, collections.count))
        
        for collection in initialCollections {
            if let index = collections.firstIndex(where: { $0.id == collection.id }) {
                do {
                    let detailedCollection = try await coinGeckoManager.fetchNFTCollectionDetails(id: collection.id)
                    collections[index] = detailedCollection
                    
                    // Filtrelenmiş koleksiyonları da güncelle
                    if let filteredIndex = filteredCollections.firstIndex(where: { $0.id == collection.id }) {
                        filteredCollections[filteredIndex] = detailedCollection
                    }
                } catch {
                    logger.error("Error loading initial collection details for \(collection.id): \(error.localizedDescription)")
                }
            }
        }
    }
    
    @MainActor
    func loadFavoriteStates() async {
        favoriteCollectionIds.removeAll()
        
        for collection in collections {
            do {
                let isFavorite = try await firestoreService.isFavorite(collectionId: collection.id)
                if isFavorite {
                    self.favoriteCollectionIds.insert(collection.id)
                }
            } catch {
                logger.error("Error checking favorite status: \(error.localizedDescription)")
            }
        }
        
        logger.info("Favorite collection count updated: \(self.favoriteCollectionIds.count)")
    }
    
    @MainActor
    private func loadFavoriteStatesForNewCollections(newCollections: [NFTCollection]) async {
        for collection in newCollections {
            do {
                let isFavorite = try await firestoreService.isFavorite(collectionId: collection.id)
                if isFavorite {
                    self.favoriteCollectionIds.insert(collection.id)
                }
            } catch {
                logger.error("Error checking favorite status for new collection: \(error.localizedDescription)")
            }
        }
    }
    
    @MainActor
    func toggleFavorite(collectionId: String) async {
        guard let collection = collections.first(where: { $0.id == collectionId }) else {
            logger.error("Collection not found: \(collectionId)")
            return
        }
        
        do {
            let wasFavorite = favoriteCollectionIds.contains(collectionId)
            
            if wasFavorite {
                // Favorileri kaldır
                try await firestoreService.removeFavorite(collectionId: collectionId)
                favoriteCollectionIds.remove(collectionId)
                logger.info("Collection removed from favorites: \(collectionId)")
                
                // Notification gönder
                NotificationCenter.default.post(
                    name: .favoriteStatusChanged,
                    object: nil,
                    userInfo: ["collectionId": collectionId, "isFavorite": false]
                )
            } else {
                // Favorilere ekle
                try await firestoreService.addFavorite(collectionId: collectionId, collection: collection)
                favoriteCollectionIds.insert(collectionId)
                logger.info("Collection added to favorites: \(collectionId)")
                
                // Notification gönder
                NotificationCenter.default.post(
                    name: .favoriteStatusChanged,
                    object: nil,
                    userInfo: ["collectionId": collectionId, "isFavorite": true]
                )
            }
            
            // UI'ı zorla güncelle (favoriteCollectionIds set'ini yeniden atayarak)
            let updatedFavorites = favoriteCollectionIds
            favoriteCollectionIds = updatedFavorites
        } catch {
            logger.error("Favorite operation error: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    @MainActor
    func isFavorite(collectionId: String) -> Bool {
        return favoriteCollectionIds.contains(collectionId)
    }
    
    func retry() {
        Task { [weak self] in
            guard let self = self else { return }
            await self.fetchCollections()
        }
    }
    
    // Koleksiyon detaylarını yükle
    @MainActor
    func loadCollectionDetails(for collectionId: String) async {
        guard let index = collections.firstIndex(where: { $0.id == collectionId }) else {
            logger.error("Collection not found for details: \(collectionId)")
            return
        }
        
        do {
            let detailedCollection = try await coinGeckoManager.fetchNFTCollectionDetails(id: collectionId)
            collections[index] = detailedCollection
            
            // Filtrelenmiş koleksiyonları da güncelle
            if let filteredIndex = filteredCollections.firstIndex(where: { $0.id == collectionId }) {
                filteredCollections[filteredIndex] = detailedCollection
            }
            
            logger.info("Updated collection details for: \(collectionId)")
        } catch {
            logger.error("Error loading collection details: \(error.localizedDescription)")
            // Hata durumunda UI'ı bozmamak için koleksiyonu silmiyoruz
        }
    }
    
    func loadCollections() async {
        isLoading = true
        
        do {
            // Koleksiyonları yükle...
            
            // İşlem tamamlandığında, tüm veriler hazır olduğunda loading durumunu false yap
            await MainActor.run {
                self.collections = collections
                self.filteredCollections = filteredCollections
                self.isLoading = false
            }
        } catch {
            // Hata işleme...
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
} 
