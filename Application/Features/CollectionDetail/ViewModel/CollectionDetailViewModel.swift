import Foundation
import SwiftUI

@Observable
final class CollectionDetailViewModel {
    // MARK: - Properties
    
    private(set) var collectionDetail: CombinedCollectionDetail?
    private(set) var isLoading = false
    private(set) var error: Error?
    private(set) var nfts: [OpenSeaNFT] = []
    
    private let repository: CollectionDetailRepositoryProtocol
    private let coinGeckoManager: CoinGeckoManager
    private let openSeaService: OpenSeaServiceProtocol
    
    // MARK: - Initialization
    
    init(initialCollection: NFTCollection, 
         coinGeckoManager: CoinGeckoManager = .shared,
         openSeaService: OpenSeaServiceProtocol = OpenSeaService()) {
        self.collectionDetail = CombinedCollectionDetail(
            coinGeckoData: initialCollection,
            openSeaData: nil,
            openSeaNFTs: nil
        )
        
        self.coinGeckoManager = coinGeckoManager
        self.openSeaService = openSeaService
        
        // Özel repository oluştur
        self.repository = CustomCollectionDetailRepository(
            coinGeckoManager: coinGeckoManager,
            openSeaService: openSeaService
        )
    }
    
    // MARK: - Actions
    
    func loadCollectionDetails() async {
        guard let id = collectionDetail?.coinGeckoData.id else { return }
        
        isLoading = true
        error = nil
        
        do {
            // 1. Koleksiyon detaylarını yükle
            let detailedCollection = try await repository.getCollectionDetail(id: id)
            collectionDetail = detailedCollection
            
            // 2. NFT'leri yükle (aynı zamanda)
            nfts = await loadNFTsForCollection(id: id)
            
        } catch {
            self.error = error
            print("Failed to load collection details: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - NFT Yükleme İşlemi
    
    private func loadNFTsForCollection(id: String) async -> [OpenSeaNFT] {
        let slug = id.toOpenSeaSlug()
        let targetCount = 20 // Hedeflenen NFT sayısı
        var allNFTs: [OpenSeaNFT] = []
        var nextCursor: String? = nil
        var hasMore = true
        
        do {
            // İlk yükleme - daha büyük bir sayı ile başlayalım
            let initialResult = try await NFTGridView.fetchNFTsForCollection(collectionSlug: slug, limit: targetCount * 2)
            allNFTs = initialResult.nfts
            nextCursor = initialResult.nextCursor
            hasMore = nextCursor != nil
            
            // Fiyat bilgilerini yükle ve güncellenen NFT'leri al
            allNFTs = await loadNFTPrices(for: allNFTs, collectionSlug: slug)
            
            // Eğer görüntüsü olan NFT sayısı hedef sayının altındaysa daha fazla yükle
            while filteredCount(nfts: allNFTs) < targetCount && hasMore {
                // Daha fazla NFT yükle
                let result = try await NFTGridView.fetchNFTsForCollection(
                    collectionSlug: slug,
                    limit: targetCount * 2,
                    cursor: nextCursor
                )
                
                var newNFTs = result.nfts
                // Yeni NFT'lerin fiyat bilgilerini yükle
                newNFTs = await loadNFTPrices(for: newNFTs, collectionSlug: slug)
                
                allNFTs.append(contentsOf: newNFTs)
                nextCursor = result.nextCursor
                hasMore = nextCursor != nil
                
                // Çok hızlı istek göndermemek için kısa bir bekleme
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 saniye
            }
            
            // Filtreleme işlemini uygula
            return filterValidNFTs(allNFTs, limit: targetCount)
            
        } catch {
            print("NFT'ler yüklenirken hata: \(error)")
            return []
        }
    }
    
    private func loadNFTPrices(for inputNfts: [OpenSeaNFT], collectionSlug: String) async -> [OpenSeaNFT] {
        // Create a mutable copy of the input
        var updatedNfts = inputNfts
        
        await withTaskGroup(of: (String, NFTPrice?).self) { group in
            for nft in inputNfts {
                group.addTask {
                    do {
                        let price = try await NFTGridView.fetchPriceForNFT(collectionSlug: collectionSlug, identifier: nft.identifier)
                        return (nft.identifier, price)
                    } catch {
                        print("NFT ID \(nft.identifier) için fiyat bilgisi alınamadı: \(error)")
                        return (nft.identifier, nil)
                    }
                }
            }
            
            for await (identifier, price) in group {
                if let index = updatedNfts.firstIndex(where: { $0.identifier == identifier }), let price = price {
                    updatedNfts[index].price = price
                }
            }
        }
        
        // Also update the class property for consistency
        self.nfts = updatedNfts
        
        return updatedNfts
    }
    
    private func filteredCount(nfts: [OpenSeaNFT]) -> Int {
        return nfts.filter { $0.displayImageUrl != nil || $0.imageUrl != nil }.count
    }
    
    private func filterValidNFTs(_ nfts: [OpenSeaNFT], limit: Int) -> [OpenSeaNFT] {
        return Array(nfts.filter { $0.displayImageUrl != nil || $0.imageUrl != nil }.prefix(limit))
    }
    
    // MARK: - Helper Methods
    
    var hasOpenSeaData: Bool {
        return collectionDetail?.openSeaData != nil
    }
    
    var hasNFTs: Bool {
        return collectionDetail?.openSeaNFTs?.isEmpty == false
    }
    
    var formattedCreationDate: String? {
        guard let dateString = collectionDetail?.createdDate else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = dateFormatter.date(from: dateString) else { return dateString }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM yyyy"
        displayFormatter.locale = Locale(identifier: "en_US")
        
        return displayFormatter.string(from: date)
    }
    
    var socialLinks: [(icon: String, url: String)] {
        var links: [(icon: String, url: String)] = []
        
        if let websiteUrl = collectionDetail?.websiteUrl, !websiteUrl.isEmpty {
            links.append((icon: "globe", url: websiteUrl))
        }
        
        if let twitterUsername = collectionDetail?.twitterUsername, !twitterUsername.isEmpty {
            links.append((icon: "twitter", url: "https://twitter.com/\(twitterUsername)"))
        }
        
        if let discordUrl = collectionDetail?.discordUrl, !discordUrl.isEmpty {
            links.append((icon: "discord", url: discordUrl))
        }
        
        if let openseaUrl = collectionDetail?.openSeaData?.openseaUrl, !openseaUrl.isEmpty {
            links.append((icon: "link", url: openseaUrl))
        }
        
        return links
    }
}

// Özel repository implementasyonu - CoinGeckoService yerine CoinGeckoManager kullanır
final class CustomCollectionDetailRepository: CollectionDetailRepositoryProtocol {
    private let coinGeckoManager: CoinGeckoManager
    private let openSeaService: OpenSeaServiceProtocol
    
    init(coinGeckoManager: CoinGeckoManager, openSeaService: OpenSeaServiceProtocol) {
        self.coinGeckoManager = coinGeckoManager
        self.openSeaService = openSeaService
    }
    
    func getCollectionDetail(id: String) async throws -> CombinedCollectionDetail {
        // First get the CoinGecko data which we know we have
        let coinGeckoCollection = try await getOrFetchCoinGeckoCollection(id: id)
        
        // Create a basic combined result with just CoinGecko data
        var combinedDetail = CombinedCollectionDetail(
            coinGeckoData: coinGeckoCollection,
            openSeaData: nil,
            openSeaNFTs: nil
        )
        
        // Try to fetch OpenSea data - don't throw if this fails
        do {
            // CoinGecko ID'sini OpenSea slug'ına dönüştürerek OpenSea verilerini al
            let openSeaDetail = try await openSeaService.fetchCollectionDetailsByCoinGeckoID(id: id)
            combinedDetail.openSeaData = openSeaDetail
            
            // Now that we have collection data, try to fetch some NFTs
            let nftsResponse = try await openSeaService.fetchCollectionNFTsByCoinGeckoID(id: id, limit: 10)
            combinedDetail.openSeaNFTs = nftsResponse.nfts
            
            print("✅ OpenSea verisi başarıyla alındı: [\(id)] koleksiyonu için. Slug: [\(id.toOpenSeaSlug())]")
        } catch {
            print("❌ OpenSea veri alımı başarısız: [\(id)] için hata: \(error)")
            // Continue even if OpenSea data fails - we still have CoinGecko data
        }
        
        return combinedDetail
    }
    
    private func getOrFetchCoinGeckoCollection(id: String) async throws -> NFTCollection {
        // Check if we already have this collection in HomeTabViewModel
        if let existingCollection = HomeTabViewModel.shared.collections.first(where: { $0.id == id }),
           existingCollection.marketCap != nil,
           existingCollection.floorPrice != nil {
            return existingCollection
        }
        
        // Otherwise fetch it directly
        return try await coinGeckoManager.fetchNFTCollectionDetails(id: id)
    }
} 