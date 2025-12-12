import SwiftUI

/// Centralized design system for the CatPrinter app
/// Contains all colors, typography, spacing, and styling constants
struct AppDesignSystem {
    
    // MARK: - Colors
    
    /// Theme colors used throughout the app
    struct Colors {
        // Pastel palette
        static let pastelBlue = Color(red: 0.6, green: 0.8, blue: 1.0)
        static let pastelPink = Color(red: 1.0, green: 0.7, blue: 0.75)
        static let pastelPurple = Color(red: 0.8, green: 0.7, blue: 1.0)
        static let pastelMint = Color(red: 0.6, green: 0.9, blue: 0.7)
        static let pastelYellow = Color(red: 1.0, green: 0.9, blue: 0.6)
        static let pastelOrange = Color(red: 1.0, green: 0.8, blue: 0.6)
        static let pastelTeal = Color(red: 0.6, green: 0.9, blue: 0.8)
        
        // Neutral colors
        static let textDark = Color(red: 0.3, green: 0.3, blue: 0.3)
        static let textSecondary = Color.gray
        static let textBlack = Color.black
        
        // Background colors
        static let backgroundLight = Color(red: 0.97, green: 0.97, blue: 0.97)
        static let backgroundWhite = Color.white
        static let backgroundPaper = Color(red: 0.99, green: 0.99, blue: 1.0)
        
        // UI element colors
        static let cardBackground = Color.white
        static let textFieldBackground = Color(red: 0.96, green: 0.96, blue: 0.98)
        static let borderGray = Color.gray.opacity(0.2)
        static let dividerGray = Color.gray.opacity(0.3)
        
        // Semantic colors
        static let success = Color.green
        static let error = Color.red
        static let warning = Color.orange
    }
    
    // MARK: - Typography
    
    struct Typography {
        static let largeTitle = Font.largeTitle
        static let title = Font.title
        static let title2 = Font.title2
        static let title3 = Font.title3
        static let headline = Font.headline
        static let subheadline = Font.subheadline
        static let body = Font.body
        static let callout = Font.callout
        static let caption = Font.caption
        static let caption2 = Font.caption2
    }
    
    // MARK: - Spacing
    
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 20
        static let xxLarge: CGFloat = 28
        static let xxxLarge: CGFloat = 30
    }
    
    // MARK: - Shadows
    
    struct Shadow {
        static func card(color: Color = .black) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (color: color.opacity(0.03), radius: 6, x: 0, y: 0)
        }
        
        static func button(color: Color) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (color: color.opacity(0.3), radius: 5, x: 0, y: 3)
        }
        
        static func light(color: Color = .black) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (color: color.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    // MARK: - Button Heights
    
    struct ButtonHeight {
        static let small: CGFloat = 40
        static let medium: CGFloat = 50
        static let large: CGFloat = 56
    }
}

// MARK: - View Extension for Consistent Theming

extension View {
    /// Apply light color scheme to ensure dark text
    func forceLightMode() -> some View {
        self.environment(\.colorScheme, .light)
    }
}
