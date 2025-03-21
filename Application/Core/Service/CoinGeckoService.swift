import Foundation
import Alamofire
import OSLog

protocol CoinGeckoServiceProtocol {
    func fetchNFTCollections(page: Int, pageSize: Int) async throws -> [NFTCollection]
    func fetchNFTCollectionDetails(id: String) async throws -> NFTCollection
}

final class CoinGeckoService: CoinGeckoServiceProtocol {
    private let baseURL = "https://api.coingecko.com/api/v3"
    private let apiKey: String
    private let cache = NSCache<NSString, CachedResponse>()
    private let logger = Logger(subsystem: "com.application", category: "CoinGeckoService")
    
    init(apiKey: String) {
        self.apiKey = apiKey
        cache.countLimit = 100 // Cache limiti
        logger.info("CoinGecko Service initialized with API key")
    }
    
    // Cache'i temizle
    func clearCache() {
        cache.removeAllObjects()
        print("CoinGeckoService cache cleared")
    }
    
    private var headers: HTTPHeaders {
        [
            "x-cg-demo-api-key": apiKey,
            "accept": "application/json"
        ]
    }
    
    // Cache için yardımcı sınıf
    private class CachedResponse {
        let data: Any
        let timestamp: Date
        
        init(data: Any) {
            self.data = data
            self.timestamp = Date()
        }
        
        var isValid: Bool {
            return Date().timeIntervalSince(timestamp) < 180 // 3 dakika cache süresi
        }
    }
    
    func fetchNFTCollections(page: Int = 1, pageSize: Int = 50) async throws -> [NFTCollection] {
        // Sadece ilk sayfa için önbelleği kullan, diğer sayfalar için her zaman yeni veri çek
        let cacheKey = "nft_collections_list_page\(page)_size\(pageSize)" as NSString
        if page == 1, let cached = cache.object(forKey: cacheKey), cached.isValid {
            logger.info("Using cached NFT collections list for page \(page)")
            // Önbellekten gelen verilerde de "synclub-s-snbnb-early-adopters" ve diğer ID'li koleksiyonları filtrele
            let cachedCollections = cached.data as! [NFTCollection]
            let filteredCachedCollections = cachedCollections.filter { collection in
                !["synclub-s-snbnb-early-adopters", "ordinal-maxi-biz-omb", "runestone", "chromie-squiggle-by-snowfro", "bitcoin-puppets"].contains(collection.id)
            }
            return filteredCachedCollections
        }
        
        let endpoint = "\(baseURL)/nfts/list"
        var components = URLComponents(string: endpoint)!
        
        // Query parametreleri (sayfalama parametrelerini ekle)
        // Belirtilen koleksiyonları hariç tutmak için pageSize'ı artır (4 ekstra koleksiyon çıkaracağımız için +5)
        let adjustedPageSize = pageSize + 5
        components.queryItems = [
            URLQueryItem(name: "order", value: "market_cap_usd_desc"),
            URLQueryItem(name: "per_page", value: "\(adjustedPageSize)"),
            URLQueryItem(name: "page", value: "\(page)")
        ]
        
        guard let url = components.url else {
            logger.error("Invalid URL for NFT collections")
            throw CoinGeckoError.invalidURL
        }
        
        logger.info("Fetching NFT collections from CoinGecko API - page \(page)")
        logger.debug("Request URL: \(url.absoluteString)")
        
        do {
            let request = AF.request(url,
                                    method: .get,
                                    headers: headers)
            
            let allCollections = try await request
                .validate()
                .serializingDecodable([NFTCollection].self)
                .value
            
            // İstenmeyen koleksiyonları filtrele
            let filteredCollections = allCollections.filter { collection in
                !["synclub-s-snbnb-early-adopters", "ordinal-maxi-biz-omb", "runestone", "chromie-squiggle-by-snowfro", "bitcoin-puppets"].contains(collection.id)
            }
            
            // Orijinal pageSize'a göre ilk x öğeyi al
            let limitedCollections = Array(filteredCollections.prefix(pageSize))
            
            // Enhance collections with additional details
            let enhancedCollections = try await enhanceCollectionsWithDetails(collections: limitedCollections)
            
            // Sadece ilk sayfa için önbelleğe al, böylece ilk yükleme hızlı olur
            if page == 1 {
                cache.setObject(CachedResponse(data: enhancedCollections), forKey: cacheKey)
            }
            
            logger.info("Successfully fetched \(enhancedCollections.count) NFT collections for page \(page)")
            return enhancedCollections
        } catch {
            logger.error("Error fetching NFT collections for page \(page): \(error.localizedDescription)")
            throw handleError(error)
        }
    }
    
    func fetchNFTCollectionDetails(id: String) async throws -> NFTCollection {
        // Cache kontrolü
        let cacheKey = "nft_collection_\(id)" as NSString
        if let cached = cache.object(forKey: cacheKey), cached.isValid {
            logger.info("Using cached NFT collection details for \(id)")
            return cached.data as! NFTCollection
        }
        
        let endpoint = "\(baseURL)/nfts/\(id)"
        
        guard let url = URL(string: endpoint) else {
            logger.error("Invalid URL for NFT collection details")
            throw CoinGeckoError.invalidURL
        }
        
        logger.info("Fetching NFT collection details for \(id)")
        logger.debug("Request URL: \(url.absoluteString)")
        
        do {
            let request = AF.request(url,
                                    method: .get,
                                    headers: headers)
            
            let collection = try await request
                .validate()
                .serializingDecodable(NFTCollection.self)
                .value
            
            // Cache the result
            cache.setObject(CachedResponse(data: collection), forKey: cacheKey)
            
            logger.info("Successfully fetched details for NFT collection: \(collection.name)")
            return collection
        } catch {
            logger.error("Error fetching NFT collection details: \(error.localizedDescription)")
            throw handleError(error)
        }
    }
    
    // Tüm koleksiyonlar için detay bilgilerini asenkron olarak almak yerine,
    // koleksiyonları temel bilgilerle döndürür, UI'da gösterildikçe detaylar yüklenir
    private func enhanceCollectionsWithDetails(collections: [NFTCollection]) async throws -> [NFTCollection] {
        // Basit koleksiyonları döndür, detaylar sonradan yüklenecek
        return collections
    }
    
    // Hata işleme helper metodu
    private func handleError(_ error: Error) -> CoinGeckoError {
        if let afError = error.asAFError {
            if let responseCode = afError.responseCode {
                switch responseCode {
                case 401:
                    return .unauthorized
                case 429:
                    return .rateLimited
                case 400...499:
                    return .serverError(responseCode, "Client error")
                case 500...599:
                    return .serverError(responseCode, "Server error")
                default:
                    return .unknown(afError.localizedDescription)
                }
            }
            
            return .networkError(afError.localizedDescription)
        }
        
        if let decodingError = error as? DecodingError {
            return .decodingError(decodingError.localizedDescription)
        }
        
        return .unknown(error.localizedDescription)
    }
} 
