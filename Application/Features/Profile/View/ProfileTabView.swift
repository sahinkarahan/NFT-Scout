import SwiftUI
import PhotosUI

struct ProfileTabView: View {
    @Binding var authState: AuthState
    @State private var viewModel = ProfileTabViewModel()
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @FocusState private var isNameFieldFocused: Bool
    @State private var selectedItem: PhotosPickerItem?
    @State private var isUpdatingName: Bool = false
    @State private var loadingProgress: Double = 0.0
    @State private var loadingTimer: Timer? = nil
    
    var body: some View {
        ZStack {
            // Ana içerik
            VStack(spacing: 0) {
                // Sabit başlık kısmı - her zaman net, bulanıklaştırma uygulanmaz
                VStack(spacing: 12) {
                    Text("Profile")
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
                
                // İçerik kısmı - Sadece bu alan bulanıklaşacak
                ScrollView {
                    VStack(alignment: .center, spacing: 24) {
                        if let error = viewModel.error {
                            errorView(error)
                        } else {
                            profileContentView
                        }
                    }
                    .padding(.top, 20)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden) // Scroll göstergesini gizle
                .blur(radius: showError || viewModel.isLoading ? 4 : 0) // Bulanıklaştırma efekti sadece içerik kısmına uygulandı
            }
            .background(Color.appPrimary)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 60)
            }
            // Ana view için bulanıklaştırma efekti kaldırıldı
            
            // Yükleme görünümü - ayrı bir katmanda, bulanıksız
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
                ProfileErrorView(message: errorMessage, buttonTitle: "OK") {
                    withAnimation(.easeInOut) {
                        showError = false
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .task {
            if viewModel.isLoading {
                startLoadingAnimation()
            }
            await viewModel.fetchUserProfile()
        }
        .onChange(of: viewModel.isLoading) { oldValue, newValue in
            if newValue {
                startLoadingAnimation()
            } else {
                stopLoadingAnimation()
            }
        }
        .onChange(of: selectedItem) { oldValue, newValue in
            if let newValue = newValue {
                loadImage(from: newValue)
            }
        }
    }
    
    private func loadImage(from item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await viewModel.uploadProfileImage(image: image)
            }
        }
    }
    
    private func startLoadingAnimation() {
        // Reset progress
        loadingProgress = 0.0
        
        // Stop any existing timer
        loadingTimer?.invalidate()
        
        // Create a new timer that updates the progress
        loadingTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            withAnimation {
                loadingProgress += 0.01
                if loadingProgress >= 1.0 {
                    loadingProgress = 0.0
                }
            }
        }
    }
    //stop animation
    private func stopLoadingAnimation() {
        loadingTimer?.invalidate()
        loadingTimer = nil
    }
    
    private var loadingView: some View {
        HomeTabViewLoading(progress: loadingProgress)
            .frame(maxWidth: .infinity, minHeight: 300)
            .clipShape(.rect(cornerRadius: 12))
    }
    
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.red)
            
            Text(error.localizedDescription)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal)
            
            Button {
                Task {
                    await viewModel.fetchUserProfile()
                }
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.2))
                    .clipShape(.rect(cornerRadius: 8))
            }
            .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    private var profileContentView: some View {
        VStack(alignment: .center, spacing: 32) {
            // Profile Image
            ZStack {
                Circle()
                    .fill(Color.appPrimary)
                    .frame(width: 150, height: 150)
                    .overlay {
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 2)
                    }
                    .shadow(radius: 5)
                
                if let profileImage = viewModel.profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 146, height: 146)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    // SF symbolu kaldırıldı - burada kamera ikonu görüntülenmeyecek
                    Color.clear
                        .frame(width: 150, height: 150)
                }
            }
            .padding(.bottom, 20)
            
            // Name Section
            VStack(spacing: 8) {
                // Name Label
                Text("Full Name")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                
                // Name Field or Display
                if !viewModel.hasNameBeenSet || isUpdatingName {
                    // Editable Name Field - isim yoksa veya güncelleme modundaysa
                    TextField("Enter your full name", text: $viewModel.name)
                        .font(.body)
                        .foregroundStyle(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 12)
                        .background(Color.appPrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white, lineWidth: 1)
                        )
                        .padding(.horizontal, 8)
                        .focused($isNameFieldFocused)
                        .onAppear {
                            if isUpdatingName {
                                // Güncelleme modunda ismi temizle
                                viewModel.name = ""
                                isNameFieldFocused = true
                            }
                        }
                } else {
                    // Display Name - isim varsa ve güncelleme modunda değilse
                    Text(viewModel.name)
                        .font(.body)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 12)
                        .background(Color.appPrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white, lineWidth: 1)
                        )
                        .padding(.horizontal, 8)
                }
            }
            //.padding(.vertical, 8)
            
            // Email Section
            VStack(spacing: 8) {
                Text("E-mail")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                
                // E-posta - sola hizalı
                Text(viewModel.userProfile?.email ?? "")
                    .font(.body)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                    .background(Color.appPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white, lineWidth: 1)
                    )
                    .padding(.horizontal, 8)
            }
            //.padding(.vertical, 4)
            
            // Butonlar arasına bir boşluk ekliyoruz
            //Spacer()
            
            // Alt kısımdaki butonları içeren VStack
            VStack(spacing: 16) {
                // İsim Güncelleme Butonu
                Button {
                    if viewModel.hasNameBeenSet && !isUpdatingName {
                        // İlk tıklama: Güncelleme moduna geç
                        isUpdatingName = true
                    } else {
                        // İkinci tıklama veya yeni isim: İsmi kaydet
                        isNameFieldFocused = false
                        
                        // Boş isim kontrolü ekle
                        if viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            errorMessage = "Name cannot be empty. Please enter your full name."
                            withAnimation(.spring) {
                                showError = true
                            }
                            return
                        }
                        
                        Task {
                            await viewModel.updateUserName()
                            if let error = viewModel.error {
                                errorMessage = error.localizedDescription
                                withAnimation(.spring) {
                                    showError = true
                                }
                            } else {
                                // Başarılı güncelleme sonrası güncelleme modunu kapat
                                isUpdatingName = false
                            }
                        }
                    }
                } label: {
                    Text(buttonText)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 12)
                        .background(Color.appPrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white, lineWidth: 1)
                        )
                }
                .padding(.horizontal, 8)
                .disabled(viewModel.isLoading)
                
                // Logout Butonu
                Button {
                    viewModel.handleLogout { result in
                        switch result {
                        case .success:
                            withAnimation(.easeInOut) {
                                authState = .welcome
                            }
                        case .failure(let error):
                            errorMessage = error.localizedDescription
                            withAnimation(.spring) {
                                showError = true
                            }
                        }
                    }
                } label: {
                    Text("Logout")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 12)
                        .background(Color.appPrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white, lineWidth: 1)
                        )
                }
                .padding(.horizontal, 8)
            }
            .padding(.top, 48)
            .padding(.bottom, 8)
        }
    }
    
    private var buttonText: String {
        if !viewModel.hasNameBeenSet {
            return "Add Full Name"
        } else if isUpdatingName {
            return "Save Full Name"
        } else {
            return "Update Full Name"
        }
    }
}

#Preview {
    ProfileTabView(authState: .constant(.authenticated))
        .background(Color.appPrimary)
}

// Hata gösterimi için yardımcı view
struct ProfileErrorView: View {
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
