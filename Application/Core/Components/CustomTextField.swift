import SwiftUI

struct CustomTextField: View {
    let placeholder: String
    let isSecure: Bool
    @Binding var text: String
    
    init(_ placeholder: String, text: Binding<String>, isSecure: Bool = false) {
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
    }
    
    var body: some View {
        Group {
            if isSecure {
                SecureField("", text: $text)
            } else {
                TextField("", text: $text)
            }
        }
        .placeholder(when: text.isEmpty) {
            Text(placeholder)
                .foregroundStyle(.white.opacity(0.5))
        }
        .textFieldStyle(.plain)
        .foregroundStyle(.white)
        .padding()
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.3), lineWidth: 1)
        }
    }
}

private extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    ZStack {
        Color.black
        CustomTextField("Enter text", text: .constant(""))
            .padding()
    }
} 