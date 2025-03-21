//
//  ContentView.swift
//  Application
//
//  Created by Şahin Karahan on 18.02.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var authState: AuthState = .welcome
    
    var body: some View {
        Group {
            if authState == .authenticated || AuthenticationManager.shared.currentUser != nil {
                HomeView(authState: $authState)
            } else {
                IntroPage(authState: $authState)
            }
        }
        .onChange(of: AuthenticationManager.shared.currentUser) { oldValue, newValue in
            withAnimation {
                authState = newValue != nil ? .authenticated : .welcome
            }
        }
    }
}

#Preview {
    ContentView()
}
