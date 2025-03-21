import Foundation

struct NFTCollection: Identifiable, Codable {
    let id: String
    let contractAddress: String
    let assetPlatformId: String
    let name: String
    let symbol: String
    
    // Detailed info - will be populated from detailed fetch
    var image: NFTImage?
    var bannerImage: String?
    var description: String?
    var nativeCurrency: String?
    var nativeCurrencySymbol: String?
    var marketCapRank: Int?
    var floorPrice: PriceInfo?
    var marketCap: PriceInfo?
    var volume24h: PriceInfo?
    var floorPriceIn24hPercentageChange: Double?
    var floorPrice24hPercentageChange: PercentageChange?
    var marketCap24hPercentageChange: PercentageChange?
    var volume24hPercentageChange: PercentageChange?
    var numberOfUniqueAddresses: Int?
    var totalSupply: Int?
    var links: NFTLinks?
    var athChangePercentage: PercentageChange?
    var userFavoritesCount: Int?
    
    // Computed properties
    var ownerCount: Int { numberOfUniqueAddresses ?? 0 }
    var totalNFTs: Int { totalSupply ?? 0 }
    var rank: Int { marketCapRank ?? 0 }
    
    // For displaying in UI
    var displayableMarketCap: String {
        guard let value = marketCap?.nativeCurrency else { return "N/A" }
        return formatNumber(value)
    }
    
    var displayableFloorPrice: String {
        guard let value = floorPrice?.nativeCurrency else { return "N/A" }
        return String(format: "%.2f", value)
    }
    
    var displayablePercentageChange: String {
        guard let value = athChangePercentage?.nativeCurrency else { return "0%" }
        let formattedValue = String(format: "%.2f", abs(value))
        return value >= 0 ? "+\(formattedValue)%" : "-\(formattedValue)%"
    }
    
    var percentageChangeColor: Bool {
        return athChangePercentage?.nativeCurrency ?? 0 >= 0
    }

    // Helper function to format large numbers
    private func formatNumber(_ number: Double) -> String {
        let billion = 1_000_000_000.0
        let million = 1_000_000.0
        let thousand = 1_000.0
        
        if number >= billion {
            return String(format: "%.2fB", number / billion)
        } else if number >= million {
            return String(format: "%.2fM", number / million)
        } else if number >= thousand {
            return String(format: "%.2fK", number / thousand)
        } else {
            return String(format: "%.2f", number)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case contractAddress = "contract_address"
        case assetPlatformId = "asset_platform_id"
        case name
        case symbol
        case image
        case bannerImage = "banner_image"
        case description
        case nativeCurrency = "native_currency"
        case nativeCurrencySymbol = "native_currency_symbol"
        case marketCapRank = "market_cap_rank"
        case floorPrice = "floor_price"
        case marketCap = "market_cap"
        case volume24h = "volume_24h"
        case floorPriceIn24hPercentageChange = "floor_price_in_usd_24h_percentage_change"
        case floorPrice24hPercentageChange = "floor_price_24h_percentage_change"
        case marketCap24hPercentageChange = "market_cap_24h_percentage_change"
        case volume24hPercentageChange = "volume_24h_percentage_change"
        case numberOfUniqueAddresses = "number_of_unique_addresses"
        case totalSupply = "total_supply"
        case links
        case athChangePercentage = "ath_change_percentage"
        case userFavoritesCount = "user_favorites_count"
    }
}

struct NFTImage: Codable {
    let small: String
    let small2x: String
    
    enum CodingKeys: String, CodingKey {
        case small
        case small2x = "small_2x"
    }
}

struct PriceInfo: Codable {
    let nativeCurrency: Double
    let usd: Double
    
    enum CodingKeys: String, CodingKey {
        case nativeCurrency = "native_currency"
        case usd
    }
}

struct PercentageChange: Codable {
    let usd: Double
    let nativeCurrency: Double
    
    enum CodingKeys: String, CodingKey {
        case usd
        case nativeCurrency = "native_currency"
    }
}

struct NFTLinks: Codable {
    let homepage: String?
    let twitter: String?
    let discord: String?
    
    enum CodingKeys: String, CodingKey {
        case homepage
        case twitter
        case discord
    }
}

// CoinGecko API'den gelen listeleme yanıtı
struct NFTCollectionListResponse: Codable {
    let collections: [NFTCollection]
    
    // API doğrudan bir dizi döndürdüğü için özel bir init
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        collections = try container.decode([NFTCollection].self)
    }
}

// MARK: - CoinGecko NFT Asset Models

struct NFTAsset: Identifiable, Codable {
    let id: String
    let name: String?
    let tokenId: String
    let contractAddress: String
    let imageUrl: String?
    let description: String?
    let collectionName: String
    let collectionId: String
    let attributes: [NFTAttribute]?
    
    // CoinGecko permalink
    var permalink: String {
        "https://www.coingecko.com/nft/\(collectionId)/\(tokenId)"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case tokenId = "token_id"
        case contractAddress = "contract_address"
        case imageUrl = "image_url"
        case description
        case collectionName = "collection_name"
        case collectionId = "collection_id"
        case attributes
    }
}

struct NFTAttribute: Codable {
    let traitType: String
    let value: String
    let displayType: String?
    
    enum CodingKeys: String, CodingKey {
        case traitType = "trait_type"
        case value
        case displayType = "display_type"
    }
}

// CoinGecko NFT Asset arama yanıtı
struct NFTAssetSearchResponse: Codable {
    let assets: [NFTAsset]
    let total: Int
    
    enum CodingKeys: String, CodingKey {
        case assets
        case total
    }
} 