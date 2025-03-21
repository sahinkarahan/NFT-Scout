import SwiftUI
import Kingfisher

struct HomeTabView: View {
    @State private var viewModel = HomeTabViewModel.shared
    @State private var loadingProgress: Double = 0.0
    @State private var loadingTimer: Timer? = nil
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var timeFrame: String = "24h" // Default olarak 24h seçildi
    @State private var selectedChain: String = "All Chains" // Default olarak tüm zincirler seçildi
    @State private var showTimeFrameSheet: Bool = false // Time frame sheet gösterimi için
    @State private var showChainSheet: Bool = false // Chain sheet gösterimi için
    @State private var showInUSD: Bool = false // Para birimi gösterimi için (false: native, true: USD)
    var onCollectionSelected: ((NFTCollection) -> Void)? = nil
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Sabit başlık kısmı - Her zaman görünsün ve bulanıklaşmasın
                VStack(spacing: 12) {
                    Text("NFT Scout")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 16)
                        .padding(.horizontal)
                    
                    // Horizontal line
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(.white.opacity(0.2))
                        //.padding(.horizontal, 8)
                }
                .padding(.bottom, 8)
                .background(Color.appPrimary) // Başlık arka planı
                
                // İçerik kısmı - bulanıklaştırma efekti sadece burada uygulanacak
                ZStack {
                    if viewModel.collections.isEmpty && !viewModel.isLoading {
                        emptyView
                            .blur(radius: viewModel.isLoading || showError ? 4 : 0) // Bulanıklaştırma efekti
                    } else {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 0) {
                                // En yüksek piyasa değerine sahip 5 koleksiyon - FilterPickerView'in üzerine taşındı
                                topCollectionsView
                                
                                // Filtre picker'ları ScrollView içine taşındı
                                FilterPickersView(
                                    timeFrame: $timeFrame,
                                    selectedChain: $selectedChain,
                                    showTimeFrameSheet: $showTimeFrameSheet,
                                    showChainSheet: $showChainSheet,
                                    showInUSD: $showInUSD
                                )
                                .padding(.bottom, 16) // Filtreler ile kolleksiyon listesi arasında boşluk
                                
                                collectionsListView
                            }
                        }
                        .blur(radius: viewModel.isLoading || showError ? 4 : 0) // Bulanıklaştırma efekti sadece içeriğe uygulandı
                        .refreshable {
                            await loadCollections()
                        }
                    }
                }
            }
            .background(Color.appPrimary)
            // Bulanıklaştırma efekti tüm içerikten kaldırıldı, çünkü daha aşağıda sadece içerik kısmına uygulandı
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 60)
            }
            
            // Yükleme görünümünü overlay olarak göster
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    loadingView
                        .padding(.horizontal)
                    Spacer()
                }
            }
            
            // Hata görünümü
            if showError {
                HomeErrorView(message: errorMessage, buttonTitle: "OK") {
                    withAnimation(.easeInOut) {
                        showError = false
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .task {
            if viewModel.collections.isEmpty {
                await loadCollections()
            }
        }
        .onChange(of: viewModel.isLoading) { oldValue, newValue in
            if newValue {
                startLoadingAnimation()
            } else {
                stopLoadingAnimation()
                
                // Yükleme bittiğinde hata kontrolü
                if let error = viewModel.error {
                    errorMessage = error.localizedDescription
                    withAnimation(.spring) {
                        showError = true
                    }
                }
            }
        }
        .onChange(of: selectedChain) { _, newChain in
            // Zincir filtresi değiştiğinde koleksiyonları filtrele
            viewModel.filterCollectionsByChain(chain: newChain)
        }
        .onReceive(NotificationCenter.default.publisher(for: .favoriteStatusChanged)) { notification in
            // Favori durumu değiştiğinde update et
            guard let userInfo = notification.userInfo,
                  let collectionId = userInfo["collectionId"] as? String,
                  let isFavorite = userInfo["isFavorite"] as? Bool else {
                return
            }
            
            // UI'ı yenile
            Task {
                // Favori durumunu güncelle, favori state'i henüz değişmediyse
                if viewModel.isFavorite(collectionId: collectionId) != isFavorite {
                    await viewModel.loadFavoriteStates()
                }
            }
        }
        // Tab'e dönüldüğünde zincir filtresini varsayılana sıfırla
        .onReceive(NotificationCenter.default.publisher(for: .homeTabSelected)) { _ in
            if selectedChain != "All Chains" {
                selectedChain = "All Chains"
                viewModel.filterCollectionsByChain(chain: "All Chains")
            }
        }
        .sheet(isPresented: $showTimeFrameSheet) {
            TimeFramePickerSheet(selectedTimeFrame: $timeFrame)
                .presentationDetents([.height(330)]) 
                .presentationBackground(.clear) 
                .presentationCornerRadius(12)
                .interactiveDismissDisabled(false)
        }
        .sheet(isPresented: $showChainSheet) {
            ChainPickerSheet(selectedChain: $selectedChain)
                .presentationDetents([.height(400)]) 
                .presentationBackground(.clear) 
                .presentationCornerRadius(12)
                .interactiveDismissDisabled(false)
        }
    }
    
    private func startLoadingAnimation() {
        // Reset progress
        loadingProgress = 0.0
        
        // Stop any existing timer
        loadingTimer?.invalidate()
        
        // Create a new timer that updates the progress
        loadingTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            loadingProgress += 0.01
            if loadingProgress >= 1.0 {
                loadingProgress = 0.0
            }
        }
    }
    
    private func stopLoadingAnimation() {
        loadingTimer?.invalidate()
        loadingTimer = nil
    }
    
    private var loadingView: some View {
        HomeTabViewLoading(progress: loadingProgress)
            .frame(maxWidth: .infinity, minHeight: 300)
            .clipShape(.rect(cornerRadius: 12))
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 50))
                .foregroundStyle(.white.opacity(0.7))
            
            Text("No NFT collections available yet.")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))
                
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var collectionsListView: some View {
        ZStack {
            if viewModel.isLoading || viewModel.filteredCollections.isEmpty {
                // Placeholder görünümü
                LazyVStack(spacing: 8) {
                    ForEach(0..<10, id: \.self) { _ in
                        CollectionCardView(
                            collection: NFTCollection(
                                id: "placeholder",
                                contractAddress: "",
                                assetPlatformId: "",
                                name: "",
                                symbol: ""
                            ),
                            index: 0,
                            isFavorite: false,
                            onFavoriteToggle: { _ in },
                            timeFrame: timeFrame,
                            showInUSD: showInUSD
                        )
                        .padding(.horizontal, 16)
                    }
                }
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(viewModel.filteredCollections.enumerated()), id: \.element.id) { index, collection in
                        Button {
                            onCollectionSelected?(collection)
                        } label: {
                            CollectionCardView(
                                collection: collection, 
                                index: index + 1,
                                isFavorite: viewModel.isFavorite(collectionId: collection.id),
                                onFavoriteToggle: { isFavorite in
                                    Task {
                                        await viewModel.toggleFavorite(collectionId: collection.id)
                                    }
                                },
                                timeFrame: timeFrame,
                                showInUSD: showInUSD
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        // Lazy loading: Listede son elemana yaklaşırken yeni veri yükle
                        .onAppear {
                            if index == viewModel.filteredCollections.count - 5 && !viewModel.isLoadingMoreData && viewModel.hasMoreData {
                                Task {
                                    await viewModel.loadMoreCollections()
                                }
                            }
                        }
                        // Görünürken koleksiyon detaylarını yükle
                        .task {
                            if collection.floorPrice == nil || collection.marketCap == nil {
                                await viewModel.loadCollectionDetails(for: collection.id)
                            }
                        }
                        .id("\(collection.id)_\(viewModel.isFavorite(collectionId: collection.id))") // Favori durumu değiştiğinde view'i yenile
                    }
                    
                    // Daha fazla veri yükleniyorsa yükleme göstergesi
                    if viewModel.isLoadingMoreData {
                        HStack {
                            Spacer()
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.2)
                                .padding()
                            Spacer()
                        }
                        .frame(height: 60)
                    }
                    
                    // Tüm veriler yüklendi mesajı
                    if !viewModel.hasMoreData && !viewModel.filteredCollections.isEmpty && !viewModel.isLoadingMoreData {
                        HStack {
                            Spacer()
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
    }
    
    private func collectionDetailView(for collection: NFTCollection) -> some View {
        // Koleksiyon detay sayfası
        CollectionDetailView(collection: collection)
    }
    
    private func loadCollections() async {
        startLoadingAnimation()
        await viewModel.fetchCollections()
        
        // Hata kontrolü ekle
        if let error = viewModel.error {
            errorMessage = error.localizedDescription
            withAnimation(.spring) {
                showError = true
            }
        }
    }
    
    // Yeni refresh fonksiyonu ekle
    private func refreshCollections() async {
        // Yükleniyor animasyonunu göster
        startLoadingAnimation()
        
        // Koleksiyonları yeniden çek
        // Önce cache'i temizle ve ardından koleksiyonları yeniden çek
        await viewModel.fetchCollections(forceRefresh: true)
        
        // Hata kontrolü
        if let error = viewModel.error {
            errorMessage = error.localizedDescription
            withAnimation(.spring) {
                showError = true
            }
        }
    }
    
    // Market cap formatı
    private func formatMarketCap(_ value: Double, symbol: String?, symbolOnRight: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "." // Virgül yerine nokta kullanılıyor
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
    
    // Para birimi formatı
    private func formatCurrency(_ value: Double, symbol: String?, symbolOnRight: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "." // Virgül yerine nokta kullanılıyor
        
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
    
    // En yüksek piyasa değerine sahip koleksiyonları gösteren yatay liste
    private var topCollectionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.isLoading || viewModel.collections.isEmpty {
                // Yükleme durumunda placeholder göster - CollectionCardView ile uyumlu
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(0..<5, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 180, height: 180)
                                .clipShape(.rect(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(getTopMarketCapCollections(count: 5)) { collection in
                            // NavigationLink yerine Button kullan
                            Button {
                                // collectionsListView içindekiyle aynı mantık
                                onCollectionSelected?(collection)
                            } label: {
                                topCollectionCard(collection: collection)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 16)
    }
    
    // Tek bir koleksiyon kartı
    private func topCollectionCard(collection: NFTCollection) -> some View {
        ZStack(alignment: .bottomLeading) {
            // Koleksiyon resmi - bannerImage kullanılıyor
            Group {
                if let bannerUrl = collection.bannerImage, let url = URL(string: bannerUrl) {
                    KFImage(url)
                        .resizable()
                        .placeholder {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 180, height: 180)
                                .clipShape(.rect(cornerRadius: 12))
                        }
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 180, height: 180)
                } else if let imageUrl = collection.image?.small, let url = URL(string: imageUrl) {
                    // Banner yoksa small image kullan
                    KFImage(url)
                        .resizable()
                        .placeholder {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 180, height: 180)
                                .clipShape(.rect(cornerRadius: 12))
                        }
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 180, height: 180)
                } else {
                    // Resim yoksa placeholder göster
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 180, height: 180)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundStyle(.white.opacity(0.7))
                        )
                }
            }
            .clipShape(.rect(cornerRadius: 12))
            
            // Koleksiyon adı ve taban fiyatı resmin alt sol köşesinde
            // Arka plan kullanılmadan, gölge yok
            VStack(alignment: .leading, spacing: 4) {
                Text(collection.name)
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Text("Floor: \(collection.displayableFloorPrice) \(collection.nativeCurrencySymbol ?? "ETH")")
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(width: 180, alignment: .leading)
        }
        .frame(width: 180, height: 180)
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white, lineWidth: 2)
        )
    }
    
    // USD cinsinden en yüksek piyasa değerine sahip n adet koleksiyonu alır
    private func getTopMarketCapCollections(count: Int) -> [NFTCollection] {
        return viewModel.filteredCollections
            .filter { $0.marketCap?.usd != nil } // Sadece market cap değeri olanları filtrele
            .sorted { 
                ($0.marketCap?.usd ?? 0) > ($1.marketCap?.usd ?? 0) // USD cinsinden sırala
            }
            .prefix(count) // İlk n adet
            .map { $0 } // Array'e çevir
    }
}

struct HomeTabViewLoading: View {
    // The progress value can now be injected externally
    var progress: Double
    @State private var isAnimating: Bool = false
    
    // If no progress value is provided, 0.65 will be used by default
    init(progress: Double = 0.65) {
        self.progress = progress
    }
    
    var body: some View {
        ZStack {
            // Progress ring (background)
            Circle()
                .stroke(Color.appPrimary, lineWidth: 8)
                .frame(width: 120, height: 120)
            
            // Progress indicator
            Circle()
                .trim(from: 0, to: isAnimating ? progress : 0)
                .stroke(Color.appTertiary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 120, height: 120)
                .rotationEffect(Angle(degrees: -90))
                .animation(.easeInOut(duration: 0.1), value: progress)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// Hata gösterimi için yardımcı view
struct HomeErrorView: View {
    let message: String
    let buttonTitle: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text(message)
                .multilineTextAlignment(.center)
                .font(.body)
                .foregroundStyle(.white)
                .padding(.horizontal)
            
            Button(action: onDismiss) {
                Text(buttonTitle)
                    .font(.headline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.15))
                    .clipShape(.rect(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white, lineWidth: 1)
                    )
            }
            .foregroundStyle(.white)
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white, lineWidth: 1)
        )
        .shadow(radius: 15)
        .padding(32)
    }
}

#Preview {
    HomeTabView()
        .background(Color.appPrimary)
} 
