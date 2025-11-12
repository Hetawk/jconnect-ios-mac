import SwiftUI

/// Main app coordinator managing tab navigation and service dependencies
struct MainAppView: View {
    @EnvironmentObject private var theme: CareSphereTheme
    @EnvironmentObject private var authService: AuthenticationService
    
    @StateObject private var memberService: MemberService
    @StateObject private var messageService: MessageService
    
    init() {
        // Initialize services with temporary auth service
        // Will be updated when the real authService becomes available
        let tempAuthService = AuthenticationService()
        self._memberService = StateObject(wrappedValue: MemberService(authService: tempAuthService))
        self._messageService = StateObject(wrappedValue: MessageService(authService: tempAuthService))
    }
    
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
            
            SettingsView()
                .tabItem {
                    TabItemView(icon: "gear", text: "Settings")
                }
        }
        .accentColor(theme.colors.primary)
        .environmentObject(memberService)
        .environmentObject(messageService)
        .onAppear {
            // Update services with the actual authService when view appears
            updateServiceDependencies()
        }
        .onChange(of: authService.isAuthenticated) { _ in
            // Re-inject auth service if authentication state changes
            updateServiceDependencies()
        }
    }
    
    private func updateServiceDependencies() {
        memberService.updateAuthService(authService)
        messageService.updateAuthService(authService)
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
        .environmentObject(AuthenticationService())
}