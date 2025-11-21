import SwiftUI

/// Message composer view with template selection, recipient selection, and channel options
struct MessageComposerView: View {
    @EnvironmentObject private var theme: CareSphereTheme
    @EnvironmentObject private var messageService: MessageService
    @EnvironmentObject private var memberService: MemberService
    @Environment(\.dismiss) private var dismiss

    // Optional pre-selected template
    let selectedTemplate: MessageTemplate?

    // Form state
    @State private var templateId: String?
    @State private var selectedChannel: MessageChannel = .email
    @State private var subject: String = ""
    @State private var content: String = ""
    @State private var selectedMembers: Set<String> = []
    @State private var priority: MessagePriority = .normal
    @State private var showingTemplateSelector = false
    @State private var showingMemberSelector = false
    @State private var isSending = false
    @State private var showError = false
    @State private var errorMessage = ""

    init(selectedTemplate: MessageTemplate? = nil) {
        self.selectedTemplate = selectedTemplate
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: CareSphereSpacing.lg) {
                    // Template selection
                    templateSection

                    // Channel selection
                    channelSection

                    // Recipients
                    recipientsSection

                    // Subject (for email)
                    if selectedChannel == .email {
                        subjectSection
                    }

                    // Content
                    contentSection

                    // Priority
                    prioritySection
                }
                .padding(CareSphereSpacing.lg)
            }
            .background(theme.colors.background)
            .navigationTitle("Compose Message")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(theme.colors.surface, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(
                    theme.currentColorScheme == .dark ? .dark : .light, for: .navigationBar
                )
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .primaryAction) {
                        Button(isSending ? "Sending..." : "Send") {
                            Task { await sendMessage() }
                        }
                        .disabled(isSending || selectedMembers.isEmpty || content.isEmpty)
                        .buttonStyle(CareSphereButtonStyle.primary)
                    }
                }
            #endif
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingMemberSelector) {
                MemberSelectorView(selectedMembers: $selectedMembers)
                    .environmentObject(theme)
                    .environmentObject(memberService)
            }
            .onAppear {
                if let template = selectedTemplate {
                    applyTemplate(template)
                }
            }
        }
    }

    private var templateSection: some View {
        CareSphereCard {
            VStack(alignment: .leading, spacing: CareSphereSpacing.md) {
                Text("Template")
                    .font(CareSphereTypography.titleSmall)
                    .foregroundColor(theme.colors.onBackground)

                if let template = selectedTemplate {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.name)
                                .font(CareSphereTypography.bodyMedium)
                                .foregroundColor(theme.colors.onBackground)

                            Text(template.category.displayName)
                                .font(CareSphereTypography.labelSmall)
                                .foregroundColor(theme.colors.onSurface.opacity(0.6))
                        }

                        Spacer()

                        Button("Change") {
                            showingTemplateSelector = true
                        }
                        .buttonStyle(CareSphereButtonStyle.secondary)
                    }
                } else {
                    Button("Select Template (Optional)") {
                        showingTemplateSelector = true
                    }
                    .buttonStyle(CareSphereButtonStyle.secondary)
                }
            }
        }
    }

    private var channelSection: some View {
        CareSphereCard {
            VStack(alignment: .leading, spacing: CareSphereSpacing.md) {
                Text("Channel")
                    .font(CareSphereTypography.titleSmall)
                    .foregroundColor(theme.colors.onBackground)

                HStack(spacing: CareSphereSpacing.sm) {
                    channelButton(.email, icon: "envelope.fill", label: "Email")
                    channelButton(.sms, icon: "message.fill", label: "SMS")
                    channelButton(
                        .whatsapp, icon: "bubble.left.and.bubble.right.fill", label: "WhatsApp")
                }
            }
        }
    }

    private func channelButton(_ channel: MessageChannel, icon: String, label: String) -> some View
    {
        Button {
            selectedChannel = channel
        } label: {
            VStack(spacing: CareSphereSpacing.xs) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(CareSphereTypography.labelSmall)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, CareSphereSpacing.sm)
            .background(
                selectedChannel == channel
                    ? theme.colors.primary.opacity(0.1)
                    : theme.colors.surface
            )
            .foregroundColor(
                selectedChannel == channel
                    ? theme.colors.primary
                    : theme.colors.onSurface.opacity(0.7)
            )
            .cornerRadius(CareSphereRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CareSphereRadius.md)
                    .stroke(
                        selectedChannel == channel
                            ? theme.colors.primary
                            : theme.colors.onSurface.opacity(0.2),
                        lineWidth: selectedChannel == channel ? 2 : 1
                    )
            )
        }
    }

    private var recipientsSection: some View {
        CareSphereCard {
            VStack(alignment: .leading, spacing: CareSphereSpacing.md) {
                HStack {
                    Text("Recipients")
                        .font(CareSphereTypography.titleSmall)
                        .foregroundColor(theme.colors.onBackground)

                    Spacer()

                    Text("\(selectedMembers.count) selected")
                        .font(CareSphereTypography.labelSmall)
                        .foregroundColor(theme.colors.onSurface.opacity(0.6))
                }

                Button("Select Members") {
                    showingMemberSelector = true
                }
                .buttonStyle(CareSphereButtonStyle.secondary)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var subjectSection: some View {
        CareSphereCard {
            VStack(alignment: .leading, spacing: CareSphereSpacing.sm) {
                Text("Subject")
                    .font(CareSphereTypography.titleSmall)
                    .foregroundColor(theme.colors.onBackground)

                TextField("Enter subject", text: $subject)
                    .textFieldStyle(CareSphereTextFieldStyle())
            }
        }
    }

    private var contentSection: some View {
        CareSphereCard {
            VStack(alignment: .leading, spacing: CareSphereSpacing.sm) {
                Text("Message Content")
                    .font(CareSphereTypography.titleSmall)
                    .foregroundColor(theme.colors.onBackground)

                TextEditor(text: $content)
                    .frame(minHeight: 200)
                    .padding(CareSphereSpacing.sm)
                    .background(theme.colors.surface)
                    .cornerRadius(CareSphereRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: CareSphereRadius.md)
                            .stroke(theme.colors.onSurface.opacity(0.2), lineWidth: 1)
                    )
            }
        }
    }

    private var prioritySection: some View {
        CareSphereCard {
            VStack(alignment: .leading, spacing: CareSphereSpacing.md) {
                Text("Priority")
                    .font(CareSphereTypography.titleSmall)
                    .foregroundColor(theme.colors.onBackground)

                Picker("Priority", selection: $priority) {
                    Text("Low").tag(MessagePriority.low)
                    Text("Normal").tag(MessagePriority.normal)
                    Text("High").tag(MessagePriority.high)
                    Text("Urgent").tag(MessagePriority.urgent)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
    }

    private func applyTemplate(_ template: MessageTemplate) {
        templateId = template.id
        subject = template.subject ?? ""
        content = template.content

        // Set default channel if template supports only one
        if template.supportedChannels.count == 1,
            let channel = template.supportedChannels.first
        {
            selectedChannel = channel
        }
    }

    private func sendMessage() async {
        guard !selectedMembers.isEmpty, !content.isEmpty else { return }

        isSending = true
        defer { isSending = false }

        do {
            // Get selected member objects
            let members = memberService.members.filter { selectedMembers.contains($0.id) }

            // Use MessageService to create and send message
            _ = try await messageService.createAndSendMessage(
                to: members,
                subject: selectedChannel == .email ? subject : nil,
                content: content,
                channel: selectedChannel,
                priority: priority,
                templateId: templateId
            )

            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Member Selector Sheet
struct MemberSelectorView: View {
    @EnvironmentObject private var theme: CareSphereTheme
    @EnvironmentObject private var memberService: MemberService
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedMembers: Set<String>
    @State private var searchText = ""

    var filteredMembers: [Member] {
        memberService.members.filter { member in
            searchText.isEmpty || member.fullName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(filteredMembers) { member in
                    Button {
                        if selectedMembers.contains(member.id) {
                            selectedMembers.remove(member.id)
                        } else {
                            selectedMembers.insert(member.id)
                        }
                    } label: {
                        HStack {
                            Image(
                                systemName: selectedMembers.contains(member.id)
                                    ? "checkmark.circle.fill" : "circle"
                            )
                            .foregroundColor(
                                selectedMembers.contains(member.id)
                                    ? theme.colors.primary : theme.colors.onSurface.opacity(0.3))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(member.fullName)
                                    .font(CareSphereTypography.bodyMedium)
                                    .foregroundColor(theme.colors.onBackground)

                                if let email = member.email {
                                    Text(email)
                                        .font(CareSphereTypography.bodySmall)
                                        .foregroundColor(theme.colors.onSurface.opacity(0.6))
                                }
                            }
                        }
                    }
                    .listRowBackground(theme.colors.surface)
                }
            }
            .listStyle(PlainListStyle())
            .searchable(text: $searchText, prompt: "Search members...")
            .navigationTitle("Select Recipients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(selectedMembers.isEmpty)
                }
            }
        }
    }
}

#Preview {
    MessageComposerView()
        .environmentObject(CareSphereTheme.shared)
        .environmentObject(MessageService.preview)
        .environmentObject(MemberService.preview)
}
