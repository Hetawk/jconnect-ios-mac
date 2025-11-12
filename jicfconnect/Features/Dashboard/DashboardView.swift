import SwiftUI

/// Dashboard view showing key metrics and recent activities
struct DashboardView: View {
    @EnvironmentObject private var theme: CareSphereTheme
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var memberService: MemberService
    @EnvironmentObject private var messageService: MessageService

    @State private var isLoading = false
    @State private var metrics: DashboardMetrics?
    @State private var error: APIError?

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: CareSphereSpacing.lg) {
                    // Welcome section
                    welcomeSection

                    // Quick stats
                    quickStatsSection

                    // Recent activities
                    recentActivitiesSection

                    // Quick actions
                    quickActionsSection
                }
                .padding(CareSphereSpacing.lg)
            }
            .background(theme.colors.background)
            .navigationTitle("Dashboard")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.large)
            #endif
            .refreshable {
                await loadDashboardData()
            }
            .task {
                await loadDashboardData()
            }
        }
    }

    // MARK: - Dashboard Sections

    private var welcomeSection: some View {
        CareSphereCard {
            HStack {
                VStack(alignment: .leading, spacing: CareSphereSpacing.xs) {
                    Text("Welcome back,")
                        .font(CareSphereTypography.bodyMedium)
                        .foregroundColor(theme.colors.onSurface.opacity(0.7))

                    Text(authService.currentUser?.firstName ?? "User")
                        .font(CareSphereTypography.headlineSmall)
                        .foregroundColor(theme.colors.onBackground)

                    Text("Today is a great day to care for others")
                        .font(CareSphereTypography.bodySmall)
                        .foregroundColor(theme.colors.onSurface.opacity(0.6))
                }

                Spacer()

                CareSphereAvatar(
                    imageURL: authService.currentUser?.profileImageURL.flatMap { URL(string: $0) },
                    name: authService.currentUser?.fullName ?? "User",
                    size: 60
                )
            }
        }
    }

    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: CareSphereSpacing.md) {
            Text("Quick Stats")
                .font(CareSphereTypography.titleMedium)
                .foregroundColor(theme.colors.onBackground)
                .padding(.horizontal, CareSphereSpacing.sm)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 2),
                spacing: CareSphereSpacing.md
            ) {
                StatCard(
                    title: "Total Members",
                    value: "\(metrics?.memberMetrics.totalMembers ?? 0)",
                    icon: "person.3.fill",
                    color: .primary
                )

                StatCard(
                    title: "Messages Sent",
                    value: "\(metrics?.messageMetrics.messagesSent ?? 0)",
                    icon: "envelope.fill",
                    color: .success
                )

                StatCard(
                    title: "Active Members",
                    value: "\(metrics?.memberMetrics.activeMembers ?? 0)",
                    icon: "person.fill.checkmark",
                    color: .secondary
                )

                StatCard(
                    title: "Need Follow-up",
                    value: "\(metrics?.memberMetrics.needFollowUp ?? 0)",
                    icon: "exclamationmark.circle.fill",
                    color: .warning
                )
            }
        }
    }

    private var recentActivitiesSection: some View {
        VStack(alignment: .leading, spacing: CareSphereSpacing.md) {
            HStack {
                Text("Recent Activities")
                    .font(CareSphereTypography.titleMedium)
                    .foregroundColor(theme.colors.onBackground)

                Spacer()

                Button("View All") {
                    // Navigate to full activities view
                }
                .buttonStyle(CareSphereButtonStyle.tertiary)
            }
            .padding(.horizontal, CareSphereSpacing.sm)

            CareSphereCard {
                VStack(spacing: CareSphereSpacing.md) {
                    ForEach(sampleActivities, id: \.id) { activity in
                        ActivityRow(activity: activity)

                        if activity.id != sampleActivities.last?.id {
                            Divider()
                                .background(CareSphereColors.borderLight)
                        }
                    }
                }
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: CareSphereSpacing.md) {
            Text("Quick Actions")
                .font(CareSphereTypography.titleMedium)
                .foregroundColor(theme.colors.onBackground)
                .padding(.horizontal, CareSphereSpacing.sm)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 2),
                spacing: CareSphereSpacing.md
            ) {
                QuickActionCard(
                    title: "Add Member",
                    icon: "person.fill.badge.plus",
                    color: .primary
                ) {
                    // Navigate to add member
                }

                QuickActionCard(
                    title: "Send Message",
                    icon: "envelope.fill",
                    color: .success
                ) {
                    // Navigate to compose message
                }

                QuickActionCard(
                    title: "View Analytics",
                    icon: "chart.bar.fill",
                    color: .secondary
                ) {
                    // Navigate to analytics
                }

                QuickActionCard(
                    title: "Create Automation",
                    icon: "gearshape.fill",
                    color: .warning
                ) {
                    // Navigate to automation
                }
            }
        }
    }

    // MARK: - Data Loading

    private func loadDashboardData() async {
        isLoading = true
        defer { isLoading = false }

        // Simulate loading dashboard metrics
        // In real implementation, this would call the analytics service
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        // Mock data
        metrics = DashboardMetrics(
            organizationId: authService.currentUser?.organizationId ?? "",
            period: .last30Days,
            memberMetrics: MemberMetrics(
                totalMembers: 156,
                newMembers: 12,
                activeMembers: 134,
                inactiveMembers: 22,
                needFollowUp: 8,
                averageAge: 42.5,
                membersByStatus: [
                    .active: 134,
                    .inactive: 22,
                ],
                memberGrowthTrend: [],
                topTags: []
            ),
            messageMetrics: MessageMetrics(
                totalMessages: 89,
                messagesSent: 89,
                deliveryRate: 0.94,
                readRate: 0.76,
                messagesByChannel: [:],
                messagesByType: [:],
                messageTrend: [],
                topTemplates: []
            ),
            automationMetrics: AutomationMetrics(
                totalRules: 15,
                activeRules: 12,
                totalExecutions: 234,
                successfulExecutions: 221,
                failedExecutions: 13,
                successRate: 0.94,
                rulesByTrigger: [:],
                executionTrend: [],
                topPerformingRules: []
            ),
            engagementMetrics: EngagementMetrics(
                totalInteractions: 445,
                averageResponseTime: 3600,
                memberEngagementScore: 7.2,
                engagementByChannel: [:],
                engagementTrend: [],
                topEngagedMembers: [],
                lowEngagementMembers: []
            ),
            generatedAt: Date()
        )
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    @EnvironmentObject private var theme: CareSphereTheme
    let title: String
    let value: String
    let icon: String
    let color: CareSphereStatusBadge.StatusColor

    var body: some View {
        CareSphereCard(padding: CareSphereSpacing.md) {
            VStack(alignment: .leading, spacing: CareSphereSpacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color.color(in: theme))

                    Spacer()
                }

                Text(value)
                    .font(CareSphereTypography.headlineSmall)
                    .foregroundColor(theme.colors.onBackground)

                Text(title)
                    .font(CareSphereTypography.bodySmall)
                    .foregroundColor(theme.colors.onSurface.opacity(0.7))
            }
        }
    }
}

struct ActivityRow: View {
    @EnvironmentObject private var theme: CareSphereTheme
    let activity: ActivityItem

    var body: some View {
        HStack(spacing: CareSphereSpacing.md) {
            Image(systemName: activity.icon)
                .font(.title3)
                .foregroundColor(activity.color.color(in: theme))
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(CareSphereTypography.bodyMedium)
                    .foregroundColor(theme.colors.onBackground)

                Text(activity.subtitle)
                    .font(CareSphereTypography.bodySmall)
                    .foregroundColor(theme.colors.onSurface.opacity(0.7))
            }

            Spacer()

            Text(activity.timeAgo)
                .font(CareSphereTypography.caption)
                .foregroundColor(theme.colors.onSurface.opacity(0.6))
        }
    }
}

struct QuickActionCard: View {
    @EnvironmentObject private var theme: CareSphereTheme
    let title: String
    let icon: String
    let color: CareSphereStatusBadge.StatusColor
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            CareSphereCard(padding: CareSphereSpacing.md) {
                VStack(spacing: CareSphereSpacing.sm) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color.color(in: theme))

                    Text(title)
                        .font(CareSphereTypography.labelMedium)
                        .foregroundColor(theme.colors.onBackground)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Sample Data

struct ActivityItem {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let color: CareSphereStatusBadge.StatusColor
    let timeAgo: String
}

private let sampleActivities = [
    ActivityItem(
        title: "New member added",
        subtitle: "Sarah Johnson joined the community",
        icon: "person.fill.badge.plus",
        color: .success,
        timeAgo: "2h ago"
    ),
    ActivityItem(
        title: "Message sent",
        subtitle: "Birthday reminder to 12 members",
        icon: "envelope.fill",
        color: .primary,
        timeAgo: "4h ago"
    ),
    ActivityItem(
        title: "Follow-up needed",
        subtitle: "John Smith requires pastoral care",
        icon: "exclamationmark.circle.fill",
        color: .warning,
        timeAgo: "6h ago"
    ),
    ActivityItem(
        title: "Automation triggered",
        subtitle: "Welcome sequence for new members",
        icon: "gearshape.fill",
        color: .secondary,
        timeAgo: "8h ago"
    ),
]

#Preview {
    DashboardView()
        .environmentObject(CareSphereTheme.shared)
        .environmentObject(AuthenticationService())
        .environmentObject(MemberService(authService: AuthenticationService()))
        .environmentObject(MessageService(authService: AuthenticationService()))
}
