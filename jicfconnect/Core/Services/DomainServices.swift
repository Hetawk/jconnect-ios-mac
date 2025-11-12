import Combine
import Foundation

// MARK: - Authentication Service

/// Service for handling user authentication and session management
@MainActor
class AuthenticationService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: APIError?

    private let networkClient: NetworkClient
    private var cancellables = Set<AnyCancellable>()

    init(networkClient: NetworkClient = .shared) {
        self.networkClient = networkClient

        // Check if user is already authenticated
        if networkClient.isAuthenticated {
            Task {
                await loadCurrentUser()
            }
        }
    }

    // MARK: - Authentication Methods

    func login(email: String, password: String, rememberMe: Bool = true) async throws {
        isLoading = true
        error = nil

        defer { isLoading = false }

        let request = LoginRequest(email: email, password: password, rememberMe: rememberMe)

        let response: LoginResponse = try await networkClient.request(
            endpoint: Endpoints.Auth.login,
            method: .POST,
            body: request
        )

        // Store authentication tokens
        networkClient.setAuthToken(response.token, refreshToken: response.refreshToken)

        // Set current user
        currentUser = response.user
        isAuthenticated = true
    }

    func register(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        organizationId: String? = nil,
        organizationName: String? = nil
    ) async throws {
        isLoading = true
        error = nil

        defer { isLoading = false }

        let request = RegisterRequest(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
            organizationId: organizationId,
            organizationName: organizationName
        )

        let response: LoginResponse = try await networkClient.request(
            endpoint: Endpoints.Auth.register,
            method: .POST,
            body: request
        )

        // Store authentication tokens
        networkClient.setAuthToken(response.token, refreshToken: response.refreshToken)

        // Set current user
        currentUser = response.user
        isAuthenticated = true
    }

    // Convenience method for full name
    func register(fullName: String, email: String, password: String) async throws {
        let names = fullName.split(separator: " ")
        let firstName = String(names.first ?? "")
        let lastName = names.count > 1 ? String(names[1...].joined(separator: " ")) : ""

        try await register(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName
        )
    }

    func logout() async {
        isLoading = true
        defer { isLoading = false }

        // Call logout endpoint (fire and forget)
        do {
            let _: EmptyResponse = try await networkClient.request<EmptyResponse>(
                endpoint: Endpoints.Auth.logout,
                method: .POST
            )
        } catch {
            // We can log this error but don't block logout flow
            #if DEBUG
                print("Logout request failed: \(error)")
            #endif
        }

        // Clear local state
        networkClient.clearAuthTokens()
        currentUser = nil
        isAuthenticated = false
    }

    func refreshToken() async throws {
        // This would be called automatically by NetworkClient
        // when a 401 response is received
    }

    func checkAuthenticationState() async {
        // Check if we have stored tokens and validate them
        await loadCurrentUser()
    }

    func loadCurrentUser() async {
        guard networkClient.isAuthenticated else {
            isAuthenticated = false
            return
        }

        do {
            let user: User = try await networkClient.request<User>(endpoint: Endpoints.Auth.profile)
            currentUser = user
            isAuthenticated = true
        } catch {
            // If profile load fails, user is not authenticated
            networkClient.clearAuthTokens()
            currentUser = nil
            isAuthenticated = false
            self.error = error as? APIError
        }
    }

    // MARK: - Permission Checking

    func hasPermission(_ permission: KeyPath<UserPermissions, Bool>) -> Bool {
        guard let user = currentUser else { return false }
        return user.role.permissions[keyPath: permission]
    }

    func requiresPermission(_ permission: KeyPath<UserPermissions, Bool>) throws {
        guard hasPermission(permission) else {
            throw APIError.forbidden
        }
    }
}

// MARK: - Member Service

/// Service for member management operations
@MainActor
class MemberService: ObservableObject {
    @Published var members: [Member] = []
    @Published var selectedMember: Member?
    @Published var isLoading = false
    @Published var error: APIError?

    private var networkClient: NetworkClient
    private var authService: AuthenticationService

    init(networkClient: NetworkClient = .shared, authService: AuthenticationService) {
        self.networkClient = networkClient
        self.authService = authService
    }

    func updateAuthService(_ authService: AuthenticationService) {
        self.authService = authService
        // Update networkClient if needed to use new auth service
    }

    // MARK: - Member CRUD Operations

    func loadMembers(searchCriteria: MemberSearchCriteria? = nil) async throws {
        try authService.requiresPermission(\.manageMembers)

        isLoading = true
        error = nil
        defer { isLoading = false }

        let response: MemberListResponse

        if let criteria = searchCriteria {
            response =
                try await networkClient.request(
                    endpoint: Endpoints.Members.search,
                    method: .POST,
                    body: criteria
                ) as MemberListResponse
        } else {
            response =
                try await networkClient.request<MemberListResponse>(
                    endpoint: Endpoints.Members.list)
        }

        members = response.members
    }

    func searchMembers(query: String) async throws {
        let criteria = MemberSearchCriteria(
            query: query,
            status: nil,
            tags: nil,
            ageRange: nil,
            lastContactRange: nil,
            joinDateRange: nil,
            hasEmail: nil,
            hasPhone: nil,
            householdId: nil,
            sortBy: .firstName,
            sortOrder: .ascending,
            page: 1,
            pageSize: 50
        )
        try await loadMembers(searchCriteria: criteria)
    }

    func getMember(id: String) async throws -> Member {
        try authService.requiresPermission(\.manageMembers)

        let member: Member = try await networkClient.request<Member>(
            endpoint: Endpoints.Members.get(id: id)
        )

        selectedMember = member
        return member
    }

    func createMember(_ request: CreateMemberRequest) async throws -> Member {
        try authService.requiresPermission(\.manageMembers)

        let member: Member = try await networkClient.request<Member>(
            endpoint: Endpoints.Members.create,
            method: .POST,
            body: request
        )

        // Add to local list if loaded
        if !members.isEmpty {
            members.append(member)
        }

        return member
    }

    func updateMember(id: String, request: UpdateMemberRequest) async throws -> Member {
        try authService.requiresPermission(\.manageMembers)

        let member: Member = try await networkClient.request<Member>(
            endpoint: Endpoints.Members.update(id: id),
            method: .PUT,
            body: request
        )

        // Update local list
        if let index = members.firstIndex(where: { $0.id == id }) {
            members[index] = member
        }

        if selectedMember?.id == id {
            selectedMember = member
        }

        return member
    }

    func deleteMember(id: String) async throws {
        try authService.requiresPermission(\.manageMembers)

        let _: EmptyResponse =
            try await networkClient.request<EmptyResponse>(
                endpoint: Endpoints.Members.delete(id: id),
                method: .DELETE
            )

        // Remove from local list
        members.removeAll { $0.id == id }

        if selectedMember?.id == id {
            selectedMember = nil
        }
    }

    // MARK: - Member Notes and Activities

    func loadMemberNotes(memberId: String) async throws -> [MemberNote] {
        try authService.requiresPermission(\.manageMembers)

        return try await networkClient.request<[MemberNote]>(
            endpoint: Endpoints.Members.notes(memberId: memberId)
        )
    }

    func addMemberNote(
        memberId: String, content: String, category: NoteCategory, isPrivate: Bool = false
    ) async throws -> MemberNote {
        try authService.requiresPermission(\.manageMembers)

        let request = CreateMemberNoteRequest(
            content: content,
            category: category,
            isPrivate: isPrivate
        )

        return try await networkClient.request<MemberNote>(
            endpoint: Endpoints.Members.notes(memberId: memberId),
            method: .POST,
            body: request
        )
    }

    func loadMemberActivities(memberId: String) async throws -> [MemberActivity] {
        try authService.requiresPermission(\.manageMembers)

        return try await networkClient.request<[MemberActivity]>(
            endpoint: Endpoints.Members.activities(memberId: memberId)
        )
    }

    // MARK: - Convenience Methods

    func updateMemberStatus(id: String, status: MemberStatus) async throws {
        let request = UpdateMemberRequest(
            firstName: nil,
            lastName: nil,
            email: nil,
            phoneNumber: nil,
            whatsAppNumber: nil,
            weChatID: nil,
            dateOfBirth: nil,
            address: nil,
            status: status,
            tags: nil,
            customFields: nil,
            emergencyContact: nil,
            householdId: nil
        )

        _ = try await updateMember(id: id, request: request)
    }
}

// MARK: - Message Service

/// Service for message management and communication
@MainActor
class MessageService: ObservableObject {
    @Published var messages: [Message] = []
    @Published var templates: [MessageTemplate] = []
    @Published var isLoading = false
    @Published var error: APIError?

    private var networkClient: NetworkClient
    private var authService: AuthenticationService

    init(networkClient: NetworkClient = .shared, authService: AuthenticationService) {
        self.networkClient = networkClient
        self.authService = authService
    }

    func updateAuthService(_ authService: AuthenticationService) {
        self.authService = authService
        // Update networkClient if needed to use new auth service
    }

    // MARK: - Message Operations

    func loadMessages(searchCriteria: MessageSearchCriteria? = nil) async throws {
        try authService.requiresPermission(\.sendMessages)

        isLoading = true
        error = nil
        defer { isLoading = false }

        let response: MessageListResponse

        if let criteria = searchCriteria {
            // Implementation would use search endpoint
            response =
                try await networkClient.request<MessageListResponse>(
                    endpoint: Endpoints.Messages.list)
        } else {
            response =
                try await networkClient.request<MessageListResponse>(
                    endpoint: Endpoints.Messages.list)
        }

        messages = response.messages
    }

    func createMessage(_ request: CreateMessageRequest) async throws -> Message {
        try authService.requiresPermission(\.sendMessages)

        let message: Message = try await networkClient.request<Message>(
            endpoint: Endpoints.Messages.create,
            method: .POST,
            body: request
        )

        // Add to local list
        if !messages.isEmpty {
            messages.insert(message, at: 0)
        }

        return message
    }

    func sendMessage(id: String) async throws -> Message {
        try authService.requiresPermission(\.sendMessages)

        let message: Message =
            try await networkClient.request<Message>(
                endpoint: Endpoints.Messages.send(id: id),
                method: .POST
            )

        // Update local list
        if let index = messages.firstIndex(where: { $0.id == id }) {
            messages[index] = message
        }

        return message
    }

    func getMessageAnalytics(id: String) async throws -> MessageAnalytics {
        try authService.requiresPermission(\.viewAnalytics)

        return try await networkClient.request<MessageAnalytics>(
            endpoint: Endpoints.Messages.analytics(id: id)
        )
    }

    // MARK: - Template Operations

    func loadTemplates() async throws {
        try authService.requiresPermission(\.manageTemplates)

        templates =
            try await networkClient.request<[MessageTemplate]>(endpoint: Endpoints.Templates.list)
    }

    func createTemplate(_ request: CreateTemplateRequest) async throws -> MessageTemplate {
        try authService.requiresPermission(\.manageTemplates)

        let template: MessageTemplate =
            try await networkClient.request<MessageTemplate>(
                endpoint: Endpoints.Templates.create,
                method: .POST,
                body: request
            )

        templates.append(template)
        return template
    }

    // MARK: - Convenience Methods

    func createAndSendMessage(
        to members: [Member],
        subject: String?,
        content: String,
        channel: MessageChannel,
        priority: MessagePriority = .normal,
        templateId: String? = nil
    ) async throws -> Message {

        let recipients = members.compactMap { member -> RecipientRequest? in
            let contactInfo: ContactInfo

            switch channel {
            case .email:
                guard let email = member.email else { return nil }
                contactInfo = ContactInfo(
                    email: email, phoneNumber: nil, whatsappNumber: nil, pushToken: nil,
                    name: member.fullName)
            case .sms:
                guard let phone = member.phoneNumber else { return nil }
                contactInfo = ContactInfo(
                    email: nil, phoneNumber: phone, whatsappNumber: nil, pushToken: nil,
                    name: member.fullName)
            case .whatsapp:
                guard let whatsapp = member.whatsAppNumber else { return nil }
                contactInfo = ContactInfo(
                    email: nil, phoneNumber: nil, whatsappNumber: whatsapp, pushToken: nil,
                    name: member.fullName)
            default:
                return nil
            }

            return RecipientRequest(
                memberId: member.id,
                recipientType: .member,
                contactInfo: contactInfo
            )
        }

        let request = CreateMessageRequest(
            subject: subject,
            content: content,
            messageType: .broadcast,
            priority: priority,
            channel: channel,
            templateId: templateId,
            recipients: recipients,
            scheduledAt: nil,
            templateVariables: nil
        )

        let message = try await createMessage(request)
        return try await sendMessage(id: message.id)
    }
}

// MARK: - Supporting Models

struct EmptyResponse: Codable {
    // Used for endpoints that don't return data
}

struct CreateMemberNoteRequest: Codable {
    let content: String
    let category: NoteCategory
    let isPrivate: Bool
}

struct CreateTemplateRequest: Codable {
    let name: String
    let description: String?
    let category: TemplateCategory
    let subject: String?
    let content: String
    let placeholders: [TemplatePlaceholder]
    let supportedChannels: [MessageChannel]
}
