import SwiftUI
import Kingfisher

struct CollectionCardView: View {
    let collection: NFTCollection
    let index: Int
    let isFavorite: Bool
    let onFavoriteToggle: (Bool) -> Void
    let timeFrame: String
    let showInUSD: Bool
    
    @State private var isHeartAnimating = false
    private var isDataReady: Bool {
        return collection.floorPrice != nil && collection.marketCap != nil
    }
    
    var body: some View {
        if !isDataReady {
            // Veriler yüklenmediyse placeholder göster
            placeholderView
        } else {
            loadedCardView
        }
    }
    
    // Placeholder görünümü - yükleme sırasında gösterilen boş kart
    private var placeholderView: some View {
        HStack(spacing: 12) {
            // Sıra numarası
            Text("\(index)")
                .font(.body.bold())
                .foregroundStyle(.white)
                .frame(width: 30, alignment: .leading)
            
            // Placeholder koleksiyon resmi
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
            
            // Placeholder koleksiyon bilgileri
            VStack(alignment: .leading, spacing: 4) {
                // İsim placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 14)
                    .frame(width: 120)
                
                // Floor price placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 10)
                    .frame(width: 80)
            }
            
            Spacer()
            
            // Market cap placeholder
            VStack(alignment: .trailing, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 14)
                    .frame(width: 90)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 10)
                    .frame(width: 60)
            }
            .frame(width: 130, alignment: .trailing)
            
            // Favori buton placeholder
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 24, height: 24)
        }
        .padding(.vertical, 8)
        .background(Color.appPrimary)
        .clipShape(.rect(cornerRadius: 8))
    }
    
    // Veriler yüklendiğinde gösterilen normal kart
    private var loadedCardView: some View {
        HStack(spacing: 12) {
            // Sıra numarası
            Text("\(index)")
                .font(.body.bold())
                .foregroundStyle(.white)
                .frame(width: 30, alignment: .leading)
            
            // Koleksiyon resmi
            if let image = collection.image, let url = URL(string: image.small) {
                KFImage(url)
                    .placeholder {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 40)
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(.rect(cornerRadius: 8))
            } else {
                // Resim yoksa placeholder göster
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundStyle(.gray)
                    .background(Color.black.opacity(0.2))
                    .clipShape(.rect(cornerRadius: 8))
            }
            
            // Koleksiyon bilgileri
            VStack(alignment: .leading, spacing: 4) {
                Text(collection.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                // Floor price
                if let floorPrice = showInUSD ? collection.floorPrice?.usd : collection.floorPrice?.nativeCurrency {
                    let symbol = showInUSD ? "$" : collection.nativeCurrencySymbol
                    let symbolOnRight = !showInUSD
                    Text("Floor: \(formatCurrency(floorPrice, symbol: symbol, symbolOnRight: symbolOnRight))")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            // Market cap veya Volume 24h (timeFrame'e göre)
            VStack(alignment: .trailing, spacing: 4) {
                if timeFrame == "24h" {
                    // "24h" seçildiğinde volume_24h göster
                    if let volume24h = showInUSD ? collection.volume24h?.usd : collection.volume24h?.nativeCurrency {
                        let symbol = showInUSD ? "$" : collection.nativeCurrencySymbol
                        let symbolOnRight = !showInUSD
                        Text(formatMarketCap(volume24h, symbol: symbol, symbolOnRight: symbolOnRight))
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    } else {
                        Text("N/A")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    
                    // volume_24h_percentage_change göster
                    if let percentageChange = showInUSD ? collection.volume24hPercentageChange?.usd : collection.volume24hPercentageChange?.nativeCurrency {
                        Text(formatPercentage(percentageChange))
                            .font(.caption)
                            .foregroundStyle(percentageChange >= 0 ? .green : .red)
                    }
                } else {
                    // "All" seçildiğinde normal marketCap göster
                    if let marketCap = showInUSD ? collection.marketCap?.usd : collection.marketCap?.nativeCurrency {
                        let symbol = showInUSD ? "$" : collection.nativeCurrencySymbol
                        let symbolOnRight = !showInUSD
                        Text(formatMarketCap(marketCap, symbol: symbol, symbolOnRight: symbolOnRight))
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    } else {
                        Text("N/A")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    
                    // 24 saatlik değişim
                    if let percentageChange = showInUSD ? collection.athChangePercentage?.usd : collection.athChangePercentage?.nativeCurrency {
                        Text(formatPercentage(percentageChange))
                            .font(.caption)
                            .foregroundStyle(percentageChange >= 0 ? .green : .red)
                    }
                }
            }
            .frame(width: 130, alignment: .trailing)
            
            // Favori butonu
            Button(action: {
                // Favorileme durumunu değiştir
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)) {
                    isHeartAnimating = true
                    
                    // Favori durumunu değiştir
                    onFavoriteToggle(!isFavorite)
                    
                    // Animasyonu sıfırla
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isHeartAnimating = false
                    }
                }
            }) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.title3)
                    .foregroundStyle(isFavorite ? .white : .white.opacity(0.6))
                    .scaleEffect(isHeartAnimating ? 1.3 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHeartAnimating)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(PlainButtonStyle())
            .id("favoriteButton_\(collection.id)_\(isFavorite)")
        }
        .padding(.vertical, 8)
        .background(Color.appPrimary)
        .clipShape(.rect(cornerRadius: 8))
    }
    
    // Market cap formatı
    private func formatMarketCap(_ value: Double, symbol: String?, symbolOnRight: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.maximumFractionDigits = 0
        
        // Sembolü sağda veya solda konumlandırma
        if symbolOnRight {
            if let formattedValue = formatter.string(from: NSNumber(value: value)) {
                return "\(formattedValue) \(symbol ?? "$")"
            } else {
                return "0 \(symbol ?? "$")"
            }
        } else {
            if let formattedValue = formatter.string(from: NSNumber(value: value)) {
                return "\(symbol ?? "$")\(formattedValue)"
            } else {
                return "\(symbol ?? "$")0"
            }
        }
    }
    
    // Yüzde değişim formatı
    private func formatPercentage(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.positivePrefix = "+"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: value / 100)) ?? "0%"
    }
    
    // Para birimi formatı
    private func formatCurrency(_ value: Double, symbol: String?, symbolOnRight: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        
        // Küçük değerler için daha fazla ondalık basamak göster
        if value < 0.01 {
            formatter.maximumFractionDigits = 4
        } else {
            formatter.maximumFractionDigits = 2
        }
        
        // Sembolü sağda veya solda konumlandırma
        if symbolOnRight {
            if let formattedValue = formatter.string(from: NSNumber(value: value)) {
                return "\(formattedValue) \(symbol ?? "$")"
            } else {
                return "0.00 \(symbol ?? "$")"
            }
        } else {
            if let formattedValue = formatter.string(from: NSNumber(value: value)) {
                return "\(symbol ?? "$")\(formattedValue)"
            } else {
                return "\(symbol ?? "$")0.00"
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        // Placeholder örneği
        CollectionCardView(
            collection: NFTCollection(
                id: "placeholder-example",
                contractAddress: "0x0000000000000000000000000000000000000000",
                assetPlatformId: "ethereum",
                name: "Loading Example",
                symbol: "LOAD",
                image: nil,
                bannerImage: nil,
                description: nil,
                nativeCurrency: nil,
                nativeCurrencySymbol: nil,
                marketCapRank: nil,
                floorPrice: nil,  // Nil olduğu için placeholder gösterilecek
                marketCap: nil,   // Nil olduğu için placeholder gösterilecek
                volume24h: nil,
                floorPriceIn24hPercentageChange: nil,
                floorPrice24hPercentageChange: nil,
                marketCap24hPercentageChange: nil,
                volume24hPercentageChange: nil,
                numberOfUniqueAddresses: nil,
                totalSupply: nil,
                links: nil,
                athChangePercentage: nil
            ),
            index: 0,
            isFavorite: false,
            onFavoriteToggle: { _ in },
            timeFrame: "All",
            showInUSD: false
        )
        
        CollectionCardView(
            collection: NFTCollection(
                id: "boredapeyachtclub",
                contractAddress: "0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d",
                assetPlatformId: "ethereum",
                name: "Bored Ape Yacht Club",
                symbol: "BAYC",
                image: NFTImage(
                    small: "https://assets.coingecko.com/nft_contracts/images/1/small/bored-ape-yacht-club.png",
                    small2x: "https://assets.coingecko.com/nft_contracts/images/1/small_2x/bored-ape-yacht-club.png"
                ),
                bannerImage: nil,
                description: nil,
                nativeCurrency: nil,
                nativeCurrencySymbol: "ETH",
                marketCapRank: 1,
                floorPrice: PriceInfo(nativeCurrency: 22.5, usd: 35000.0),
                marketCap: PriceInfo(nativeCurrency: 250000000, usd: 390000000.0),
                volume24h: PriceInfo(nativeCurrency: 403.97, usd: 929291),
                floorPriceIn24hPercentageChange: nil,
                floorPrice24hPercentageChange: nil,
                marketCap24hPercentageChange: nil,
                volume24hPercentageChange: PercentageChange(usd: 9.608821222996795, nativeCurrency: -1.8634590532363389),
                numberOfUniqueAddresses: 6500,
                totalSupply: 10000,
                links: nil,
                athChangePercentage: PercentageChange(usd: 2.35, nativeCurrency: 2.35)
            ),
            index: 1, 
            isFavorite: false,
            onFavoriteToggle: { _ in },
            timeFrame: "All",
            showInUSD: false
        )
        
        // "24h" seçili olduğunda nasıl görüneceğini gösteren örnek
        CollectionCardView(
            collection: NFTCollection(
                id: "cryptopunks",
                contractAddress: "0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb",
                assetPlatformId: "ethereum",
                name: "CryptoPunks", 
                symbol: "PUNK",
                image: NFTImage(
                    small: "https://assets.coingecko.com/nft_contracts/images/2/small/cryptopunks.png",
                    small2x: "https://assets.coingecko.com/nft_contracts/images/2/small_2x/cryptopunks.png"
                ),
                bannerImage: nil,
                description: nil,
                nativeCurrency: nil,
                nativeCurrencySymbol: "ETH",
                marketCapRank: 2,
                floorPrice: PriceInfo(nativeCurrency: 39.2, usd: 61000.0),
                marketCap: PriceInfo(nativeCurrency: 375000000, usd: 584000000.0),
                volume24h: PriceInfo(nativeCurrency: 403.97, usd: 929291),
                floorPriceIn24hPercentageChange: nil,
                floorPrice24hPercentageChange: nil,
                marketCap24hPercentageChange: nil,
                volume24hPercentageChange: PercentageChange(usd: 9.608821222996795, nativeCurrency: -1.8634590532363389),
                numberOfUniqueAddresses: 3500,
                totalSupply: 10000,
                links: nil,
                athChangePercentage: PercentageChange(usd: -1.2, nativeCurrency: -1.2)
            ),
            index: 2,
            isFavorite: true,
            onFavoriteToggle: { _ in },
            timeFrame: "24h",
            showInUSD: true
        )
    }
    .padding()
    .background(Color.appPrimary)
} 
