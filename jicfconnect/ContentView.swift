//
//  ContentView.swift
//  jicfconnect
//
//  Created by Enoch Kwateh Dongbo on 2025/11/11.
//

import SwiftUI

/// Main app coordinator handling authentication state and app flow
struct ContentView: View {
    @StateObject private var theme = CareSphereTheme.shared
    @StateObject private var authService = AuthenticationService()
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                MainAppView()
            } else {
                AuthenticationView()
            }
        }
        .environmentObject(theme)
        .environmentObject(authService)
        .task {
            // Check for saved authentication state on app launch
            await authService.checkAuthenticationState()
        }
    }
}

#Preview {
    ContentView()
}
