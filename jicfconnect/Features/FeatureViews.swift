import SwiftUI

/// Members management view
struct MembersView: View {
    @EnvironmentObject private var theme: CareSphereTheme
    @EnvironmentObject private var memberService: MemberService

    @State private var searchText = ""
    @State private var selectedMember: Member?
    @State private var showingAddMember = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                CareSphereSearchBar(
                    text: $searchText,
                    placeholder: "Search members..."
                ) {
                    Task {
                        await searchMembers()
                    }
                }
                .padding(CareSphereSpacing.md)

                // Members list
                if memberService.isLoading {
                    CareSphereLoadingView("Loading members...")
                } else if memberService.members.isEmpty {
                    CareSphereEmptyState(
                        icon: "person.3",
                        title: "No Members Yet",
                        description: "Add your first member to start building your community.",
                        actionTitle: "Add Member"
                    ) {
                        showingAddMember = true
                    }
                } else {
                    List {
                        ForEach(filteredMembers) { member in
                            MemberRow(member: member)
                                .onTapGesture {
                                    selectedMember = member
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .background(theme.colors.background)
            .navigationTitle("Members")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showingAddMember = true
                    }
                    .buttonStyle(CareSphereButtonStyle.tertiary)
                }
            }
            .sheet(isPresented: $showingAddMember) {
                AddMemberView()
            }
            .sheet(item: $selectedMember) { member in
                MemberDetailView(member: member)
            }
            .task {
                if memberService.members.isEmpty {
                    try? await memberService.loadMembers()
                }
            }
        }
    }

    private var filteredMembers: [Member] {
        if searchText.isEmpty {
            return memberService.members
        } else {
            return memberService.members.filter { member in
                member.fullName.localizedCaseInsensitiveContains(searchText)
                    || member.email?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }

    private func searchMembers() async {
        guard !searchText.isEmpty else {
            try? await memberService.loadMembers()
            return
        }

        try? await memberService.searchMembers(query: searchText)
    }
}

struct MemberRow: View {
    @EnvironmentObject private var theme: CareSphereTheme
    let member: Member

    var body: some View {
        HStack(spacing: CareSphereSpacing.md) {
            CareSphereAvatar(
                imageURL: member.profileImageURL.flatMap { URL(string: $0) },
                name: member.fullName
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(member.fullName)
                    .font(CareSphereTypography.bodyMedium)
                    .foregroundColor(theme.colors.onBackground)

                if let email = member.email {
                    Text(email)
                        .font(CareSphereTypography.bodySmall)
                        .foregroundColor(theme.colors.onSurface.opacity(0.7))
                }

                if let lastContact = member.lastContactDate {
                    Text("Last contact: \(lastContact, style: .relative)")
                        .font(CareSphereTypography.caption)
                        .foregroundColor(theme.colors.onSurface.opacity(0.6))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                CareSphereStatusBadge(
                    member.status.displayName,
                    color: statusColor(for: member.status),
                    size: .small
                )

                if !member.tags.isEmpty {
                    Text("\(member.tags.count) tag\(member.tags.count == 1 ? "" : "s")")
                        .font(CareSphereTypography.caption)
                        .foregroundColor(theme.colors.onSurface.opacity(0.6))
                }
            }
        }
        .padding(.vertical, CareSphereSpacing.xs)
    }

    private func statusColor(for status: MemberStatus) -> CareSphereStatusBadge.StatusColor {
        switch status {
        case .active: return .success
        case .inactive: return .secondary
        case .needsFollowUp: return .warning
        case .archived: return .secondary
        case .new: return .primary
        }
    }
}

/// Messages management view
struct MessagesView: View {
    @EnvironmentObject private var theme: CareSphereTheme
    @EnvironmentObject private var messageService: MessageService

    @State private var showingComposer = false

    var body: some View {
        NavigationView {
            VStack {
                if messageService.isLoading {
                    CareSphereLoadingView("Loading messages...")
                } else if messageService.messages.isEmpty {
                    CareSphereEmptyState(
                        icon: "envelope",
                        title: "No Messages Yet",
                        description: "Send your first message to connect with your community.",
                        actionTitle: "Compose Message"
                    ) {
                        showingComposer = true
                    }
                } else {
                    List {
                        ForEach(messageService.messages) { message in
                            MessageRow(message: message)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .background(theme.colors.background)
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Compose") {
                        showingComposer = true
                    }
                    .buttonStyle(CareSphereButtonStyle.tertiary)
                }
            }
            .sheet(isPresented: $showingComposer) {
                MessageComposerView()
            }
            .task {
                if messageService.messages.isEmpty {
                    try? await messageService.loadMessages()
                }
            }
        }
    }
}

struct MessageRow: View {
    @EnvironmentObject private var theme: CareSphereTheme
    let message: Message

    var body: some View {
        VStack(alignment: .leading, spacing: CareSphereSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    if let subject = message.subject {
                        Text(subject)
                            .font(CareSphereTypography.bodyMedium)
                            .foregroundColor(theme.colors.onBackground)
                    }

                    Text(message.content)
                        .font(CareSphereTypography.bodySmall)
                        .foregroundColor(theme.colors.onSurface.opacity(0.7))
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    CareSphereStatusBadge(
                        message.status.displayName,
                        color: statusColor(for: message.status),
                        size: .small
                    )

                    Text("\(message.recipientCount) recipients")
                        .font(CareSphereTypography.caption)
                        .foregroundColor(theme.colors.onSurface.opacity(0.6))
                }
            }

            HStack {
                Image(systemName: message.channel.icon)
                    .foregroundColor(theme.colors.primary)

                Text(message.channel.displayName)
                    .font(CareSphereTypography.caption)
                    .foregroundColor(theme.colors.onSurface.opacity(0.6))

                Spacer()

                if let sentAt = message.sentAt {
                    Text(sentAt, style: .relative)
                        .font(CareSphereTypography.caption)
                        .foregroundColor(theme.colors.onSurface.opacity(0.6))
                } else {
                    Text(message.createdAt, style: .relative)
                        .font(CareSphereTypography.caption)
                        .foregroundColor(theme.colors.onSurface.opacity(0.6))
                }
            }
        }
        .padding(.vertical, CareSphereSpacing.xs)
    }

    private func statusColor(for status: MessageStatus) -> CareSphereStatusBadge.StatusColor {
        switch status {
        case .sent: return .success
        case .failed: return .error
        case .scheduled: return .primary
        case .sending: return .warning
        case .draft: return .secondary
        case .cancelled: return .secondary
        }
    }
}

/// Analytics view
struct AnalyticsView: View {
    @EnvironmentObject private var theme: CareSphereTheme

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: CareSphereSpacing.lg) {
                    // Period selector
                    periodSelector

                    // Key metrics
                    keyMetricsSection

                    // Charts placeholder
                    chartsSection
                }
                .padding(CareSphereSpacing.lg)
            }
            .background(theme.colors.background)
            .navigationTitle("Analytics")
        }
    }

    private var periodSelector: some View {
        CareSphereCard {
            VStack(alignment: .leading, spacing: CareSphereSpacing.md) {
                Text("Time Period")
                    .font(CareSphereTypography.titleSmall)
                    .foregroundColor(theme.colors.onBackground)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: CareSphereSpacing.sm) {
                        ForEach(AnalyticsPeriod.allCases.prefix(6), id: \.rawValue) { period in
                            Button(period.displayName) {
                                // Select period
                            }
                            .buttonStyle(CareSphereButtonStyle.secondary)
                        }
                    }
                    .padding(.horizontal, CareSphereSpacing.sm)
                }
            }
        }
    }

    private var keyMetricsSection: some View {
        VStack(alignment: .leading, spacing: CareSphereSpacing.md) {
            Text("Key Metrics")
                .font(CareSphereTypography.titleMedium)
                .foregroundColor(theme.colors.onBackground)
                .padding(.horizontal, CareSphereSpacing.sm)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 2),
                spacing: CareSphereSpacing.md
            ) {
                MetricCard(
                    title: "Member Growth",
                    value: "+12",
                    percentage: "+8.3%",
                    icon: "arrow.up.right",
                    color: .success
                )

                MetricCard(
                    title: "Message Delivery",
                    value: "94.2%",
                    percentage: "+2.1%",
                    icon: "arrow.up.right",
                    color: .success
                )

                MetricCard(
                    title: "Engagement Rate",
                    value: "76.4%",
                    percentage: "-1.2%",
                    icon: "arrow.down.right",
                    color: .warning
                )

                MetricCard(
                    title: "Response Time",
                    value: "2.3h",
                    percentage: "-15%",
                    icon: "arrow.down.right",
                    color: .success
                )
            }
        }
    }

    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: CareSphereSpacing.md) {
            Text("Trends")
                .font(CareSphereTypography.titleMedium)
                .foregroundColor(theme.colors.onBackground)
                .padding(.horizontal, CareSphereSpacing.sm)

            CareSphereCard {
                VStack(alignment: .leading, spacing: CareSphereSpacing.md) {
                    Text("Member Growth Over Time")
                        .font(CareSphereTypography.titleSmall)
                        .foregroundColor(theme.colors.onBackground)

                    // Chart placeholder
                    RoundedRectangle(cornerRadius: CareSphereRadius.md)
                        .fill(theme.colors.primary.opacity(0.1))
                        .frame(height: 200)
                        .overlay(
                            Text("Chart Coming Soon")
                                .font(CareSphereTypography.bodyMedium)
                                .foregroundColor(theme.colors.onSurface.opacity(0.7))
                        )
                }
            }

            CareSphereCard {
                VStack(alignment: .leading, spacing: CareSphereSpacing.md) {
                    Text("Message Performance")
                        .font(CareSphereTypography.titleSmall)
                        .foregroundColor(theme.colors.onBackground)

                    // Chart placeholder
                    RoundedRectangle(cornerRadius: CareSphereRadius.md)
                        .fill(theme.colors.secondary.opacity(0.1))
                        .frame(height: 200)
                        .overlay(
                            Text("Chart Coming Soon")
                                .font(CareSphereTypography.bodyMedium)
                                .foregroundColor(theme.colors.onSurface.opacity(0.7))
                        )
                }
            }
        }
    }
}

struct MetricCard: View {
    @EnvironmentObject private var theme: CareSphereTheme
    let title: String
    let value: String
    let percentage: String
    let icon: String
    let color: CareSphereStatusBadge.StatusColor

    var body: some View {
        CareSphereCard(padding: CareSphereSpacing.md) {
            VStack(alignment: .leading, spacing: CareSphereSpacing.sm) {
                HStack {
                    Text(title)
                        .font(CareSphereTypography.bodySmall)
                        .foregroundColor(theme.colors.onSurface.opacity(0.7))

                    Spacer()

                    Image(systemName: icon)
                        .foregroundColor(color.color(in: theme))
                }

                Text(value)
                    .font(CareSphereTypography.headlineSmall)
                    .foregroundColor(theme.colors.onBackground)

                Text(percentage)
                    .font(CareSphereTypography.caption)
                    .foregroundColor(color.color(in: theme))
            }
        }
    }
}

/// Settings view
struct SettingsView: View {
    @EnvironmentObject private var theme: CareSphereTheme
    @EnvironmentObject private var authService: AuthenticationService

    var body: some View {
        NavigationView {
            Form {
                Section("Profile") {
                    HStack {
                        CareSphereAvatar(
                            imageURL: authService.currentUser?.avatarUrl.flatMap {
                                URL(string: $0)
                            },
                            name: authService.currentUser?.fullName ?? "User",
                            size: 50
                        )

                        VStack(alignment: .leading) {
                            Text(authService.currentUser?.fullName ?? "Unknown User")
                                .font(CareSphereTypography.bodyMedium)

                            Text(authService.currentUser?.email ?? "")
                                .font(CareSphereTypography.bodySmall)
                                .foregroundColor(theme.colors.onSurface.opacity(0.7))
                        }

                        Spacer()
                    }
                    .padding(.vertical, CareSphereSpacing.xs)
                }

                Section("Appearance") {
                    Picker("Color Scheme", selection: .constant(theme.currentColorScheme)) {
                        Text("Light").tag(ColorScheme.light)
                        Text("Dark").tag(ColorScheme.dark)
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(theme.colors.onSurface.opacity(0.7))
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text("2025.1")
                            .foregroundColor(theme.colors.onSurface.opacity(0.7))
                    }
                }

                Section {
                    Button("Sign Out") {
                        Task {
                            await authService.logout()
                        }
                    }
                    .foregroundColor(CareSphereColors.error)
                }
            }
            .background(theme.colors.background)
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Placeholder Views

struct AddMemberView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Text("Add Member Form")
                .navigationTitle("Add Member")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct MemberDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let member: Member

    var body: some View {
        NavigationView {
            Text("Member Detail: \(member.fullName)")
                .navigationTitle(member.fullName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct MessageComposerView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Text("Message Composer")
                .navigationTitle("Compose Message")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Send") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview("Members") {
    MembersView()
        .environmentObject(CareSphereTheme.shared)
        .environmentObject(MemberService.shared)
}

#Preview("Messages") {
    MessagesView()
        .environmentObject(CareSphereTheme.shared)
        .environmentObject(MessageService.shared)
}

#Preview("Analytics") {
    AnalyticsView()
        .environmentObject(CareSphereTheme.shared)
}

#Preview("Settings") {
    SettingsView()
        .environmentObject(CareSphereTheme.shared)
        .environmentObject(AuthenticationService.shared)
}
