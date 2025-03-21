import SwiftUI

struct LoadingView: View {
    // Progress değeri artık dışarıdan enjekte edilebilir
    var progress: Double
    @State private var isAnimating: Bool = false
    
    // Eğer progress değeri verilmezse, varsayılan olarak 0.65 kullanılacak
    init(progress: Double = 0.65) {
        self.progress = progress
    }
    
    var body: some View {
        ZStack {
            // İlerleme halkası (arka plan)
            Circle()
                .stroke(Color.appPrimary, lineWidth: 8)
                .frame(width: 120, height: 120)
            
            // İlerleme göstergesi
            Circle()
                .trim(from: 0, to: isAnimating ? progress : 0)
                .stroke(Color.appTertiary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 120, height: 120)
                .rotationEffect(Angle(degrees: -90))
                .animation(.easeInOut(duration: 0.1), value: progress)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview("Loading View") {
    ZStack {
        Color.gray.ignoresSafeArea()
        LoadingView()
    }
}

#Preview("Loading View with Progress") {
    ZStack {
        Color.black.ignoresSafeArea()
        LoadingView(progress: 0.75)
    }
}
