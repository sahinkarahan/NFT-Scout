import Foundation
import Alamofire

protocol OpenSeaServiceProtocol {
    func fetchCollections() async throws -> OpenSeaCollectionsResponse
    func fetchCollectionDetails(slug: String) async throws -> OpenSeaCollectionDetail
    func fetchCollectionNFTs(slug: String, limit: Int) async throws -> OpenSeaNFTsResponse
    
    // Yeni metodlar
    func fetchCollectionDetailsByCoinGeckoID(id: String) async throws -> OpenSeaCollectionDetail
    func fetchCollectionNFTsByCoinGeckoID(id: String, limit: Int) async throws -> OpenSeaNFTsResponse
}

final class OpenSeaService: OpenSeaServiceProtocol {
    // MARK: - Properties
    
    private let baseURL = "https://api.opensea.io/api/v2"
    private let apiKey = "API-KEY"
    
    // MARK: - Public Methods
    
    /// Fetches a list of NFT collections from OpenSea
    func fetchCollections() async throws -> OpenSeaCollectionsResponse {
        let endpoint = "\(baseURL)/collections"
        
        var components = URLComponents(string: endpoint)!
        components.queryItems = [
            URLQueryItem(name: "order_by", value: "market_cap")
        ]
        
        let request = createRequest(url: components.url!)
        
        do {
            let dataTask = AF.request(request)
                .validate()
                .serializingDecodable(OpenSeaCollectionsResponse.self)
            
            return try await dataTask.value
        } catch {
            print("Error fetching OpenSea collections: \(error)")
            throw error
        }
    }
    
    /// Fetches details for a specific collection by slug
    func fetchCollectionDetails(slug: String) async throws -> OpenSeaCollectionDetail {
        let endpoint = "\(baseURL)/collections/\(slug)"
        let request = createRequest(url: URL(string: endpoint)!)
        
        do {
            let dataTask = AF.request(request)
                .validate()
                .serializingDecodable(OpenSeaCollectionDetail.self)
            
            return try await dataTask.value
        } catch {
            print("Error fetching OpenSea collection details: \(error)")
            throw error
        }
    }
    
    /// Fetches NFTs for a specific collection by slug
    func fetchCollectionNFTs(slug: String, limit: Int = 30) async throws -> OpenSeaNFTsResponse {
        let endpoint = "\(baseURL)/collection/\(slug)/nfts"
        
        var components = URLComponents(string: endpoint)!
        components.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        let request = createRequest(url: components.url!)
        
        do {
            let dataTask = AF.request(request)
                .validate()
                .serializingDecodable(OpenSeaNFTsResponse.self)
            
            return try await dataTask.value
        } catch {
            print("Error fetching OpenSea collection NFTs: \(error)")
            throw error
        }
    }
    
    /// CoinGecko ID'sini kullanarak OpenSea'den koleksiyon detaylarını getirir
    func fetchCollectionDetailsByCoinGeckoID(id: String) async throws -> OpenSeaCollectionDetail {
        let openSeaSlug = id.toOpenSeaSlug()
        print("🔄 ID Dönüşümü: CoinGecko ID [\(id)] -> OpenSea Slug [\(openSeaSlug)]")
        return try await fetchCollectionDetails(slug: openSeaSlug)
    }
    
    /// CoinGecko ID'sini kullanarak OpenSea'den koleksiyon NFT'lerini getirir
    func fetchCollectionNFTsByCoinGeckoID(id: String, limit: Int = 30) async throws -> OpenSeaNFTsResponse {
        let openSeaSlug = id.toOpenSeaSlug()
        print("🔄 ID Dönüşümü: CoinGecko ID [\(id)] -> OpenSea Slug [\(openSeaSlug)]")
        return try await fetchCollectionNFTs(slug: openSeaSlug, limit: limit)
    }
    
    // MARK: - Private Methods
    
    private func createRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        request.allHTTPHeaderFields = [
            "accept": "application/json",
            "x-api-key": apiKey
        ]
        
        return request
    }
} 
