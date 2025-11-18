import SwiftUI

/// Main app coordinator managing tab navigation and service dependencies
struct MainAppView: View {
    @EnvironmentObject private var theme: CareSphereTheme
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var settingsService: SenderSettingsService
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    TabItemView(icon: "house", text: "Dashboard")
                }
            
            MembersView()
                .tabItem {
                    TabItemView(icon: "person.2", text: "Members")
                }
            
            MessagesView()
                .tabItem {
                    TabItemView(icon: "envelope", text: "Messages")
                }
            
            AnalyticsView()
                .tabItem {
                    TabItemView(icon: "chart.bar", text: "Analytics")
                }
            
            AppSettingsView()
                .tabItem {
                    TabItemView(icon: "gear", text: "Settings")
                }
        }
        .accentColor(theme.colors.primary)
    }
}

/// Tab item view component for consistent tab styling
struct TabItemView: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack {
            Image(systemName: icon)
            Text(text)
        }
    }
}

#Preview {
    MainAppView()
        .environmentObject(CareSphereTheme.shared)
        .environmentObject(AuthenticationService.shared)
        .environmentObject(SenderSettingsService.shared)
}