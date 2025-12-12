import SwiftUI

/// Themed progress view with percentage
struct AppProgressView: View {
    let progress: Double
    let message: String
    let themeColor: Color
    
    init(
        progress: Double,
        message: String,
        themeColor: Color
    ) {
        self.progress = progress
        self.message = message
        self.themeColor = themeColor
    }
    
    var body: some View {
        VStack(spacing: AppDesignSystem.Spacing.md) {
            ProgressView(value: progress, total: 1.0)
                .tint(themeColor)
                .padding(.horizontal)
            
            Text("\(message): \(Int(progress * 100))%")
                .font(.caption)
                .foregroundColor(themeColor)
        }
    }
}

/// Simple loading indicator
struct AppLoadingView: View {
    let message: String
    
    init(message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text(message)
                .foregroundColor(AppDesignSystem.Colors.textSecondary)
                .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(AppDesignSystem.CornerRadius.medium)
    }
}
