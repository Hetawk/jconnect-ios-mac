import SwiftUI

/// CareSphere Design System - Color Tokens
/// Single source of truth for all colors used across the application
struct CareSphereColors {
    
    // MARK: - Primary Brand Colors
    static let primaryBlue = Color(red: 0.20, green: 0.48, blue: 0.84)      // #3478D5
    static let primaryBlueLight = Color(red: 0.40, green: 0.63, blue: 0.91) // #669EE8
    static let primaryBlueDark = Color(red: 0.12, green: 0.35, blue: 0.68)  // #1F59AE
    
    // MARK: - Secondary Colors
    static let secondaryGreen = Color(red: 0.22, green: 0.73, blue: 0.41)   // #38BB68
    static let secondaryOrange = Color(red: 0.98, green: 0.55, blue: 0.18)  // #FA8C2E
    static let secondaryPurple = Color(red: 0.61, green: 0.35, blue: 0.85)  // #9B59D9
    
    // MARK: - Semantic Colors
    static let success = Color(red: 0.22, green: 0.73, blue: 0.41)          // #38BB68
    static let warning = Color(red: 0.98, green: 0.55, blue: 0.18)          // #FA8C2E
    static let error = Color(red: 0.91, green: 0.26, blue: 0.27)            // #E84344
    static let info = primaryBlue
    
    // MARK: - Text Colors
    static let textPrimary = Color(red: 0.13, green: 0.13, blue: 0.13)      // #212121
    static let textSecondary = Color(red: 0.46, green: 0.46, blue: 0.46)    // #757575
    static let textTertiary = Color(red: 0.62, green: 0.62, blue: 0.62)     // #9E9E9E
    static let textOnPrimary = Color.white
    
    // MARK: - Background Colors
    static let backgroundPrimary = Color(red: 0.99, green: 0.99, blue: 0.99) // #FAFAFA
    static let backgroundSecondary = Color(red: 0.96, green: 0.96, blue: 0.96) // #F5F5F5
    static let backgroundTertiary = Color.white
    static let backgroundCard = Color.white
    
    // MARK: - Border Colors
    static let borderLight = Color(red: 0.91, green: 0.91, blue: 0.91)      // #E8E8E8
    static let borderMedium = Color(red: 0.84, green: 0.84, blue: 0.84)     // #D6D6D6
    static let borderDark = Color(red: 0.62, green: 0.62, blue: 0.62)       // #9E9E9E
    
    // MARK: - Surface Colors
    static let surfaceElevated = Color.white
    static let surfacePressed = Color(red: 0.93, green: 0.93, blue: 0.93)   // #EEEEEE
    static let surfaceHover = Color(red: 0.96, green: 0.96, blue: 0.96)     // #F5F5F5
    
    // MARK: - Shadow Colors
    static let shadowPrimary = Color.black.opacity(0.08)
    static let shadowSecondary = Color.black.opacity(0.04)
    
    // MARK: - Dark Mode Support (Future)
    // TODO: Implement dark mode color variants
    // These will be added when dark mode support is implemented
}

// MARK: - Semantic Color Extensions
extension CareSphereColors {
    /// Colors for different user roles
    struct UserRoles {
        static let superAdmin = CareSphereColors.primaryBlueDark
        static let admin = CareSphereColors.primaryBlue
        static let ministryLeader = CareSphereColors.secondaryPurple
        static let volunteer = CareSphereColors.secondaryGreen
        static let member = CareSphereColors.textSecondary
    }
    
    /// Colors for different message priorities
    struct MessagePriority {
        static let urgent = CareSphereColors.error
        static let high = CareSphereColors.warning
        static let normal = CareSphereColors.primaryBlue
        static let low = CareSphereColors.textSecondary
    }
    
    /// Colors for different member status
    struct MemberStatus {
        static let active = CareSphereColors.success
        static let inactive = CareSphereColors.textSecondary
        static let needsFollowUp = CareSphereColors.warning
        static let archived = CareSphereColors.borderMedium
    }
}