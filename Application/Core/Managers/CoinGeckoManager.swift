import Foundation
import OSLog

@Observable
final class CoinGeckoManager {
    static let shared = CoinGeckoManager()
    
    private let service: CoinGeckoServiceProtocol
    private let logger = Logger(subsystem: "com.application", category: "CoinGeckoManager")
    
    private init() {
        let apiKey = "CG-9jxjVkLsiHWPBovzi59zGRsb"
        self.service = CoinGeckoService(apiKey: apiKey)
        logger.info("CoinGeckoManager initialized with API key")
    }
    
    init(service: CoinGeckoServiceProtocol = CoinGeckoService(apiKey: "CG-VK2yKvXyxpU8k2YjSXbPMtbx")) {
        self.service = service
        logger.info("CoinGeckoManager initialized")
    }
    
    // Cache temizleme
    func clearCache() {
        if let coinGeckoService = service as? CoinGeckoService {
            coinGeckoService.clearCache()
            logger.info("CoinGecko cache cleared")
        }
        print("CoinGeckoManager: Cache cleared - Filtrelenen koleksiyonlar: synclub-s-snbnb-early-adopters, ordinal-maxi-biz-omb, runestone, chromie-squiggle-by-snowfro, bitcoin-puppets")
    }
    
    func fetchNFTCollections(page: Int = 1, pageSize: Int = 50) async throws -> [NFTCollection] {
        logger.info("Fetching NFT collections page \(page)")
        do {
            let collections = try await service.fetchNFTCollections(page: page, pageSize: pageSize)
            logger.info("Successfully fetched \(collections.count) collections for page \(page)")
            return collections
        } catch {
            logger.error("Error fetching NFT collections: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchNFTCollectionDetails(id: String) async throws -> NFTCollection {
        logger.info("Fetching NFT collection details for: \(id)")
        do {
            let collection = try await service.fetchNFTCollectionDetails(id: id)
            logger.info("Successfully fetched details for collection \(id)")
            return collection
        } catch {
            logger.error("Error fetching NFT collection details: \(error.localizedDescription)")
            throw error
        }
    }
} 