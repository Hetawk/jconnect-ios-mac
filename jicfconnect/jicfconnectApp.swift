//
//  jicfconnectApp.swift
//  jicfconnect
//
//  Created by Enoch Kwateh Dongbo on 2025/11/11.
//

import SwiftUI

/// Main application entry point with proper dependency injection
@main
struct CareSphereApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .defaultSize(width: 1200, height: 800)
        .windowToolbarStyle(UnifiedWindowToolbarStyle(showsTitle: true))
        #endif
        
        #if os(macOS)
        // Settings window for macOS
        Settings {
            SettingsView()
                .environmentObject(CareSphereTheme.shared)
                .environmentObject(AuthenticationService())
        }
        #endif
    }
}

// MARK: - macOS Support
#if os(macOS)
extension CareSphereApp {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
    }
}
#endif
