import SwiftUI

/// Empty state view with icon and message
struct AppEmptyState: View {
    let icon: String
    let message: String
    let iconColor: Color
    let iconSize: CGFloat
    
    init(
        icon: String,
        message: String,
        iconColor: Color = AppDesignSystem.Colors.textSecondary,
        iconSize: CGFloat = 48
    ) {
        self.icon = icon
        self.message = message
        self.iconColor = iconColor
        self.iconSize = iconSize
    }
    
    var body: some View {
        VStack(spacing: AppDesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: iconSize))
                .foregroundColor(iconColor.opacity(0.5))
            Text(message)
                .font(.subheadline)
                .foregroundColor(AppDesignSystem.Colors.textSecondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
}
