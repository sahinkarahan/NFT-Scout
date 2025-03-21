import SwiftUI

struct TimeFramePickerSheet: View {
    @Binding var selectedTimeFrame: String
    @Environment(\.dismiss) private var dismiss
    @State private var isDragging = false
    @State private var dragOffset: CGFloat = 0
    
    // Sadece iki seçenek: "All" ve "24h"
    private let timeFrameOptions = ["All", "24h"]
    
    // Gri tonları için özel renkler
    private let lightGrayColor = Color(UIColor.systemGray5)
    private let selectedGrayColor = Color(UIColor.systemGray4)
    private let dividerGrayColor = Color(UIColor.systemGray3)
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
                    ForEach(timeFrameOptions, id: \.self) { option in
                        Button(action: {
                            selectedTimeFrame = option
                            // Animasyonsuz doğrudan kapat
                            dismiss()
                        }) {
                            HStack {
                                Text(option)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 20)
                            }
                            .background(selectedTimeFrame == option ? selectedGrayColor : Color.clear)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Son eleman değilse ayraç çizgisi ekle
                        if option != timeFrameOptions.last {
                            Divider()
                                .background(dividerGrayColor)
                        }
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
                TimeFramePickerSheet(selectedTimeFrame: .constant("24h"))
            }
        }
} 
