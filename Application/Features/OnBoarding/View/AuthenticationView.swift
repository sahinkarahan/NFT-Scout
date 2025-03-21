import SwiftUI

struct AuthenticationView: View {
    // MARK: - Properties
    @Binding var authState: AuthState
    @Binding var initialAnimation: Bool
    @Binding var titleProgress: CGFloat
    @Binding var email: String
    @Binding var password: String
    
    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var loadingProgress: Double = 0
    @State private var emailErrorMessage: String = ""
    @State private var passwordErrorMessage: String = ""
    @State private var isEmailValid: Bool = true
    @State private var isPasswordValid: Bool = true
    
    // MARK: - Body
    var body: some View {
        switch authState {
        case .welcome:
            WelcomeView(
                initialAnimation: $initialAnimation,
                titleProgress: $titleProgress,
                action: { handleStateTransition(to: .signUp) }
            )
        case .signUp:
            AuthFormView(
                title: "Sign Up",
                subtitle: "Create a new account",
                buttonTitle: "Create Account",
                alternateActionText: "Already have an account?",
                showFullNameField: false,
                email: $email,
                password: $password,
                fullName: .constant(""),
                initialAnimation: $initialAnimation,
                titleProgress: $titleProgress,
                isEmailValid: isEmailValid,
                isPasswordValid: isPasswordValid,
                onSubmit: handleSignUp,
                onAlternateAction: { handleStateTransition(to: .login) }
            )
            .blur(radius: isLoading || showError ? 4 : 0)
            .overlay {
                errorLoadingOverlay()
            }
        case .login:
            AuthFormView(
                title: "Log in",
                subtitle: "Welcome back",
                buttonTitle: "Log in",
                alternateActionText: "Don't have an account?",
                showFullNameField: false,
                email: $email,
                password: $password,
                fullName: .constant(""),
                initialAnimation: $initialAnimation,
                titleProgress: $titleProgress,
                isEmailValid: isEmailValid,
                isPasswordValid: isPasswordValid,
                onSubmit: handleLogin,
                onAlternateAction: { handleStateTransition(to: .signUp) }
            )
            .blur(radius: isLoading || showError ? 4 : 0)
            .overlay {
                errorLoadingOverlay()
            }
        case .authenticated:
            // Bu durum ContentView tarafından yönetilecek
            EmptyView()
        }
    }
    
    // MARK: - UI Components
    @ViewBuilder
    private func errorLoadingOverlay() -> some View {
        Group {
            if isLoading && !showError {
                LoadingView(progress: loadingProgress)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.clear)
                    .transition(.opacity)
            }
            
            if showError {
                ProfileErrorView(
                    message: errorMessage,
                    buttonTitle: "OK",
                    onDismiss: {
                        withAnimation(.easeInOut) {
                            showError = false
                        }
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Actions
    private func handleStateTransition(to newState: AuthState) {
        // Reset error messages when transitioning between states
        emailErrorMessage = ""
        passwordErrorMessage = ""
        isEmailValid = true
        isPasswordValid = true
        
        withAnimation(.smooth(duration: 0.75)) {
            authState = newState
            initialAnimation = false
            titleProgress = 0
        }
        
        Task {
            try? await Task.sleep(for: .seconds(0.35))
            
            withAnimation(.smooth(duration: 0.75, extraBounce: 0)) {
                initialAnimation = true
            }
            
            withAnimation(.smooth(duration: 2.5, extraBounce: 0).delay(0.3)) {
                titleProgress = 1
            }
        }
    }
    
    private func handleSignUp() {
        // Form validation
        var isValid = true
        var errorMessages = [String]()
        
        // Email validation
        if email.isEmpty {
            isEmailValid = false
            errorMessages.append("Email address is required")
            isValid = false
        } else if !FormValidator.isValidEmail(email) {
            isEmailValid = false
            errorMessages.append("Please enter a valid email address")
            isValid = false
        } else {
            isEmailValid = true
        }
        
        // Password validation
        if password.isEmpty {
            isPasswordValid = false
            errorMessages.append("Password is required")
            isValid = false
        } else if !FormValidator.isValidPassword(password) {
            isPasswordValid = false
            errorMessages.append("Password must be at least 6 characters")
            isValid = false
        } else {
            isPasswordValid = true
        }
        
        // If validation fails, don't proceed
        if !isValid {
            // "and" ile hata mesajlarını birleştir
            errorMessage = formatErrorMessages(errorMessages)
            withAnimation(.easeInOut) {
                showError = true
            }
            return
        }
        
        // Proceed with signup if validation passes
        withAnimation(.easeInOut) {
            isLoading = true
            loadingProgress = 0
        }
        
        // Progress animasyonunu başlat
        let progressTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
        let progressCancellable = progressTimer.sink { _ in
            withAnimation {
                if self.loadingProgress < 0.95 {
                    self.loadingProgress += 0.02
                }
            }
        }
        
        Task {
            defer {
                progressCancellable.cancel()
            }
            
            do {
                try await AuthenticationManager.shared.createUser(email: email, password: password)
                
                withAnimation {
                    loadingProgress = 1.0 // Tamamlandığında 100%
                }
                
                // Kısa bir gecikme ekleyelim ki kullanıcı 100% görebilsin
                try? await Task.sleep(for: .seconds(0.5))
                
                await MainActor.run {
                    withAnimation(.easeInOut) {
                        authState = .authenticated
                    }
                }
            } catch {
                handleAuthError(error)
            }
            
            withAnimation(.easeInOut) {
                isLoading = false
            }
        }
    }
    
    private func handleLogin() {
        // Form validation
        var isValid = true
        var errorMessages = [String]()
        
        // Email validation
        if email.isEmpty {
            isEmailValid = false
            errorMessages.append("Email address is required")
            isValid = false
        } else if !FormValidator.isValidEmail(email) {
            isEmailValid = false
            errorMessages.append("Please enter a valid email address")
            isValid = false
        } else {
            isEmailValid = true
        }
        
        // Password validation
        if password.isEmpty {
            isPasswordValid = false
            errorMessages.append("Password is required")
            isValid = false
        } else {
            isPasswordValid = true
        }
        
        // If validation fails, don't proceed
        if !isValid {
            // "and" ile hata mesajlarını birleştir
            errorMessage = formatErrorMessages(errorMessages)
            withAnimation(.easeInOut) {
                showError = true
            }
            return
        }
        
        withAnimation(.easeInOut) {
            isLoading = true
            loadingProgress = 0
        }
        
        // Progress animasyonunu başlat
        let progressTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
        let progressCancellable = progressTimer.sink { _ in
            withAnimation {
                if self.loadingProgress < 0.95 {
                    self.loadingProgress += 0.02
                }
            }
        }
        
        Task {
            defer {
                progressCancellable.cancel()
            }
            
            do {
                try await AuthenticationManager.shared.signIn(email: email, password: password)
                
                withAnimation {
                    loadingProgress = 1.0 // Tamamlandığında 100%
                }
                
                // Kısa bir gecikme ekleyelim ki kullanıcı 100% görebilsin
                try? await Task.sleep(for: .seconds(0.5))
                
                await MainActor.run {
                    withAnimation(.easeInOut) {
                        authState = .authenticated
                    }
                }
            } catch {
                handleAuthError(error)
            }
            
            withAnimation(.easeInOut) {
                isLoading = false
            }
        }
    }
    
    @MainActor
    private func handleAuthError(_ error: Error) {
        // Hata mesajını hazırla
        if let authError = error as? AuthError {
            errorMessage = authError.localizedDescription
        } else {
            errorMessage = error.localizedDescription
        }
        
        // LoadingView'u kapat ve ErrorView'u aynı anda göster - gecikme olmadan
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = false
            showError = true
        }
    }
    
    // Hata mesajlarını formatlamak için yardımcı fonksiyon
    private func formatErrorMessages(_ messages: [String]) -> String {
        switch messages.count {
        case 0:
            return ""
        case 1:
            return messages[0]
        case 2:
            return messages[0] + " and " + messages[1]
        default:
            // İkiden fazla hata varsa, son eleman için "and" kullan
            var result = ""
            for (index, message) in messages.enumerated() {
                if index == 0 {
                    result = message
                } else if index == messages.count - 1 {
                    result += " and " + message
                } else {
                    result += ", " + message
                }
            }
            return result
        }
    }
}

// MARK: - Welcome View
private struct WelcomeView: View {
    @Binding var initialAnimation: Bool
    @Binding var titleProgress: CGFloat
    let action: () -> Void
    
    var body: some View {
        VStack {
            Text("Welcome to")
                .fontWeight(.semibold)
                .foregroundStyle(.white.secondary)
                .blurOpacityEffect(initialAnimation)
            
            Text("NFT Scout")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
                .textRenderer(TitleTextRenderer(progress: titleProgress))
                .padding(.bottom, 55)
            
            Text("Don't get lost in the NFT world! With NFT Scout, track the latest prices, set your favorite collections, and never miss an opportunity.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.secondary)
                .blurOpacityEffect(initialAnimation)
                .padding(.top, 5)
            
            VStack {
                PrimaryButton(title: "Let's Go") {
                    action()
                }
                .blurOpacityEffect(initialAnimation)
            }
            .padding(.top, 55)
        }
    }
} 
