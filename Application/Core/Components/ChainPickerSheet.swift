import SwiftUI

struct ChainPickerSheet: View {
    @Binding var selectedChain: String
    @Environment(\.dismiss) private var dismiss
    @State private var isDragging = false
    @State private var dragOffset: CGFloat = 0
    
    // Zincir seçenekleri
    private let chainOptions = ["All Chains", "Ethereum", "Solana", "Bitcoin"]
    
    // Gri tonları için özel renkler
    private let lightGrayColor = Color(UIColor.systemGray5)
    private let selectedGrayColor = Color(UIColor.systemGray4)
    private let handleGrayColor = Color(UIColor.systemGray2)
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Üstteki gri çizgi - farklı bir gri tonu
                Rectangle()
                    .fill(handleGrayColor)
                    .frame(width: 40, height: 5)
                    .clipShape(.rect(cornerRadius: 2.5))
                    .padding(.top, 10)
                    .padding(.bottom, 16)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDragging = true
                                // Sadece aşağı doğru sürüklemeyi işle
                                if value.translation.height > 0 {
                                    dragOffset = value.translation.height
                                }
                            }
                            .onEnded { value in
                                isDragging = false
                                // Belirli bir eşiği aşarsa kapat
                                if value.translation.height > 50 {
                                    dismiss()
                                } else {
                                    // Yeterince sürüklenmemişse eski pozisyonuna geri getir
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )

                // Seçenekler listesi
                VStack(spacing: 0) {
                    ForEach(chainOptions, id: \.self) { option in
                        Button(action: {
                            selectedChain = option
                            // Animasyonsuz doğrudan kapat
                            dismiss()
                        }) {
                            Text(option)
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 20)
                            .background(selectedChain == option ? selectedGrayColor : Color.clear)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.bottom, 30) // Alt kısma ekstra boşluk
            }
            .background(lightGrayColor) // Ana arka plan rengi
            .offset(y: dragOffset)
            .animation(isDragging ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: dragOffset)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottom)
            .edgesIgnoringSafeArea(.bottom)
        }
    }
}

#Preview {
    Color.black
        .ignoresSafeArea()
        .overlay {
            VStack {
                Spacer()
                ChainPickerSheet(selectedChain: .constant("All Chains"))
            }
        }
} 
