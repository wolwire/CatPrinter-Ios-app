import SwiftUI

/// Reusable card container with consistent styling
struct AppCard<Content: View>: View {
  let content: Content
  let backgroundColor: Color
  let cornerRadius: CGFloat
  let shadowRadius: CGFloat
  let padding: CGFloat

  init(
    backgroundColor: Color = AppDesignSystem.Colors.cardBackground,
    cornerRadius: CGFloat = AppDesignSystem.CornerRadius.xLarge,
    shadowRadius: CGFloat = 6,
    padding: CGFloat = AppDesignSystem.Spacing.lg,
    @ViewBuilder content: () -> Content
  ) {
    self.backgroundColor = backgroundColor
    self.cornerRadius = cornerRadius
    self.shadowRadius = shadowRadius
    self.padding = padding
    self.content = content()
  }

  var body: some View {
    content
      .padding(padding)
      .background(backgroundColor)
      .cornerRadius(cornerRadius)
      .shadow(color: Color.black.opacity(0.03), radius: shadowRadius)
  }
}

/// App card with horizontal padding applied outside the card
struct AppCardWithPadding<Content: View>: View {
  let content: Content
  let backgroundColor: Color
  let cornerRadius: CGFloat
  let shadowRadius: CGFloat
  let innerPadding: CGFloat
  let outerPadding: CGFloat

  init(
    backgroundColor: Color = AppDesignSystem.Colors.cardBackground,
    cornerRadius: CGFloat = AppDesignSystem.CornerRadius.xLarge,
    shadowRadius: CGFloat = 6,
    innerPadding: CGFloat = AppDesignSystem.Spacing.lg,
    outerPadding: CGFloat = AppDesignSystem.Spacing.lg,
    @ViewBuilder content: () -> Content
  ) {
    self.backgroundColor = backgroundColor
    self.cornerRadius = cornerRadius
    self.shadowRadius = shadowRadius
    self.innerPadding = innerPadding
    self.outerPadding = outerPadding
    self.content = content()
  }

  var body: some View {
    content
      .padding(innerPadding)
      .background(backgroundColor)
      .cornerRadius(cornerRadius)
      .shadow(color: Color.black.opacity(0.03), radius: shadowRadius)
      .padding(.horizontal, outerPadding)
  }
}
