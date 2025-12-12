import SwiftUI

// MARK: - Primary Button Style

struct AppPrimaryButtonStyle: ButtonStyle {
    let themeColor: Color
    let isDisabled: Bool
    
    init(themeColor: Color, isDisabled: Bool = false) {
        self.themeColor = themeColor
        self.isDisabled = isDisabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: AppDesignSystem.ButtonHeight.medium)
            .background(isDisabled ? Color.gray : themeColor)
            .cornerRadius(AppDesignSystem.CornerRadius.large)
            .shadow(
                color: themeColor.opacity(0.3),
                radius: 5,
                x: 0,
                y: 3
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style

struct AppSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(AppDesignSystem.Colors.backgroundWhite)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesignSystem.CornerRadius.medium)
                    .stroke(AppDesignSystem.Colors.dividerGray, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .cornerRadius(AppDesignSystem.CornerRadius.medium)
    }
}

// MARK: - Print Button Style

struct AppPrintButtonStyle: ButtonStyle {
    let isDisabled: Bool
    
    init(isDisabled: Bool = false) {
        self.isDisabled = isDisabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: AppDesignSystem.ButtonHeight.large)
            .background(isDisabled ? Color.gray : Color.black.opacity(0.8))
            .cornerRadius(AppDesignSystem.CornerRadius.xxLarge)
            .shadow(radius: 5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Convenience Button Views

struct AppPrimaryButton: View {
    let title: String
    let icon: String?
    let themeColor: Color
    let isDisabled: Bool
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        themeColor: Color,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.themeColor = themeColor
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
        }
        .buttonStyle(AppPrimaryButtonStyle(themeColor: themeColor, isDisabled: isDisabled))
        .disabled(isDisabled)
    }
}

struct AppPrintButton: View {
    let title: String
    let isDisabled: Bool
    let action: () -> Void
    
    init(
        _ title: String = "PRINT NOW",
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "printer.fill")
                Text(title)
                    .fontWeight(.bold)
            }
        }
        .buttonStyle(AppPrintButtonStyle(isDisabled: isDisabled))
        .disabled(isDisabled)
    }
}
