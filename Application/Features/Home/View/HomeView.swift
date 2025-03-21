import SwiftUI

struct HomeView: View {
    @Binding var authState: AuthState
    @State private var selectedTab: Int = 0
    @State private var selectedCollection: NFTCollection? = nil
    @State private var showDetailView: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Arka plan rengi tüm sayfayı kaplasın
                Color.appPrimary
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab içeriğini göster
                    if showDetailView, let collection = selectedCollection {
                        CollectionDetailView(collection: collection, onDismiss: {
                            showDetailView = false
                            selectedCollection = nil
                        })
                    } else {
                        TabView(selection: $selectedTab) {
                            HomeTabView(onCollectionSelected: { collection in
                                selectedCollection = collection
                                showDetailView = true
                            })
                            .tag(0)
                            
                            SearchTabView(onCollectionSelected: { collection in
                                selectedCollection = collection
                                showDetailView = true
                            })
                            .tag(1)
                            
                            FavoritesTabView(onCollectionSelected: { collection in
                                selectedCollection = collection
                                showDetailView = true
                            })
                            .tag(2)

                            ProfileTabView(authState: $authState)
                                .tag(3)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .edgesIgnoringSafeArea(.all)
                    }
                    
                    // Özel TabBar
                    customTabBar
                        .background(Color.appPrimary)
                }
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            // Eğer detay görünümde iken tab değişirse, detay görünümden çık
            if showDetailView {
                showDetailView = false
                selectedCollection = nil
            }
            
            print("Tab değişti: \(oldValue) -> \(newValue)")
            
            // Tab değişikliğini kaydet
            UserDefaults.standard.set(newValue, forKey: "currentTabIndex")
            
            // Diğer tab için temizleme bildirimi gönder - önemli
            if oldValue == 1 { // 1 == SearchTabView
                // SearchTabView'dan başka bir tab'e geçildiğinde güçlü bir temizleme bildirimi gönder
                NotificationCenter.default.post(
                    name: NSNotification.Name("cleanupSearchTab"),
                    object: nil
                )
            }
            
            // NotificationCenter üzerinden bildirim gönder
            NotificationCenter.default.post(
                name: NSNotification.Name("TabChanged"),
                object: nil,
                userInfo: ["oldTab": oldValue, "newTab": newValue]
            )
            
            // Herbir tab için özel bildirim gönder
            switch newValue {
            case 0:
                NotificationCenter.default.post(
                    name: .homeTabSelected,
                    object: nil
                )
            case 1:
                NotificationCenter.default.post(
                    name: .searchTabSelected,
                    object: nil
                )
            case 2:
                NotificationCenter.default.post(
                    name: .favoritesTabSelected,
                    object: nil
                )
            case 3:
                NotificationCenter.default.post(
                    name: .profileTabSelected,
                    object: nil
                )
            default:
                break
            }
        }
    }
    
    // Özel TabBar Görünümü
    private var customTabBar: some View {
        VStack(spacing: 0) {
            // Üstteki çizgi
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(.gray.opacity(0.5))
            
            HStack {
                Spacer()
                
                // Ana Sayfa Butonu
                tabButton(
                    imageName: selectedTab == 0 ? "house.fill" : "house",
                    isSelected: selectedTab == 0,
                    action: { 
                        selectedTab = 0 
                        // Detay görünümde ise kapat
                        if showDetailView {
                            showDetailView = false
                            selectedCollection = nil
                        }
                    }
                )
                
                Spacer()
                
                // Arama Butonu
                tabButton(
                    imageName: "magnifyingglass",
                    isSelected: selectedTab == 1,
                    action: { 
                        selectedTab = 1 
                        // Detay görünümde ise kapat
                        if showDetailView {
                            showDetailView = false
                            selectedCollection = nil
                        }
                    }
                )
                
                Spacer()
                
                // Favoriler Butonu
                tabButton(
                    imageName: selectedTab == 2 ? "star.fill" : "star",
                    isSelected: selectedTab == 2,
                    action: { 
                        selectedTab = 2 
                        // Detay görünümde ise kapat
                        if showDetailView {
                            showDetailView = false
                            selectedCollection = nil
                        }
                    }
                )
                
                Spacer()
                
                // Profil Butonu
                tabButton(
                    imageName: selectedTab == 3 ? "person.fill" : "person",
                    isSelected: selectedTab == 3,
                    action: { 
                        selectedTab = 3 
                        // Detay görünümde ise kapat
                        if showDetailView {
                            showDetailView = false
                            selectedCollection = nil
                        }
                    }
                )
                
                Spacer()
            }
            .padding(.vertical, 10)
            .background(Color.appPrimary)
        }
    }
    
    // TabBar Buton Görünümü
    private func tabButton(imageName: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: imageName)
                .font(.system(size: 20))
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .frame(width: 44, height: 44)
        }
    }
}

extension Notification.Name {
    static let favoritesTabSelected = Notification.Name("favoritesTabSelected")
    static let homeTabSelected = Notification.Name("homeTabSelected")
    static let searchTabSelected = Notification.Name("searchTabSelected")
    static let profileTabSelected = Notification.Name("profileTabSelected")
}

#Preview {
    HomeView(authState: .constant(.authenticated))
} 
