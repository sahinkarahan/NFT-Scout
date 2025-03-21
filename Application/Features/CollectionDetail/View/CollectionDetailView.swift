import SwiftUI
import Kingfisher

struct CollectionDetailView: View {
    let collection: NFTCollection
    var onDismiss: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CollectionDetailViewModel
    @State private var isDescriptionExpanded = false
    @State private var isDataLoading = true // Tek bir yükleme durumu
    
    init(collection: NFTCollection, onDismiss: (() -> Void)? = nil) {
        self.collection = collection
        self.onDismiss = onDismiss
        self._viewModel = State(initialValue: CollectionDetailViewModel(initialCollection: collection))
    }
    
    var body: some View {
        ZStack {
            Color.appPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navbar View - Sabit kalacak
                ZStack {
                    // Arka plan
                    Color.appPrimary
                        .ignoresSafeArea()
                    
                    // İçerik
                    HStack {
                        // Geri butonu
                        Button(action: {
                            onDismiss?()
                        }) {
                            Image(systemName: "chevron.backward")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.appPrimary)
                                .clipShape(.circle)
                        }
                        
                        Spacer()
                        
                        // Koleksiyon adı
                        Text(viewModel.collectionDetail?.coinGeckoData.name ?? collection.name)
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Denge oluşturmak için boş bir görünüm (sağda geri butonunun genişliğinde)
                        Color.clear
                            .frame(width: 40, height: 40)
                    }
                    .padding(.horizontal, 16)
                }
                .frame(height: 60)
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(.white.opacity(0.2))
                        .offset(y: 30) // ZStack'in tam alt sınırına yerleştirmek için
                 )
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Banner Container
                        GeometryReader { geometry in
                            ZStack {
                                // Banner Image Container - Önce CoinGecko sonra OpenSea verisini kullanalım
                                if !isDataLoading, let bannerImage = viewModel.collectionDetail?.bannerImage, 
                                   let url = URL(string: bannerImage) {
                                    KFImage(url)
                                        .placeholder {
                                            // Banner placeholder gradient
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    .white.opacity(0.1),
                                                    Color.appPrimary
                                                ]),
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        }
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: geometry.size.width)
                                        .frame(maxHeight: .infinity)
                                        .clipped()
                                        .contentShape(Rectangle())
                                        .overlay {
                                            // Gradient overlay
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    .clear,
                                                    Color.appPrimary.opacity(0.5),
                                                    Color.appPrimary
                                                ]),
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        }
                                } else {
                                    // Banner placeholder gradient
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            .white.opacity(0.1),
                                            Color.appPrimary
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    .frame(width: geometry.size.width)
                                    .frame(maxHeight: .infinity)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .ignoresSafeArea()
                        
                        // Collection Logo and Name Container - padding 14
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                // Collection Logo - CoinGecko'dan small imajı kullanalım
                                if !isDataLoading, let imageUrl = viewModel.collectionDetail?.coinGeckoData.image?.small, 
                                   let url = URL(string: imageUrl) {
                                    KFImage(url)
                                        .placeholder {
                                            Image(systemName: "photo")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .foregroundStyle(.gray)
                                        }
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 120, height: 120)
                                        .clipShape(.rect(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white, lineWidth: 4)
                                        )
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.appPrimary)
                                                .frame(width: 124, height: 124)
                                        )
                                } else {
                                    // Logo placeholder
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 120, height: 120)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white, lineWidth: 4)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.white, lineWidth: 1)
                                                )
                                        )
                                }
                                
                                // Collection Name ve Favori Butonu
                                HStack {
                                    if !isDataLoading {
                                        Text(viewModel.collectionDetail?.coinGeckoData.name ?? collection.name)
                                            .font(.title2.bold())
                                            .foregroundStyle(.white)
                                    } else {
                                        // Name placeholder
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(height: 24)
                                            .frame(width: 180)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                                            )
                                    }
                                    
                                    Spacer()
                                    
                                    // Favorilere ekleme/çıkarma butonu
                                    if !isDataLoading {
                                        Button {
                                            if let id = viewModel.collectionDetail?.coinGeckoData.id {
                                                Task {
                                                    // Favoriler ViewModel'i burada çağrılmalı
                                                    // Geçici çözüm: HomeTabViewModel üzerinden favorileri yönetelim
                                                    await HomeTabViewModel.shared.toggleFavorite(collectionId: id)
                                                }
                                            }
                                        } label: {
                                            // Favori durumunu HomeTabViewModel'den kontrol edelim
                                            Image(systemName: viewModel.collectionDetail?.coinGeckoData.id != nil && 
                                                   HomeTabViewModel.shared.isFavorite(collectionId: viewModel.collectionDetail!.coinGeckoData.id) 
                                                   ? "star.fill" : "star")
                                                .font(.system(size: 22))
                                                .foregroundStyle(.white)
                                        }
                                        .padding(.trailing, 20)
                                    } else {
                                        // Star button placeholder
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 30, height: 30)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                                            )
                                            .padding(.trailing, 20)
                                    }
                                }
                                .padding(.top, 8)
                            }
                            .offset(y: -60)
                            .padding(.bottom, -60)
                            .padding(.leading, 14) // 12'den 14'e yükseltildi
                            
                            Spacer()
                        }
                        
                        // Collection Details
                        VStack(alignment: .leading, spacing: 16) {
                            // Collection Quick Info Section - Yeni OpenSea veri gösterimi
                            VStack(alignment: .leading, spacing: 16) {
                                // Yatay bilgi çubuğu
                                if !isDataLoading {
                                    FlowLayout(alignment: .leading, spacing: 16) {
                                        // Total Supply
                                        HStack(spacing: 8) { // 12'den 8'e düşürüldü
                                            HStack(spacing: 4) {
                                                Text(formatWithK(viewModel.collectionDetail?.totalSupply ?? 0))
                                                    .font(.subheadline.bold())
                                                    .foregroundStyle(.white)
                                                
                                                Text("items")
                                                    .font(.subheadline)
                                                    .foregroundStyle(.white) // opacity kaldırıldı
                                            }
                                            
                                            // Daha büyük (size 6) ve eşit aralıklı nokta
                                            Image(systemName: "circle.fill")
                                                .font(.system(size: 6, weight: .bold))
                                                .foregroundStyle(.white)
                                                .padding(.leading, 6)
                                        }
                                        
                                        // Created Date
                                        if let creationDate = viewModel.formattedCreationDate {
                                            HStack(spacing: 8) { // 12'den 8'e düşürüldü
                                                HStack(spacing: 4) {
                                                    Text("Created")
                                                        .font(.subheadline)
                                                        .foregroundStyle(.white) // opacity kaldırıldı
                                                    
                                                    Text(creationDate)
                                                        .font(.subheadline.bold())
                                                        .foregroundStyle(.white)
                                                }
                                                
                                                // Daha büyük (size 6) ve eşit aralıklı nokta
                                                Image(systemName: "circle.fill")
                                                    .font(.system(size: 6, weight: .bold))
                                                    .foregroundStyle(.white)
                                                    .padding(.leading, 6)
                                            }
                                        }
                                        
                                        // Blockchain
                                        if let chain = viewModel.collectionDetail?.coinGeckoData.assetPlatformId {
                                            HStack(spacing: 4) {
                                                Text("Chain")
                                                    .font(.subheadline)
                                                    .foregroundStyle(.white) // opacity kaldırıldı
                                                
                                                Text(chain.capitalized)
                                                    .font(.subheadline.bold())
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                    }
                                    .padding(.top, 20)
                                } else {
                                    // Quick Info Section Placeholder
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 30) 
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                                        )
                                        .padding(.top, 20)
                                }
                            }
                            .padding(.horizontal, 16)
                            
                            // Description Section (OpenSea'den) - Butonlar düzenlendi
                            if !isDataLoading, let description = viewModel.collectionDetail?.openSeaData?.description, !description.isEmpty {
                                // Description'ı temizleyelim
                                let cleanedDescription = cleanDescription(description)
                                
                                // İçerik varsa devam edelim
                                if !cleanedDescription.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        // Açıklama içeriğini bir Text view'a yükleyip ölçüm yapalım
                                        let textView = Text(cleanedDescription)
                                            .font(.body)
                                            .foregroundStyle(.white)
                                            .fixedSize(horizontal: false, vertical: true) // Metnin doğru şekilde sarılmasını sağlamak için
                                        
                                        // 3 satır için yaklaşık bir yükseklik hesabı
                                        let approxLineHeight: CGFloat = 21 // Bir satırın yaklaşık yüksekliği
                                        let threeLineHeight: CGFloat = approxLineHeight * 3
                                        
                                        // Satır sayısını tahmin etmek için text karakterlerini kullan
                                        // Ortalama olarak bir satırda 40 karakter olduğunu varsayalım
                                        // Bu değer tam kesinlik sağlamaz ama bazen daha hızlıdır
                                        let approxLinesCount = Int(ceil(Double(cleanedDescription.count) / 40.0))
                                        let exceedsThreeLines = approxLinesCount > 3
                                        
                                        // Expanded görünümde veya 3 satırdan az olduğu tahmin ediliyorsa doğrudan göster
                                        if isDescriptionExpanded {
                                            textView
                                        } else {
                                            ZStack(alignment: .bottomTrailing) {
                                                textView
                                                    .lineLimit(3)
                                                
                                                // Eğer satır sayısı muhtemelen 3'ten fazlaysa more butonu göster
                                                if exceedsThreeLines {
                                                    // "...more" butonunun solunda opaklık azalışı
                                                    HStack(spacing: 0) {
                                                        // 0'dan 100 opaklığa geçiş yapan gradient
                                                        LinearGradient(
                                                            gradient: Gradient(
                                                                colors: [
                                                                    Color.appPrimary.opacity(0),  // Sol taraf tamamen şeffaf
                                                                    Color.appPrimary              // Sağ taraf app arka plan rengi
                                                                ]
                                                            ),
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        )
                                                        .frame(width: 60) // "...more" butonundan önce geçiş için
                                                        
                                                        // Butonun arka planı için tam opak alan
                                                        Color.appPrimary
                                                            .frame(width: 75) // "...more" butonunun genişliği
                                                    }
                                                    .frame(height: approxLineHeight) // Bir satır yüksekliği
                                                    
                                                    // "... more" butonu - Metinin sonunda olacak
                                                    Button("...more") {
                                                        isDescriptionExpanded = true
                                                    }
                                                    .font(.body.bold())
                                                    .foregroundStyle(.white)
                                                    .padding(.trailing, 4)
                                                }
                                            }
                                            .frame(height: threeLineHeight) // 3 satır için yaklaşık yükseklik
                                        }
                                        
                                        // "less" butonu - Sadece açık durumdayken ve metni 3 satırdan uzunsa göster
                                        if isDescriptionExpanded && exceedsThreeLines {
                                            Button("less") {
                                                isDescriptionExpanded = false
                                            }
                                            .font(.body.bold())
                                            .foregroundStyle(.white)
                                            .padding(.top, 4)
                                        }
                                        
                                        // Sosyal medya butonları - 35x35 boyutuna ayarlandı ve gri renk yapıldı
                                        HStack(spacing: 24) {
                                            // Website butonu - "web" ikonu ile değiştirildi
                                            if let websiteUrl = viewModel.collectionDetail?.openSeaData?.projectUrl,
                                               !websiteUrl.isEmpty,
                                               let url = URL(string: websiteUrl) {
                                                Link(destination: url) {
                                                    Image("web")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 35, height: 35)
                                                        .foregroundStyle(.gray)
                                                }
                                            }
                                            
                                            // Discord butonu
                                            if let discordUrl = viewModel.collectionDetail?.openSeaData?.discordUrl,
                                               !discordUrl.isEmpty,
                                               let url = URL(string: discordUrl) {
                                                Link(destination: url) {
                                                    Image("discord")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 35, height: 35)
                                                        .foregroundStyle(.gray)
                                                }
                                            }
                                            
                                            // Twitter butonu
                                            if let twitterUsername = viewModel.collectionDetail?.openSeaData?.twitterUsername,
                                               !twitterUsername.isEmpty,
                                               let url = URL(string: "https://twitter.com/\(twitterUsername)") {
                                                Link(destination: url) {
                                                    Image("twitter")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 35, height: 35)
                                                        .foregroundStyle(.gray)
                                                }
                                            }
                                        }
                                        .padding(.top, 16)
                                        
                                        // Koleksiyon Metrikleri Bölümü
                                        VStack(alignment: .leading, spacing: 20) {
                                            HStack(alignment: .top, spacing: 36) {//h
                                                // Toplam Hacim
                                                VStack(alignment: .leading, spacing: 4) {
                                                    HStack(spacing: 2) {
                                                        if let marketCap = viewModel.collectionDetail?.marketCap?.nativeCurrency {
                                                            Text(formatMarketValue(marketCap))
                                                                .font(.title3.bold())
                                                                .foregroundStyle(.white)
                                                            
                                                            Text(viewModel.collectionDetail?.nativeCurrencySymbol ?? "ETH")
                                                                .font(.title3.bold())
                                                                .foregroundStyle(.white)
                                                                .padding(.leading, 6)
                                                        } else {
                                                            Text("--")
                                                                .font(.title3.bold())
                                                                .foregroundStyle(.white)
                                                        }
                                                    }
                                                    
                                                    Text("total volume")
                                                        .font(.subheadline)
                                                        .foregroundStyle(.white.opacity(0.7))
                                                }
                                                
                                                // Taban Fiyatı
                                                VStack(alignment: .leading, spacing: 4) {
                                                    HStack(spacing: 2) {
                                                        if let floorPrice = viewModel.collectionDetail?.floorPrice?.nativeCurrency {
                                                            Text(formatCurrency(floorPrice, symbol: ""))
                                                                .font(.title3.bold())
                                                                .foregroundStyle(.white)
                                                            
                                                            Text(viewModel.collectionDetail?.nativeCurrencySymbol ?? "ETH")
                                                                .font(.title3.bold())
                                                                .foregroundStyle(.white)
                                                                .padding(.leading, 6)
                                                        } else {
                                                            Text("--")
                                                                .font(.title3.bold())
                                                                .foregroundStyle(.white)
                                                        }
                                                    }
                                                    
                                                    Text("floor price")
                                                        .font(.subheadline)
                                                        .foregroundStyle(.white.opacity(0.7))
                                                }
                                                
                                                // Toplam Favoriler
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text("\(viewModel.collectionDetail?.userFavoritesCount ?? 0)")
                                                        .font(.title3.bold())
                                                        .foregroundStyle(.white)
                                                    
                                                    Text("total favorites")
                                                        .font(.subheadline)
                                                        .foregroundStyle(.white.opacity(0.7))
                                                }
                                            }
                                        }
                                        .padding(.top, 24)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.top, 6)
                                }
                            } else if isDataLoading {
                                // Description ve Sosyal Medya Placeholder
                                VStack(alignment: .leading, spacing: 16) {
                                    // Description placeholder
                                    VStack(alignment: .leading, spacing: 8) {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(height: 80)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                                            )
                                        
                                        // Sosyal medya butonlar placeholder
                                        HStack(spacing: 24) {
                                            ForEach(0..<3, id: \.self) { _ in
                                                Circle()
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(width: 35, height: 35)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                                                    )
                                            }
                                        }
                                        .padding(.top, 16)
                                        
                                        // Koleksiyon metrikleri placeholder
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(height: 70)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                                            )
                                            .padding(.top, 24)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.top, 6)
                                }
                            }
                            
                            // NFTs Section if available
                            if !isDataLoading, let collection = viewModel.collectionDetail?.coinGeckoData.id {
                                NFTCollectionGridView(
                                    collectionSlug: collection.toOpenSeaSlug(), 
                                    isDataLoading: false,
                                    preloadedNFTs: viewModel.nfts
                                )
                            } else {
                                // NFT placeholder görünümü
                                NFTCollectionGridView(
                                    collectionSlug: "", 
                                    isDataLoading: true,
                                    preloadedNFTs: nil
                                )
                            }
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .tabBar)
        .task {
            isDataLoading = true
            await viewModel.loadCollectionDetails()
            // Tüm veriler yüklendikten sonra isDataLoading'i false yap
            isDataLoading = false
        }
    }
    
    // Currency Formatter
    private func formatCurrency(_ value: Double, symbol: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        if let formattedValue = formatter.string(from: NSNumber(value: value)) {
            return "\(symbol)\(formattedValue)"
        } else {
            return "\(symbol)0"
        }
    }
    
    // Market Value Formatter (K, M, B formatları için)
    private func formatMarketValue(_ value: Double) -> String {
        if value >= 1_000_000_000 {
            return String(format: "%dB", Int(value / 1_000_000_000))
        } else if value >= 1_000_000 {
            return String(format: "%dM", Int(value / 1_000_000))
        } else if value >= 1_000 {
            return String(format: "%dK", Int(value / 1_000))
        } else {
            return formatCurrency(value, symbol: "")
        }
    }
    
    // K formatter for totalSupply
    private func formatWithK(_ value: Int) -> String {
        if value >= 1_000_000 {
            let millions = Double(value) / 1_000_000.0
            return millions.truncatingRemainder(dividingBy: 1) == 0 
                ? String(format: "%dM", Int(millions)) 
                : String(format: "%.1fM", millions)
        } else if value >= 1_000 {
            let thousands = Double(value) / 1_000.0
            return thousands.truncatingRemainder(dividingBy: 1) == 0 
                ? String(format: "%dK", Int(thousands)) 
                : String(format: "%.1fK", thousands)
        } else {
            return "\(value)"
        }
    }
}

// FlowLayout for auto-wrapping items
struct FlowLayout: Layout {
    var alignment: HorizontalAlignment = .center
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? 0
        
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        var nextX: CGFloat = 0
        var nextY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        for i in 0..<subviews.count {
            let size = sizes[i]
            
            if nextX + size.width > containerWidth {
                // Move to next row
                nextX = 0
                nextY += rowHeight + spacing
                totalHeight = nextY
                rowHeight = 0
            }
            
            nextX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        
        totalHeight += rowHeight
        
        return CGSize(width: containerWidth, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        var nextX: CGFloat = bounds.minX
        var nextY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        var rowItems: [(subview: LayoutSubview, size: CGSize, xPos: CGFloat)] = []
        
        for i in 0..<subviews.count {
            let size = sizes[i]
            
            if nextX + size.width > bounds.maxX {
                // Position items in the row according to alignment
                placeRow(in: bounds, rowItems: rowItems, rowHeight: rowHeight, rowY: nextY)
                
                // Reset for next row
                rowItems.removeAll()
                nextX = bounds.minX
                nextY += rowHeight + spacing
                rowHeight = 0
            }
            
            rowItems.append((subviews[i], size, nextX))
            nextX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        
        // Place the last row
        placeRow(in: bounds, rowItems: rowItems, rowHeight: rowHeight, rowY: nextY)
    }
    
    private func placeRow(
        in bounds: CGRect,
        rowItems: [(subview: LayoutSubview, size: CGSize, xPos: CGFloat)],
        rowHeight: CGFloat,
        rowY: CGFloat
    ) {
        for item in rowItems {
            let position: CGPoint
            
            switch alignment {
            case .leading:
                position = CGPoint(x: item.xPos, y: rowY + (rowHeight - item.size.height) / 2)
            case .center:
                position = CGPoint(x: item.xPos, y: rowY + (rowHeight - item.size.height) / 2)
            case .trailing:
                position = CGPoint(x: item.xPos, y: rowY + (rowHeight - item.size.height) / 2)
            default:
                position = CGPoint(x: item.xPos, y: rowY + (rowHeight - item.size.height) / 2)
            }
            
            item.subview.place(at: position, anchor: .topLeading, proposal: .unspecified)
        }
    }
}

// MARK: - Extension for Helper Methods
extension CollectionDetailView {
    /// Description metnini temizleyen fonksiyon
    /// - Parameter text: Temizlenecek orijinal metin
    /// - Returns: Temizlenmiş metin
    private func cleanDescription(_ text: String) -> String {
        // İlk önce başlangıçtaki ve sondaki boşlukları temizle
        var cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // "website" kelimesini kaldır
        cleanedText = cleanedText.replacingOccurrences(of: "website", with: "", options: .caseInsensitive)
        cleanedText = cleanedText.replacingOccurrences(of: "Website", with: "")
        cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines) // Her adımdan sonra tekrar temizle
        
        // Parantez içindeki metinleri kaldır - ()
        while let range = cleanedText.range(of: "\\([^\\)]*\\)", options: .regularExpression) {
            cleanedText.removeSubrange(range)
        }
        cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines) // Her adımdan sonra tekrar temizle
        
        // Köşeli parantez içindeki metinleri kaldır - []
        while let range = cleanedText.range(of: "\\[[^\\]]*\\]", options: .regularExpression) {
            cleanedText.removeSubrange(range)
        }
        cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines) // Her adımdan sonra tekrar temizle
        
        // Fazla boşlukları kaldır
        while cleanedText.contains("  ") {
            cleanedText = cleanedText.replacingOccurrences(of: "  ", with: " ")
        }
        
        // Unicode boşlukları ve diğer boşluk karakterlerini de temizle
        cleanedText = cleanedText.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Son olarak yeniden baştaki ve sondaki boşlukları temizle
        return cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
