import SwiftUI

struct AuthFormView: View {
    // MARK: - Properties
    let title: String
    let subtitle: String
    let buttonTitle: String
    let alternateActionText: String
    let showFullNameField: Bool
    
    @Binding var email: String
    @Binding var password: String
    @Binding var fullName: String
    @Binding var initialAnimation: Bool
    @Binding var titleProgress: CGFloat
    
    // Hata durumları için doğrulama değişkenlerini tutuyoruz 
    // ancak görsel olarak bunları göstermeyeceğiz
    var isEmailValid: Bool = true
    var isPasswordValid: Bool = true
    
    let onSubmit: () -> Void
    let onAlternateAction: () -> Void
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 30) {
            VStack {
                Text(subtitle)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.secondary)
                    .blurOpacityEffect(initialAnimation)
                
                Text(title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .textRenderer(TitleTextRenderer(progress: titleProgress))
            }
            .padding(.bottom, 6)
            
            VStack(spacing: 10) {
                if showFullNameField {
                    CustomTextField("Full Name", text: $fullName)
                }
                
                // Email alanı - her zaman normal border kullanıyoruz
                CustomTextField("Email", text: $email)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
                
                // Şifre alanı - her zaman normal border kullanıyoruz
                CustomTextField("Password", text: $password, isSecure: true)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
            }
            .blurOpacityEffect(initialAnimation)
            .padding(.vertical, 10)
            
            PrimaryButton(title: buttonTitle) {
                onSubmit()
            }
            .frame(maxWidth: .infinity)
            .blurOpacityEffect(initialAnimation)
            
            HStack {
                Spacer()
                Text(alternateActionText)
                    .font(.callout)
                    .foregroundStyle(.white.secondary)
                    .onTapGesture {
                        onAlternateAction()
                    }
            }
            .blurOpacityEffect(initialAnimation)
            .padding(.top, 20)
        }
        .padding(.bottom, -55)
    }
}

#Preview {
    ZStack {
        Color.black
        AuthFormView(
            title: "Sign Up",
            subtitle: "Welcome to",
            buttonTitle: "Create Account",
            alternateActionText: "Already have an account?",
            showFullNameField: true,
            email: .constant(""),
            password: .constant(""),
            fullName: .constant(""),
            initialAnimation: .constant(true),
            titleProgress: .constant(1),
            isEmailValid: false,
            isPasswordValid: false,
            onSubmit: {},
            onAlternateAction: {}
        )
        .padding()
    }
} 
