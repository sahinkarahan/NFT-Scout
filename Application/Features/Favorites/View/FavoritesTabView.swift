import SwiftUI
import Kingfisher

struct FavoritesTabView: View {
    @State private var viewModel = FavoritesViewModel()
    var onCollectionSelected: ((NFTCollection) -> Void)? = nil
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var loadingProgress: Double = 0.0
    @State private var loadingTimer: Timer? = nil
    @State private var viewDidAppear = false
    @State private var forceRefresh = false  // View'ı zorla yenilemek için
    @State private var isRefreshing = false  // Yenileme işlemi için durum
    @State private var timeFrame: String = "24h" // Default olarak 24h seçildi
    @State private var selectedChain: String = "All Chains" // Default olarak tüm zincirler seçildi
    @State private var showTimeFrameSheet: Bool = false // Sheet gösterimi için
    @State private var showChainSheet: Bool = false // Chain sheet gösterimi için
    @State private var showInUSD: Bool = false // Para birimi gösterimi için (false: native, true: USD)
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Fixed header section - always at top
                VStack(spacing: 12) {
                    Text("Favorites")
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
                
                // İçerik kısmı
                ZStack {
                    if viewModel.isLoading && viewModel.filteredFavoriteCollections.isEmpty && !isRefreshing {
                        // When loading and no collections
                        Color.appPrimary
                            .ignoresSafeArea()
                            .blur(radius: viewModel.isLoading && !isRefreshing ? 4 : 0) // Bulanıklaştırma efekti
                    } else if viewModel.filteredFavoriteCollections.isEmpty {
                        // When no collections but not loading
                        emptyView
                            .blur(radius: viewModel.isLoading && !isRefreshing ? 4 : 0) // Bulanıklaştırma efekti
                    } else {
                        // When there are collections
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 0) {
                                // Filtre picker'ları ScrollView içine taşındı
                                FilterPickersView(
                                    timeFrame: $timeFrame,
                                    selectedChain: $selectedChain,
                                    showTimeFrameSheet: $showTimeFrameSheet,
                                    showChainSheet: $showChainSheet,
                                    showInUSD: $showInUSD
                                )
                                .padding(.top, 16)
                                .padding(.bottom, 16) // Filtreler ile koleksiyon listesi arasında boşluk
                                
                                favoritesListView
                            }
                        }
                        .blur(radius: viewModel.isLoading && !isRefreshing ? 4 : 0) // Bulanıklaştırma efekti
                        .refreshable {
                            // Aşağı çekerek yenileme işlemi
                            print("Favorites list refreshable triggered")
                            isRefreshing = true
                            await viewModel.loadFavorites()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // forceRefresh değiştiğinde view'ı zorla güncelle
                .id(forceRefresh)
            }
            .background(Color.appPrimary)
            
            // Yükleme görünümünü overlay olarak göster, refreshing sırasında gösterme
            if viewModel.isLoading && !isRefreshing {
                VStack {
                    Spacer()
                    loadingView
                        .padding(.horizontal)
                    Spacer()
                }
            }
            
            // Hata görünümü
            if showError {
                FavoritesErrorView(message: errorMessage, buttonTitle: "OK") {
                    withAnimation(.easeInOut) {
                        showError = false
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active && viewDidAppear {
                // Uygulama tekrar aktif olduğunda verileri yenile
                refreshFavorites()
            }
        }
        .onAppear {
            viewDidAppear = true
            refreshFavorites()
        }
        .onReceive(NotificationCenter.default.publisher(for: .favoritesTabSelected)) { _ in
            print("FavoritesTabView - Tab seçildi bildirimi alındı")
            refreshFavorites(forceUpdate: true)
            
            // Tab'e dönüldüğünde zincir filtresini varsayılana sıfırla
            if selectedChain != "All Chains" {
                selectedChain = "All Chains"
                viewModel.filterCollectionsByChain(chain: "All Chains")
            }
        }
        .task {
            // Paralel olarak task ile de verileri yükle
            await loadFavoritesWithForceUpdate()
        }
        .onChange(of: viewModel.isLoading) { oldValue, newValue in
            if newValue && !isRefreshing {
                startLoadingAnimation()
            } else {
                stopLoadingAnimation()
                
                // Refreshing durumunu sıfırla
                isRefreshing = false
                
                // Yükleme bittiğinde view'ı zorla yenile
                if !viewModel.filteredFavoriteCollections.isEmpty {
                    forceUpdateView()
                }
                
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
            // View'ı yenile
            forceUpdateView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .favoriteStatusChanged)) { notification in
            // Favori durumu değiştiğinde update et
            guard let userInfo = notification.userInfo,
                  let _ = userInfo["collectionId"] as? String,
                  let _ = userInfo["isFavorite"] as? Bool else {
                return
            }
            
            // Favoriler değiştiğinde yeniden yükle
            refreshFavorites(forceUpdate: true)
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
    
    // View'ı zorla yenileme metodu
    private func forceUpdateView() {
        DispatchQueue.main.async {
            self.forceRefresh.toggle()
        }
    }
    
    // Favorileri yenilemek için yardımcı metod
    private func refreshFavorites(forceUpdate: Bool = false) {
        print("FavoritesTabView - refreshFavorites çağrıldı, forceUpdate: \(forceUpdate)")
        Task {
            await viewModel.loadFavorites()
            
            if forceUpdate {
                // Yükleme tamamlandığında view'ı zorla yenile
                DispatchQueue.main.async {
                    self.forceRefresh.toggle()
                }
            }
        }
    }
    
    // Yükleme ile birlikte zorla güncelleme yapan metod
    private func loadFavoritesWithForceUpdate() async {
        await viewModel.loadFavorites()
        
        // Yükleme başarılıysa ve koleksiyonlar varsa view'ı zorla yenile
        if !viewModel.filteredFavoriteCollections.isEmpty {
            DispatchQueue.main.async {
                self.forceRefresh.toggle()
            }
        }
        
        // Hata kontrolü ekle
        if let error = viewModel.error {
            DispatchQueue.main.async {
                errorMessage = error.localizedDescription
                withAnimation(.spring) {
                    showError = true
                }
            }
        }
    }
    
    // Yükleme animasyonunu başlat
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
    
    // Yükleme animasyonunu durdur
    private func stopLoadingAnimation() {
        loadingTimer?.invalidate()
        loadingTimer = nil
    }
    
    // Yeni loading view - HomeTabViewLoading ile aynı
    private var loadingView: some View {
        FavoritesTabViewLoading(progress: loadingProgress)
            .frame(maxWidth: .infinity, minHeight: 300)
            .clipShape(.rect(cornerRadius: 12))
    }
    
    private var emptyView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                Spacer(minLength: 100)
                
                Image(systemName: "star.slash")
                    .font(.system(size: 60))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.bottom, 20)
                
                Text("You haven't added any favorite collections yet.")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Spacer(minLength: 200)
            }
            .frame(maxWidth: .infinity, minHeight: UIScreen.main.bounds.height * 0.6)
        }
        .refreshable {
            // Aşağı çekerek yenileme işlemi
            print("Empty view refreshable triggered")
            isRefreshing = true
            await viewModel.loadFavorites()
        }
        .background(Color.appPrimary)
    }
    
    private var favoritesListView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header row
                HStack(spacing: 0) {
                    Text("#")
                        .font(.headline)
                        .foregroundStyle(.gray)
                        .frame(width: 40, alignment: .leading)
                        .padding(.leading, 16)
                    
                    Text("Collection")
                        .font(.headline)
                        .foregroundStyle(.gray)
                        .padding(.trailing, 8)
                    
                    Spacer()
                    
                    Text("Market Cap")
                        .font(.headline)
                        .foregroundStyle(.gray)
                        .frame(width: 130, alignment: .trailing) // Genişliği artırıyorum
                        .padding(.trailing, 50) // Added for star icon
                }
                .padding(.top, 8)
                .padding(.bottom, 12) // Header ile liste arasında boşluk eklendi
                
                // Gri çizgi
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.white.opacity(0.2))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                
                // List the favorite collections
                LazyVStack(spacing: 8) {
                    ForEach(Array(viewModel.filteredFavoriteCollections.enumerated()), id: \.element.id) { index, collection in
                        Button {
                            onCollectionSelected?(collection)
                        } label: {
                            CollectionCardView(
                                collection: collection,
                                index: index + 1,
                                isFavorite: true, // Favori ekranında her zaman true
                                onFavoriteToggle: { isFavorite in
                                    if !isFavorite {
                                        Task {
                                            await viewModel.removeFavorite(collectionId: collection.id)
                                        }
                                    }
                                },
                                timeFrame: timeFrame,
                                showInUSD: showInUSD
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 100) // Space at bottom for tab bar
            }
        }
        .refreshable {
            // Aşağı çekerek yenileme işlemi
            print("Favorites list refreshable triggered")
            isRefreshing = true
            await viewModel.loadFavorites()
        }
    }
    
    private func collectionDetailView(for collection: NFTCollection) -> some View {
        // Koleksiyon detay sayfası
        CollectionDetailView(collection: collection)
            .onAppear {
                // Detay sayfası açıldığında detaylı bilgileri yükle
                Task {
                    await viewModel.loadCollectionDetails(for: collection.id)
                }
            }
    }
    
    private func loadFavorites() async {
        await viewModel.loadFavorites()
        
        // Hata kontrolü ekle
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
    
    // Yüzde değişim formatı
    private func formatPercentage(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.positivePrefix = "+"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: value / 100.0)) ?? "0.00%"
    }
}

// Loading view bileşeni - HomeTabViewLoading ile aynı
struct FavoritesTabViewLoading: View {
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
struct FavoritesErrorView: View {
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
    FavoritesTabView()
} 
