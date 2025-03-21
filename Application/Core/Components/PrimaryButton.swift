import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .foregroundStyle(Color.appPrimary)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 25)
                .padding(.vertical, 12)
                .background(Color.appBackground)
                .clipShape(.rect(cornerRadius: 12))
        }
    }
}

#Preview {
    PrimaryButton(title: "Test Button") {}
        .padding()
} 
