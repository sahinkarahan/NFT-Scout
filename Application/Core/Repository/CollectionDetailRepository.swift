import Foundation

// Combined collection detail from both CoinGecko and OpenSea sources
struct CombinedCollectionDetail {
    let coinGeckoData: NFTCollection
    var openSeaData: OpenSeaCollectionDetail?
    var openSeaNFTs: [OpenSeaNFT]?
    
    // Computed properties for commonly used combined data
    var name: String {
        return coinGeckoData.name
    }
    
    var description: String? {
        return openSeaData?.description ?? coinGeckoData.description
    }
    
    var bannerImage: String? {
        return coinGeckoData.bannerImage ?? openSeaData?.bannerImageUrl
    }
    
    var smallImage: String? {
        return openSeaData?.imageUrl ?? coinGeckoData.image?.small
    }
    
    var largeImage: String? {
        return openSeaData?.imageUrl ?? coinGeckoData.image?.small2x
    }
    
    var twitterUsername: String? {
        return openSeaData?.twitterUsername ?? coinGeckoData.links?.twitter
    }
    
    var discordUrl: String? {
        return openSeaData?.discordUrl ?? coinGeckoData.links?.discord
    }
    
    var websiteUrl: String? {
        return openSeaData?.projectUrl ?? coinGeckoData.links?.homepage
    }
    
    var totalSupply: Int? {
        return openSeaData?.totalSupply ?? coinGeckoData.totalSupply
    }
    
    var createdDate: String? {
        return openSeaData?.createdDate
    }
    
    // Market data still comes from CoinGecko
    var marketCap: PriceInfo? {
        return coinGeckoData.marketCap
    }
    
    var floorPrice: PriceInfo? {
        return coinGeckoData.floorPrice
    }
    
    var nativeCurrencySymbol: String? {
        return coinGeckoData.nativeCurrencySymbol
    }
    
    var displayableFloorPrice: String {
        return coinGeckoData.displayableFloorPrice
    }
    
    var userFavoritesCount: Int? {
        return coinGeckoData.userFavoritesCount
    }
}

protocol CollectionDetailRepositoryProtocol {
    func getCollectionDetail(id: String) async throws -> CombinedCollectionDetail
}

final class CollectionDetailRepository: CollectionDetailRepositoryProtocol {
    // MARK: - Dependencies
    
    private let coinGeckoService: CoinGeckoServiceProtocol
    private let openSeaService: OpenSeaServiceProtocol
    
    // MARK: - Initialization
    
    init(coinGeckoService: CoinGeckoServiceProtocol,
         openSeaService: OpenSeaServiceProtocol = OpenSeaService()) {
        self.coinGeckoService = coinGeckoService
        self.openSeaService = openSeaService
    }
    
    // MARK: - Public Methods
    
    func getCollectionDetail(id: String) async throws -> CombinedCollectionDetail {
        // First get the CoinGecko data which we know we have
        let coinGeckoCollection = try await getOrFetchCoinGeckoCollection(id: id)
        
        // Create a basic combined result with just CoinGecko data
        var combinedDetail = CombinedCollectionDetail(
            coinGeckoData: coinGeckoCollection,
            openSeaData: nil,
            openSeaNFTs: nil
        )
        
        // Try to fetch OpenSea data using the ID mapper - don't throw if this fails
        do {
            // Önce doğrudan ID'yi kullanmayı dene
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
    
    // MARK: - Private Methods
    
    private func getOrFetchCoinGeckoCollection(id: String) async throws -> NFTCollection {
        // Check if we already have this collection in HomeTabViewModel
        if let existingCollection = HomeTabViewModel.shared.collections.first(where: { $0.id == id }),
           existingCollection.marketCap != nil,
           existingCollection.floorPrice != nil {
            return existingCollection
        }
        
        // Otherwise fetch it directly
        return try await coinGeckoService.fetchNFTCollectionDetails(id: id)
    }
} 