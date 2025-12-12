import SwiftUI

/// Section header with consistent styling
struct AppSectionHeader: View {
    let title: String
    let color: Color?
    
    init(_ title: String, color: Color? = nil) {
        self.title = title
        self.color = color
    }
    
    var body: some View {
        Text(title)
            .font(.caption)
            .bold()
            .foregroundColor(color ?? AppDesignSystem.Colors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Section header with accent bar
struct AppSectionHeaderWithBar: View {
    let title: String
    let accentColor: Color
    
    init(_ title: String, accentColor: Color) {
        self.title = title
        self.accentColor = accentColor
    }
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(accentColor)
                .frame(width: 4, height: 16)
                .cornerRadius(2)
            Text(title)
                .font(.headline)
                .foregroundColor(AppDesignSystem.Colors.textDark)
        }
    }
}

/// Subheadline section header (for settings-style UIs)
struct AppSettingsHeader: View {
    let title: String
    let color: Color
    
    init(_ title: String, color: Color = AppDesignSystem.Colors.textSecondary) {
        self.title = title
        self.color = color
    }
    
    var body: some View {
        Text(title)
            .font(.subheadline  )
            .bold()
            .foregroundColor(color)
    }
}
