import Foundation

// MARK: - Collections Response

struct OpenSeaCollectionsResponse: Codable {
    let collections: [OpenSeaCollectionBase]
}

struct OpenSeaCollectionBase: Codable {
    let collection: String // This is the slug - will match with CoinGecko's id
    let name: String
    let description: String?
    let imageUrl: String?
    let bannerImageUrl: String?
    let owner: String?
    let safelistStatus: String?
    let category: String?
    let isDisabled: Bool?
    let isNsfw: Bool?
    let traitOffersEnabled: Bool?
    let collectionOffersEnabled: Bool?
    let openseaUrl: String?
    let projectUrl: String?
    let wikiUrl: String?
    let discordUrl: String?
    let telegramUrl: String?
    let twitterUsername: String?
    let instagramUsername: String?
    let contracts: [OpenSeaContract]?
    
    enum CodingKeys: String, CodingKey {
        case collection, name, description, owner, category
        case imageUrl = "image_url"
        case bannerImageUrl = "banner_image_url"
        case safelistStatus = "safelist_status"
        case isDisabled = "is_disabled"
        case isNsfw = "is_nsfw"
        case traitOffersEnabled = "trait_offers_enabled"
        case collectionOffersEnabled = "collection_offers_enabled"
        case openseaUrl = "opensea_url"
        case projectUrl = "project_url"
        case wikiUrl = "wiki_url"
        case discordUrl = "discord_url"
        case telegramUrl = "telegram_url"
        case twitterUsername = "twitter_username"
        case instagramUsername = "instagram_username"
        case contracts
    }
}

// MARK: - Collection Detail Response

struct OpenSeaCollectionDetail: Codable {
    let collection: String
    let name: String
    let description: String?
    let imageUrl: String?
    let bannerImageUrl: String?
    let owner: String?
    let safelistStatus: String?
    let category: String?
    let isDisabled: Bool?
    let isNsfw: Bool?
    let traitOffersEnabled: Bool?
    let collectionOffersEnabled: Bool?
    let openseaUrl: String?
    let projectUrl: String?
    let wikiUrl: String?
    let discordUrl: String?
    let telegramUrl: String?
    let twitterUsername: String?
    let instagramUsername: String?
    let contracts: [OpenSeaContract]?
    let editors: [String]?
    let fees: [OpenSeaFee]?
    let paymentTokens: [OpenSeaPaymentToken]?
    let totalSupply: Int?
    let createdDate: String?
    
    enum CodingKeys: String, CodingKey {
        case collection, name, description, owner, category, editors, fees, contracts
        case imageUrl = "image_url"
        case bannerImageUrl = "banner_image_url"
        case safelistStatus = "safelist_status"
        case isDisabled = "is_disabled"
        case isNsfw = "is_nsfw"
        case traitOffersEnabled = "trait_offers_enabled"
        case collectionOffersEnabled = "collection_offers_enabled"
        case openseaUrl = "opensea_url"
        case projectUrl = "project_url"
        case wikiUrl = "wiki_url"
        case discordUrl = "discord_url"
        case telegramUrl = "telegram_url"
        case twitterUsername = "twitter_username"
        case instagramUsername = "instagram_username"
        case paymentTokens = "payment_tokens"
        case totalSupply = "total_supply"
        case createdDate = "created_date"
    }
}

struct OpenSeaContract: Codable {
    let address: String
    let chain: String
}

struct OpenSeaFee: Codable {
    let fee: Double
    let recipient: String
    let required: Bool?
}

struct OpenSeaPaymentToken: Codable {
    let symbol: String
    let address: String
    let chain: String
    let image: String?
    let name: String?
    let decimals: Int?
    let ethPrice: String?
    let usdPrice: String?
    
    enum CodingKeys: String, CodingKey {
        case symbol, address, chain, image, name, decimals
        case ethPrice = "eth_price"
        case usdPrice = "usd_price"
    }
}

// MARK: - NFT Price Response

struct NFTPriceResponse: Codable {
    let orderHash: String
    let chain: String
    let price: NFTPrice
    
    enum CodingKeys: String, CodingKey {
        case orderHash = "order_hash"
        case chain
        case price
    }
}

struct NFTPrice: Codable {
    let currency: String
    let decimals: Int
    let value: String
    
    // Ondalıklı fiyat değerini hesaplayan yardımcı fonksiyon
    func calculatedPrice() -> Double {
        guard let valueNum = Double(value) else { return 0 }
        return valueNum / pow(10, Double(decimals))
    }
    
    // Fiyatı formatlanmış olarak döndüren yardımcı fonksiyon
    func formattedPrice() -> String {
        let price = calculatedPrice()
        return String(format: "%.2f \(currency)", price)
    }
}

// MARK: - NFTs Response

struct OpenSeaNFTsResponse: Codable {
    let nfts: [OpenSeaNFT]
    let next: String?
    
    enum CodingKeys: String, CodingKey {
        case nfts
        case next
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nfts = try container.decode([OpenSeaNFT].self, forKey: .nfts)
        next = try container.decodeIfPresent(String.self, forKey: .next)
    }
}

struct OpenSeaNFT: Codable {
    let identifier: String
    let collection: String
    let contract: String
    let tokenStandard: String?
    let name: String?
    let description: String?
    let imageUrl: String?
    let displayImageUrl: String?
    let displayAnimationUrl: String?
    let metadataUrl: String?
    let openseaUrl: String?
    let updatedAt: String?
    let isDisabled: Bool?
    let isNsfw: Bool?
    var price: NFTPrice? // NFT'nin fiyat bilgisi
    
    enum CodingKeys: String, CodingKey {
        case identifier, collection, contract, name, description
        case tokenStandard = "token_standard"
        case imageUrl = "image_url"
        case displayImageUrl = "display_image_url"
        case displayAnimationUrl = "display_animation_url"
        case metadataUrl = "metadata_url"
        case openseaUrl = "opensea_url"
        case updatedAt = "updated_at"
        case isDisabled = "is_disabled"
        case isNsfw = "is_nsfw"
        case price
    }
    
    // JSON'dan oluşturucu için özel kodlanabilir yapıcı
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        identifier = try container.decode(String.self, forKey: .identifier)
        collection = try container.decode(String.self, forKey: .collection)
        contract = try container.decode(String.self, forKey: .contract)
        tokenStandard = try container.decodeIfPresent(String.self, forKey: .tokenStandard)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        displayImageUrl = try container.decodeIfPresent(String.self, forKey: .displayImageUrl)
        displayAnimationUrl = try container.decodeIfPresent(String.self, forKey: .displayAnimationUrl)
        metadataUrl = try container.decodeIfPresent(String.self, forKey: .metadataUrl)
        openseaUrl = try container.decodeIfPresent(String.self, forKey: .openseaUrl)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        isDisabled = try container.decodeIfPresent(Bool.self, forKey: .isDisabled)
        isNsfw = try container.decodeIfPresent(Bool.self, forKey: .isNsfw)
        price = try container.decodeIfPresent(NFTPrice.self, forKey: .price)
    }
    
    // Özel init oluşturucu
    init(identifier: String, collection: String, contract: String, tokenStandard: String?, name: String?,
         description: String?, imageUrl: String?, displayImageUrl: String?, displayAnimationUrl: String?,
         metadataUrl: String?, openseaUrl: String?, updatedAt: String?, isDisabled: Bool?, isNsfw: Bool?,
         price: NFTPrice? = nil) {
        self.identifier = identifier
        self.collection = collection
        self.contract = contract
        self.tokenStandard = tokenStandard
        self.name = name
        self.description = description
        self.imageUrl = imageUrl
        self.displayImageUrl = displayImageUrl
        self.displayAnimationUrl = displayAnimationUrl
        self.metadataUrl = metadataUrl
        self.openseaUrl = openseaUrl
        self.updatedAt = updatedAt
        self.isDisabled = isDisabled
        self.isNsfw = isNsfw
        self.price = price
    }
} 