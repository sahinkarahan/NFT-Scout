import SwiftUI

struct ErrorView: View {
    let message: String
    let buttonTitle: String
    let action: () -> Void
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    init(message: String, buttonTitle: String = "OK", action: @escaping () -> Void) {
        self.message = message
        self.buttonTitle = buttonTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(message)
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
            
            Button(action: action) {
                Text(buttonTitle)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.15))
                    .clipShape(.rect(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white, lineWidth: 1)
                    )
            }
            .frame(maxWidth: 200)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 30)
        .padding(.vertical, 30)
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white, lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring) {
                scale = 1
                opacity = 1
            }
        }
    }
}

#Preview("Error View") {
    ZStack {
        Color.black.edgesIgnoringSafeArea(.all)
        ErrorView(
            message: "This is an error message that will be shown to the user.",
            buttonTitle: "OK"
        ) {
            print("Error closed")
        }
    }
}

#Preview("Error View - Long Message") {
    ZStack {
        Color.black.edgesIgnoringSafeArea(.all)
        ErrorView(
            message: "This is a very long error message. Sometimes error messages can be very long and span multiple lines. It's important to see how ErrorView looks in this case.",
            buttonTitle: "Understood"
        ) {
            print("Long error message closed")
        }
    }
} 
