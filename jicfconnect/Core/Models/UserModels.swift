import Foundation

// MARK: - User Management Models

/// User model representing authenticated users in the system
struct User: Codable, Identifiable, Equatable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let role: UserRole
    let organizationId: String
    let isActive: Bool
    let profileImageURL: String?
    let phoneNumber: String?
    let createdAt: Date
    let updatedAt: Date
    let lastLoginAt: Date?
    
    // Computed properties
    var fullName: String {
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    
    var displayName: String {
        return fullName.isEmpty ? email : fullName
    }
}

/// User roles with associated permissions
enum UserRole: String, Codable, CaseIterable {
    case superAdmin = "super_admin"
    case admin = "admin"
    case ministryLeader = "ministry_leader"
    case volunteer = "volunteer"
    case member = "member"
    
    var displayName: String {
        switch self {
        case .superAdmin:
            return "Super Admin"
        case .admin:
            return "Admin"
        case .ministryLeader:
            return "Ministry Leader"
        case .volunteer:
            return "Volunteer"
        case .member:
            return "Member"
        }
    }
    
    var permissions: UserPermissions {
        switch self {
        case .superAdmin:
            return UserPermissions.all
        case .admin:
            return UserPermissions.admin
        case .ministryLeader:
            return UserPermissions.ministryLeader
        case .volunteer:
            return UserPermissions.volunteer
        case .member:
            return UserPermissions.member
        }
    }
}

/// Fine-grained permission system
struct UserPermissions: Codable, Equatable {
    let manageUsers: Bool
    let manageMembers: Bool
    let sendMessages: Bool
    let viewAnalytics: Bool
    let manageAutomation: Bool
    let manageTemplates: Bool
    let manageOrganization: Bool
    let exportData: Bool
    let deleteData: Bool
    
    static let all = UserPermissions(
        manageUsers: true,
        manageMembers: true,
        sendMessages: true,
        viewAnalytics: true,
        manageAutomation: true,
        manageTemplates: true,
        manageOrganization: true,
        exportData: true,
        deleteData: true
    )
    
    static let admin = UserPermissions(
        manageUsers: true,
        manageMembers: true,
        sendMessages: true,
        viewAnalytics: true,
        manageAutomation: true,
        manageTemplates: true,
        manageOrganization: false,
        exportData: true,
        deleteData: true
    )
    
    static let ministryLeader = UserPermissions(
        manageUsers: false,
        manageMembers: true,
        sendMessages: true,
        viewAnalytics: true,
        manageAutomation: true,
        manageTemplates: true,
        manageOrganization: false,
        exportData: false,
        deleteData: false
    )
    
    static let volunteer = UserPermissions(
        manageUsers: false,
        manageMembers: false,
        sendMessages: true,
        viewAnalytics: false,
        manageAutomation: false,
        manageTemplates: true,
        manageOrganization: false,
        exportData: false,
        deleteData: false
    )
    
    static let member = UserPermissions(
        manageUsers: false,
        manageMembers: false,
        sendMessages: false,
        viewAnalytics: false,
        manageAutomation: false,
        manageTemplates: false,
        manageOrganization: false,
        exportData: false,
        deleteData: false
    )
}

// MARK: - Organization Models

/// Organization/tenant model for multi-tenant support
struct Organization: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let slug: String  // Unique identifier for URLs
    let description: String?
    let logoURL: String?
    let website: String?
    let primaryColor: String?
    let secondaryColor: String?
    let settings: OrganizationSettings
    let subscription: SubscriptionPlan
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
}

/// Organization-specific settings and preferences
struct OrganizationSettings: Codable, Equatable {
    let defaultLanguage: String
    let defaultTimeZone: String
    let dateFormat: String
    let enabledFeatures: [String]
    let customFields: [String: String]
    let integrationSettings: IntegrationSettings
    let notificationSettings: NotificationSettings
}

/// Third-party integration settings
struct IntegrationSettings: Codable, Equatable {
    let emailProvider: EmailProvider?
    let smsProvider: SMSProvider?
    let whatsappEnabled: Bool
    let googleWorkspaceEnabled: Bool
    let microsoftOfficeEnabled: Bool
    let webhookURL: String?
}

/// Notification preferences
struct NotificationSettings: Codable, Equatable {
    let emailNotifications: Bool
    let pushNotifications: Bool
    let smsNotifications: Bool
    let digestFrequency: DigestFrequency
    let quietHours: QuietHours?
}

enum DigestFrequency: String, Codable, CaseIterable {
    case disabled = "disabled"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
}

struct QuietHours: Codable, Equatable {
    let startTime: String  // HH:mm format
    let endTime: String    // HH:mm format
    let timeZone: String
}

/// Subscription plan information
enum SubscriptionPlan: String, Codable, CaseIterable {
    case free = "free"
    case starter = "starter"
    case professional = "professional"
    case enterprise = "enterprise"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var maxUsers: Int {
        switch self {
        case .free:
            return 5
        case .starter:
            return 25
        case .professional:
            return 100
        case .enterprise:
            return Int.max
        }
    }
    
    var maxMembers: Int {
        switch self {
        case .free:
            return 100
        case .starter:
            return 500
        case .professional:
            return 2500
        case .enterprise:
            return Int.max
        }
    }
}

// MARK: - Provider Enums

enum EmailProvider: String, Codable, CaseIterable {
    case sendgrid = "sendgrid"
    case mailgun = "mailgun"
    case amazonSES = "amazon_ses"
    case smtp = "smtp"
}

enum SMSProvider: String, Codable, CaseIterable {
    case twilio = "twilio"
    case vonage = "vonage"
    case amazonSNS = "amazon_sns"
}

// MARK: - Authentication Models

/// Authentication request/response models
struct LoginRequest: Codable {
    let email: String
    let password: String
    let rememberMe: Bool
}

struct LoginResponse: Codable {
    let user: User
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    let organizationId: String?
    let organizationName: String?  // For creating new organization
}

struct AuthenticationError: Error, LocalizedError {
    let code: String
    let message: String
    
    var errorDescription: String? {
        return message
    }
    
    static let invalidCredentials = AuthenticationError(
        code: "INVALID_CREDENTIALS",
        message: "Invalid email or password"
    )
    
    static let userNotFound = AuthenticationError(
        code: "USER_NOT_FOUND",
        message: "User not found"
    )
    
    static let userInactive = AuthenticationError(
        code: "USER_INACTIVE",
        message: "Account is inactive"
    )
    
    static let organizationInactive = AuthenticationError(
        code: "ORGANIZATION_INACTIVE",
        message: "Organization is inactive"
    )
}

// MARK: - Preview Extensions

extension User {
    static let preview = User(
        id: "preview-user-id",
        email: "demo@caresphere.com",
        firstName: "Demo",
        lastName: "User",
        role: .admin,
        organizationId: "preview-org-id",
        isActive: true,
        profileImageURL: nil,
        phoneNumber: "+1-555-0123",
        createdAt: Date(),
        updatedAt: Date(),
        lastLoginAt: Date()
    )
}