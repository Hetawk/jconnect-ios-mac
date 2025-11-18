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
    @StateObject private var authService = AuthenticationService.shared
    @StateObject private var settingsService = SenderSettingsService.shared
    
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
        .environmentObject(settingsService)
        .task {
            // Load current user if already authenticated
            if authService.isAuthenticated {
                await authService.loadCurrentUser()
            }
        }
    }
}

#Preview {
    ContentView()
}
