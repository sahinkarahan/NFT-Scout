import SwiftUI
import Kingfisher
import FirebaseFirestore

struct SearchTabView: View {
    @State private var searchText: String = ""
    private let homeViewModel = HomeTabViewModel.shared
    @State private var filteredCollections: [NFTCollection] = []
    @State private var isLoading: Bool = false
    @State private var timeFrame: String = "24h"
    @State private var showInUSD: Bool = false // Para birimi gösterimi için eklendi
    private let firestoreService = FirestoreService.shared
    @State private var favoriteCollectionIds: Set<String> = []
    @State private var isActive: Bool = false
    @State private var searchTask: Task<Void, Never>? = nil
    @State private var hasAppeared: Bool = false
    var onCollectionSelected: ((NFTCollection) -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            searchBarView
            contentView
        }
        .background(Color.appPrimary)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 60)
        }
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            isActive = true
            
            // İlk kez görüntülendiğinde koleksiyonları yükle
            loadCollections()
        }
        .onDisappear {
            // Her kaybolduğunda (tab değiştiğinde veya geri butonu ile çıkıldığında) isActive'i false yap
            // Bu tab dışı picker'lar için önemli
            isActive = false
            
            // Eğer detay sayfasına gidilmediyse, tam temizleme yap
            if !isNavigatingToDetail {
                fullCleanup()
            }
        }
        .onChange(of: homeViewModel.isLoading) { _, newValue in
            isLoading = newValue
        }
        .onReceive(NotificationCenter.default.publisher(for: .searchTabSelected)) { _ in
            isActive = true
            
            // SearchTab'e geri dönüldüğünde koleksiyonları yeniden yükle - eski aramaları koruma
            if hasAppeared && searchText.isEmpty {
                loadCollections()
            }
        }
        // Diğer tab'lere geçildiğinde temizlik yapma
        .onReceive(NotificationCenter.default.publisher(for: .homeTabSelected)) { _ in
            handleTabChange()
        }
        .onReceive(NotificationCenter.default.publisher(for: .favoritesTabSelected)) { _ in
            handleTabChange()
        }
        .onReceive(NotificationCenter.default.publisher(for: .profileTabSelected)) { _ in
            handleTabChange()
        }
        // Özel temizleme bildirimini dinle
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("cleanupSearchTab"))) { _ in
            // Bu bildirim geldiğinde, tam temizleme yap
            print("SearchTabView - Özel temizleme bildirimi alındı")
            fullCleanup()
            isActive = false
        }
        .tag(1) // TabView'da 1 numaralı tag'e sahip olduğu için ekledim
        .id("searchTab_\(isActive)") // isActive değiştiğinde view'ı tamamen yeniden oluştur
    }
    
    // MARK: - Subviews
    
    // Başlık görünümü
    private var headerView: some View {
        VStack(spacing: 12) {
            Text("Search")
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
    }
    
    // Arama çubuğu görünümü
    private var searchBarView: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.white)
                    .font(.system(size: 18))
                    .padding(.leading, 12)
                
                TextField("Search", text: $searchText)
                    .foregroundStyle(.white)
                    .accentColor(.white)
                    .padding(.vertical, 12)
                    .onChange(of: searchText) { _, newValue in
                        // SearchTask oluşturma ve öncekini iptal etme
                        searchTask?.cancel()
                        searchTask = Task {
                            // Kısa bir gecikme ekle, kullanıcı yazmayı bitirene kadar bekle
                            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
                            
                            if !Task.isCancelled {
                                await MainActor.run {
                                    filterCollections()
                                }
                            }
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        searchTask?.cancel()
                        filterCollections()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray)
                            .font(.system(size: 18))
                            .padding(.trailing, 8)
                    }
                }
            }
            .background(Color.gray.opacity(0.2))
            .clipShape(.rect(cornerRadius: 12))
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
    
    // İçerik görünümü
    private var contentView: some View {
        Group {
            if isLoading {
                loadingView
                    .blur(radius: isLoading ? 4 : 0) // Bulanıklaştırma efekti sadece yükleme durumunda ve içerik kısmına uygulanıyor
            } else if searchText.isEmpty {
                emptySearchView
                    .blur(radius: isLoading ? 4 : 0) // Bulanıklaştırma efekti
            } else if filteredCollections.isEmpty {
                noResultsView
                    .blur(radius: isLoading ? 4 : 0) // Bulanıklaştırma efekti
            } else {
                searchResultsView
                    .blur(radius: isLoading ? 4 : 0) // Bulanıklaştırma efekti
            }
        }
    }
    
    // Yükleniyor görünümü
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            Spacer()
        }
    }
    
    // Boş arama görünümü
    private var emptySearchView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.5))
            
            Text("Search for NFT collections")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Text("Type a collection name to search")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    // Sonuç bulunamadı görünümü
    private var noResultsView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "exclamationmark.magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.5))
            
            Text("No collections found")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Text("Try searching with different keywords")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    // Arama sonuçları görünümü
    private var searchResultsView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(Array(filteredCollections.enumerated()), id: \.element.id) { index, collection in
                    resultCard(for: collection, index: index + 1)
                }
            }
            .padding(.vertical, 8)
        }
        .id("searchResults_\(filteredCollections.count)")
    }
    
    // Arama sonucu satırı
    private func resultCard(for collection: NFTCollection, index: Int) -> some View {
        Button {
            onCollectionSelected?(collection)
        } label: {
            CollectionCardView(
                collection: collection,
                index: index,
                isFavorite: isFavorite(collectionId: collection.id),
                onFavoriteToggle: { isFavorite in
                    toggleFavorite(collectionId: collection.id, isFavorite: isFavorite)
                },
                timeFrame: timeFrame,
                showInUSD: showInUSD
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 16)
    }
    
    // Detay sayfasına gidilip gidilmediğini takip etmek için hesaplanan değer
    private var isNavigatingToDetail: Bool {
        // NavigationLink aktifse detay sayfasına gidiliyordur
        return false // Bu değeri doğrudan belirlemek zor, default olarak false kullanıyoruz
    }
    
    // Tab değişimlerini ele alma
    private func handleTabChange() {
        if isActive {
            // Tam temizleme yap
            fullCleanup()
            isActive = false
        }
    }
    
    // Kapsamlı temizleme
    private func fullCleanup() {
        print("SearchTabView - Tam temizleme gerçekleştiriliyor")
        
        // Devam eden işlemleri iptal et
        searchTask?.cancel()
        searchTask = nil
        
        // UI güncellemelerini anında yap
        if Thread.isMainThread {
            // Ana iş parçacığındaysak direkt temizle
            performUICleanup()
        } else {
            // Değilsek, MainActor'a geç
            Task { @MainActor in
                performUICleanup()
            }
        }
        
        // Hafıza boşaltma işaretleri
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            await MainActor.run {
                // State değişkenlerini yeniden başlat
                isLoading = false
                hasAppeared = false 
                filteredCollections = []
                favoriteCollectionIds = []
            }
        }
    }
    
    // UI temizleme işlemleri
    @MainActor private func performUICleanup() {
        // Arama verilerini temizle
        searchText = ""
        filteredCollections = []
        
        // İşaretleyici durumları sıfırla
        isLoading = false
        
        // UI'ı zorla yenile - önemli!
        filteredCollections = []
    }
    
    private func loadCollections() {
        if homeViewModel.collections.isEmpty && !homeViewModel.isLoading {
            Task {
                await homeViewModel.fetchCollections()
                
                if isActive {  // Eğer hala aktifse favori durumlarını yükle
                    await loadFavoriteStates()
                    
                    if !searchText.isEmpty {
                        await MainActor.run {
                            filterCollections()
                        }
                    }
                }
            }
        } else {
            Task {
                if isActive {  // Eğer hala aktifse
                    await loadFavoriteStates()
                    
                    if !searchText.isEmpty {
                        await MainActor.run {
                            filterCollections()
                        }
                    }
                }
            }
        }
    }
    
    private func loadFavoriteStates() async {
        do {
            let favoriteIds = try await firestoreService.getFavoriteCollectionIds()
            
            await MainActor.run {
                if isActive {  // Eğer hala aktifse güncelle
                    self.favoriteCollectionIds = Set(favoriteIds)
                }
            }
        } catch {
            print("Error loading favorite states: \(error)")
        }
    }
    
    private func filterCollections() {
        if searchText.isEmpty {
            filteredCollections = []
        } else {
            filteredCollections = homeViewModel.collections.filter { collection in
                collection.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    private func isFavorite(collectionId: String) -> Bool {
        return favoriteCollectionIds.contains(collectionId)
    }
    
    private func toggleFavorite(collectionId: String, isFavorite: Bool) {
        Task {
            do {
                if isFavorite {
                    guard let collection = homeViewModel.collections.first(where: { $0.id == collectionId }) else { return }
                    
                    try await firestoreService.addFavorite(collectionId: collectionId, collection: collection)
                    
                    await MainActor.run {
                        if isActive {  // Eğer hala aktifse güncelle
                            favoriteCollectionIds.insert(collectionId)
                        }
                    }
                    
                    NotificationCenter.default.post(
                        name: .favoriteStatusChanged,
                        object: nil,
                        userInfo: ["collectionId": collectionId, "isFavorite": true]
                    )
                    
                } else {
                    try await firestoreService.removeFavorite(collectionId: collectionId)
                    
                    await MainActor.run {
                        if isActive {  // Eğer hala aktifse güncelle
                            favoriteCollectionIds.remove(collectionId)
                        }
                    }
                    
                    NotificationCenter.default.post(
                        name: .favoriteStatusChanged,
                        object: nil,
                        userInfo: ["collectionId": collectionId, "isFavorite": false]
                    )
                }
            } catch {
                print("Error toggling favorite: \(error)")
            }
        }
    }
    
    private func collectionDetailView(for collection: NFTCollection) -> some View {
        CollectionDetailView(collection: collection)
            .onAppear {
                // Detay sayfasına gittiğimizde de isActive true kalsın,
                // böylece kullanıcı geri döndüğünde arama sonuçları korunur
            }
            .onDisappear {
                // Detay sayfasından geri dönüldüğünde isActive durumunu kontrol et
                if !isActive {
                    fullCleanup()
                }
            }
    }
}

#Preview {
    SearchTabView()
        .background(Color.appPrimary)
} 
