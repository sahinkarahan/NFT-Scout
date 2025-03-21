import SwiftUI
import Kingfisher
import Foundation

struct NFTGridView: View {
    let nfts: [OpenSeaNFT]
    let isLoading: Bool
    
    let columns = [
        GridItem(.fixed(UIScreen.main.bounds.width / 2 - 26), spacing: 20),
        GridItem(.fixed(UIScreen.main.bounds.width / 2 - 26), spacing: 20)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: columns, spacing: 28) {
                if isLoading {
                    // Placeholder görünümü
                    ForEach(0..<10, id: \.self) { _ in
                        placeholderItem
                    }
                } else {
                    // Gerçek veri görünümü
                    ForEach(nfts, id: \.identifier) { nft in
                        NFTItemView(nft: nft)
                            .frame(width: UIScreen.main.bounds.width / 2 - 32, height: 300)
                    }
                }
            }
            .padding(.horizontal, 6)
        }
        .padding(.horizontal, 10)
        .padding(.top, 24)
    }
    
    private var placeholderItem: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.3))
            .frame(width: UIScreen.main.bounds.width / 2 - 32, height: 250)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.6), lineWidth: 1)
            )
    }
    
    // Koleksiyon için NFT'leri getir
    static func fetchNFTsForCollection(collectionSlug: String, limit: Int = 50, cursor: String? = nil) async throws -> (nfts: [OpenSeaNFT], nextCursor: String?) {
        let url = URL(string: "https://api.opensea.io/api/v2/collection/\(collectionSlug)/nfts")!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "\(limit)"),
        ]
        
        // Cursor varsa ekle (sayfalama için)
        if let cursor = cursor {
            queryItems.append(URLQueryItem(name: "next", value: cursor))
        }
        
        components.queryItems = components.queryItems.map { $0 + queryItems } ?? queryItems
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.allHTTPHeaderFields = [
            "accept": "application/json",
            "x-api-key": "c12c83c5cbcd4b598689f36280490cbe"
        ]
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OpenSeaNFTsResponse.self, from: data)
        return (response.nfts, response.next)
    }
    
    // NFT'nin fiyat bilgisini getir
    static func fetchPriceForNFT(collectionSlug: String, identifier: String) async throws -> NFTPrice {
        let url = URL(string: "https://api.opensea.io/api/v2/offers/collection/\(collectionSlug)/nfts/\(identifier)/best")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.allHTTPHeaderFields = [
            "accept": "application/json",
            "x-api-key": "c12c83c5cbcd4b598689f36280490cbe"
        ]
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(NFTPriceResponse.self, from: data)
        return response.price
    }
}

struct NFTItemView: View {
    let nft: OpenSeaNFT
    @State private var isPressed = false
    @State private var likeCount = Int.random(in: 10...99)
    @State private var imageLoadFailed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // NFT Image
            if let imageUrl = nft.displayImageUrl ?? nft.imageUrl, let url = URL(string: imageUrl) {
                KFImage(url)
                    .placeholder {
                        // Boş gri placeholder - açık gri kenarlıklı
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                            )
                            .clipShape(.rect(cornerRadius: 12))
                    }
                    .onFailure { _ in
                        imageLoadFailed = true
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipShape(.rect(cornerRadius: 12))
                    .shadow(radius: 2)
            } else {
                // Resim URL'si yoksa gri placeholder göster - açık gri kenarlıklı
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .clipShape(.rect(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                    )
            }
            
            // NFT ID and Name
            VStack(alignment: .leading, spacing: 8) {
                if let name = nft.name {
                    Text(name)
                        .font(.callout.bold())
                        .foregroundStyle(.white)
                        .lineLimit(1)
                } else {
                    Text("#\(nft.identifier)")
                        .font(.callout.bold())
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                
                // "Buy Now" ve fiyat bilgisi bölümü
                VStack(alignment: .leading, spacing: 8) {
                    // "Buy Now" text
                    Text("Buy Now")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .opacity(nft.price != nil ? 1 : 0)
                        .padding(.bottom, -6)
                    
                    // Fiyat ve yıldız/numara birlikte, sol-sağ hizalı
                    HStack {
                        if let price = nft.price {
                            Text(price.formattedPrice())
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                        } else {
                            // Fiyat bilgisi yoksa opacity 0 yaparak gizle
                            Text("Fiyat Bilgisi Yok")
                                .font(.subheadline.bold())
                                .foregroundStyle(.white.opacity(0.7))
                                .opacity(0)
                        }
                        
                        Spacer()
                        
                        // Yıldız ve rakam sağa hizalanmış - her zaman görünür olmalı
                        HStack(spacing: 3) {
                            Image(systemName: "star")
                                .font(.subheadline.bold())
                                .foregroundStyle(.white.opacity(0.7))
                            
                            Text("\(likeCount)")
                                .font(.subheadline.bold())
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .background(Color.white.opacity(0.3))
        .clipShape(.rect(cornerRadius: 12))
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(), value: isPressed)
        .onTapGesture {
            // Dokunma efekti
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
                
                // Gecikme ekle
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        isPressed = false
                    }
                    
                    // OpenSea URL'ye yönlendir
                    if let openseaUrl = nft.openseaUrl, let url = URL(string: openseaUrl) {
                        #if os(iOS)
                        UIApplication.shared.open(url)
                        #endif
                    }
                }
            }
        }
    }
}

struct EmptyNFTView: View {
    let isFilteredResults: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // SF Symbol
            Image(systemName: isFilteredResults ? "magnifyingglass" : "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.5))
            
            // Primary text
            Text(isFilteredResults ? "No matching NFTs found" : "No NFTs in this collection")
                .font(.title3)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            
            // Secondary text
            Text(isFilteredResults ? "Try different search terms or clear your search" : "This collection doesn't have any NFTs available")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
        }
        .padding(.vertical, 40)
    }
}

struct NFTCollectionGridView: View {
    let collectionSlug: String
    let isDataLoading: Bool
    let preloadedNFTs: [OpenSeaNFT]? // Önceden yüklenmiş NFT'leri aktarmak için
    let targetNFTCount = 20
    
    @State private var nfts: [OpenSeaNFT] = []
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var errorMessage: String?
    @State private var searchText: String = ""
    
    var filteredNFTs: [OpenSeaNFT] {
        let baseNFTs = preloadedNFTs?.isEmpty == false ? preloadedNFTs! : nfts
        
        // İlk olarak resmi başarıyla yüklenebilen NFT'leri filtrele
        let nftsWithImages = baseNFTs.filter { nft in
            // Resim URL'si olmayan NFT'leri doğrudan çıkar
            guard nft.displayImageUrl != nil || nft.imageUrl != nil else {
                return false
            }
            
            // Sadece geçerli URL'leri kontrol et, geçersiz URL'leri de filtreleyelim
            if let imageUrl = nft.displayImageUrl ?? nft.imageUrl {
                // URL formatı geçerli mi kontrol et
                return URL(string: imageUrl) != nil
            }
            return false
        }
        
        // Ardından arama filtresini uygula
        if searchText.isEmpty {
            return Array(nftsWithImages.prefix(targetNFTCount))
        } else {
            // İsim veya tanımlayıcıya göre filtrele
            return nftsWithImages.filter { nft in
                let nameMatch = nft.name?.localizedCaseInsensitiveContains(searchText) ?? false
                let idMatch = nft.identifier.localizedCaseInsensitiveContains(searchText)
                return nameMatch || idMatch
            }.prefix(targetNFTCount).map { $0 }
        }
    }
    
    var body: some View {
        VStack {
            // Search bar with placeholder
            if isDataLoading {
                // Placeholder for search bar
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
            } else {
                // Actual search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.white)
                        .font(.system(size: 16))
                        .padding(.leading, 12)
                    
                    TextField("Search", text: $searchText)
                        .foregroundStyle(.white)
                        .accentColor(.white)
                        .padding(.vertical, 10)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.gray)
                                .font(.system(size: 16))
                                .padding(.trailing, 8)
                        }
                    }
                }
                .background(Color.gray.opacity(0.2))
                .clipShape(.rect(cornerRadius: 8))
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 16)
            }
            
            if isDataLoading {
                // Placeholder görünümü
                NFTGridView(nfts: [], isLoading: true)
            } else if let preloadedNFTs = preloadedNFTs, !preloadedNFTs.isEmpty {
                // Önceden yüklenmiş NFT'leri göster - view model tarafından sağlanan
                ScrollView {
                    VStack {
                        NFTGridView(nfts: filteredNFTs, isLoading: false)
                    }
                    .padding(.bottom, 16)
                }
            } else if isLoading && nfts.isEmpty {
                // İç yükleme durumu - bu durumda artık placeholder göstermiyoruz
            } else if let error = errorMessage {
                // Hata durumu
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.white)
                    
                    Text(error)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Tekrar Dene") {
                        Task {
                            await loadNFTs()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
                .padding()
            } else if filteredNFTs.isEmpty {
                EmptyNFTView(isFilteredResults: !searchText.isEmpty)
            } else {
                ScrollView {
                    VStack {
                        NFTGridView(nfts: filteredNFTs, isLoading: false)
                    }
                    .padding(.bottom, 16)
                }
            }
        }
        .task {
            // Önceden yüklenmiş NFT'ler yoksa kendi yükleme işlemini başlat
            if preloadedNFTs == nil && !isDataLoading {
                await loadNFTs()
            }
        }
        
        // Diğer yükleme mantıkları...
    }
    
    private func loadNFTs() async {
        isLoading = true
        errorMessage = nil
        nfts = []
        
        do {
            // Başlangıçta targetNFTCount'un 3 katı kadar NFT yükleyelim
            // Böylece görüntüsü olmayan NFT'ler filtrelense bile yeterli sayıda görüntü olasılığı yüksek olacak
            let result = try await NFTGridView.fetchNFTsForCollection(collectionSlug: collectionSlug, limit: targetNFTCount * 3)
            
            nfts = result.nfts
            isLoading = false
            
            // NFT'ler başarıyla yüklendiyse fiyat bilgilerini yükle
            if !nfts.isEmpty {
                await loadNFTPrices(for: nfts)
            }
        } catch {
            nfts = []
            isLoading = false
            errorMessage = "NFT'ler yüklenirken bir hata oluştu: \(error.localizedDescription)"
            print("NFT'ler yüklenirken hata: \(error)")
        }
    }
    
    private func loadNFTPrices(for newNFTs: [OpenSeaNFT]) async {
        isLoading = true
        
        // Fiyat bilgisi yüklenecek NFT'lerin durumunu takip etmek için bir grup oluşturulur
        var processedNFTs = [String: Bool]()
        
        // Yeni NFT'ler için fiyat bilgisi yükleme işlemi başlat
        await withTaskGroup(of: (String, NFTPrice?).self) { group in
            for nft in newNFTs {
                // Her NFT için asenkron task oluştur
                group.addTask {
                    // NFT henüz işlenmemişse
                    if processedNFTs[nft.identifier] != true {
                        do {
                            // Fiyat bilgisini getir
                            let price = try await NFTGridView.fetchPriceForNFT(collectionSlug: self.collectionSlug, identifier: nft.identifier)
                            return (nft.identifier, price)
                        } catch {
                            print("NFT ID \(nft.identifier) için fiyat bilgisi alınamadı: \(error)")
                            return (nft.identifier, nil)
                        }
                    }
                    return (nft.identifier, nil)
                }
            }
            
            // Sonuçları topla ve NFT'leri güncelle
            for await (identifier, price) in group {
                processedNFTs[identifier] = true
                
                // Eşleşen NFT indeksini bul
                if let index = nfts.firstIndex(where: { $0.identifier == identifier }), let price = price {
                    // NFT'nin price özelliğini güncelle
                    nfts[index].price = price
                }
            }
        }
        
        isLoading = false
    }
}
