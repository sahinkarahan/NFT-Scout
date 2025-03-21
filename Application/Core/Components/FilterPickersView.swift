import SwiftUI

// Özel Toggle stili
struct RoundedRectangleToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            // Toggle'ın arka planı - RoundedRectangle şeklinde
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2)) // Daha hafif gri arka plan
                .frame(width: 60, height: 36) // Biraz daha yüksek çerçeve
            
            // Toggle butonu - kare şeklinde
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(configuration.isOn ? Color.green : Color.black.opacity(0.1))
                    .frame(width: 30, height: 30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(configuration.isOn ? Color.white : Color.gray.opacity(0.5), lineWidth: 2)
                    )
                
                // Para birimi sembolleri
                if configuration.isOn {
                    // Dolar sembolü - true durumunda
                    Image(systemName: "dollarsign")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    // ETH sembolü yerine ETH metni kullanıyorum
                    Text("ETH")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.gray.opacity(0.7))
                }
            }
            .offset(x: configuration.isOn ? 15 : -15)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isOn)
        }
        .onTapGesture {
            configuration.isOn.toggle()
        }
    }
}

// Filtre picker'larını ayrı bir view olarak ekledik, böylece tekrar kullanılabilir
struct FilterPickersView: View {
    @Binding var timeFrame: String
    @Binding var selectedChain: String
    @Binding var showTimeFrameSheet: Bool
    @Binding var showChainSheet: Bool
    @Binding var showInUSD: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Para birimi toggle'ı
            Toggle("", isOn: $showInUSD)
                .toggleStyle(RoundedRectangleToggleStyle())
                .frame(width: 60, height: 36) // Yükseklik değerini de ekledim
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
            
            // Zaman aralığı picker'ı
            Button(action: {
                showTimeFrameSheet = true
            }) {
                HStack {
                    Text(timeFrame)
                        .font(.headline.bold()) 
                        .foregroundStyle(.white)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption.bold()) 
                        .foregroundStyle(.white)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(Color.gray.opacity(0.2))
                .clipShape(.rect(cornerRadius: 8))
            }
            
            // Zincir filtresi picker'ı
            Button(action: {
                showChainSheet = true
            }) {
                HStack {
                    Text(selectedChain)
                        .font(.headline.bold()) 
                        .foregroundStyle(.white)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption.bold()) 
                        .foregroundStyle(.white)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(Color.gray.opacity(0.2))
                .clipShape(.rect(cornerRadius: 8))
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        //.padding(.top, 12)
    }
}

#Preview {
    ZStack {
        Color.black.edgesIgnoringSafeArea(.all)
        
        FilterPickersView(
            timeFrame: .constant("24h"),
            selectedChain: .constant("All Chains"),
            showTimeFrameSheet: .constant(false),
            showChainSheet: .constant(false),
            showInUSD: .constant(false)
        )
    }
} 
