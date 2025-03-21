import SwiftUI

extension View {
    func performAuthTransition(
        isSourceViewActive: Binding<Bool>,
        isTargetViewActive: Binding<Bool>,
        initialAnimation: Binding<Bool>,
        titleProgress: Binding<CGFloat>
    ) {
        withAnimation(.smooth(duration: 0.75)) {
            isSourceViewActive.wrappedValue = false
            isTargetViewActive.wrappedValue = true
            initialAnimation.wrappedValue = false
            titleProgress.wrappedValue = 0
        }
        
        Task {
            try? await Task.sleep(for: .seconds(0.35))
            
            withAnimation(.smooth(duration: 0.75, extraBounce: 0)) {
                initialAnimation.wrappedValue = true
            }
            
            withAnimation(.smooth(duration: 2.5, extraBounce: 0).delay(0.3)) {
                titleProgress.wrappedValue = 1
            }
        }
    }
} 