import SwiftUI

/// Styled TextField with consistent theming
struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    let backgroundColor: Color
    let cornerRadius: CGFloat
    
    init(
        _ placeholder: String,
        text: Binding<String>,
        backgroundColor: Color = AppDesignSystem.Colors.textFieldBackground,
        cornerRadius: CGFloat = AppDesignSystem.CornerRadius.medium
    ) {
        self.placeholder = placeholder
        self._text = text
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .forceLightMode()
            .foregroundColor(AppDesignSystem.Colors.textBlack)
    }
}

/// Styled TextEditor with consistent theming
struct AppTextEditor: View {
    @Binding var text: String
    let height: CGFloat
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let borderColor: Color
    
    init(
        text: Binding<String>,
        height: CGFloat = 100,
        backgroundColor: Color = AppDesignSystem.Colors.textFieldBackground,
        cornerRadius: CGFloat = AppDesignSystem.CornerRadius.medium,
        borderColor: Color = AppDesignSystem.Colors.borderGray
    ) {
        self._text = text
        self.height = height
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
    }
    
    var body: some View {
        TextEditor(text: $text)
            .frame(height: height)
            .padding(AppDesignSystem.Spacing.sm)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
            .scrollContentBackground(.hidden)
            .forceLightMode()
    }
}

/// Text field with gray background for settings/config
struct AppConfigTextField: View {
    let placeholder: String
    @Binding var text: String
    
    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(AppDesignSystem.CornerRadius.small)
            .forceLightMode()
            .foregroundColor(AppDesignSystem.Colors.textBlack)
    }
}
