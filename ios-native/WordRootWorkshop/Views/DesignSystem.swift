import SwiftUI

enum DesignSystem {
  enum Spacing {
    static let xxSmall: CGFloat = 4
    static let xSmall: CGFloat = 6
    static let tight: CGFloat = 8
    static let compact: CGFloat = 10
    static let regular: CGFloat = 12
    static let item: CGFloat = 14
    static let section: CGFloat = 20
    static let page: CGFloat = 16
  }

  enum Radius {
    static let control: CGFloat = 12
    static let chip: CGFloat = 10
    static let card: CGFloat = 18
    static let hero: CGFloat = 22
  }

  enum Motion {
    static let standard: Animation = .easeInOut(duration: 0.22)
    static let spring: Animation = .spring(response: 0.36, dampingFraction: 0.84, blendDuration: 0.1)
  }

  enum Theme {
    static let accent: Color = .yellow
  }
}

private struct ScreenBackgroundModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .background(
        Color(.systemGroupedBackground)
          .ignoresSafeArea()
      )
  }
}

private struct CardBackgroundModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding(DesignSystem.Spacing.regular)
      .background(
        RoundedRectangle(cornerRadius: DesignSystem.Radius.card, style: .continuous)
          .fill(Color(.secondarySystemGroupedBackground))
      )
      .overlay(
        RoundedRectangle(cornerRadius: DesignSystem.Radius.card, style: .continuous)
          .stroke(Color(.separator).opacity(0.14), lineWidth: 1)
      )
  }
}

private struct HeroCardBackgroundModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding(DesignSystem.Spacing.regular)
      .background(
        RoundedRectangle(cornerRadius: DesignSystem.Radius.hero, style: .continuous)
          .fill(
            LinearGradient(
              colors: [
                Color(.secondarySystemGroupedBackground),
                Color(.secondarySystemGroupedBackground).opacity(0.92)
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
      )
      .overlay(
        RoundedRectangle(cornerRadius: DesignSystem.Radius.hero, style: .continuous)
          .stroke(Color(.separator).opacity(0.14), lineWidth: 1)
      )
  }
}

private struct CardBorderModifier: ViewModifier {
  func body(content: Content) -> some View {
    content.overlay(
      RoundedRectangle(cornerRadius: DesignSystem.Radius.card, style: .continuous)
        .stroke(Color(.separator).opacity(0.14), lineWidth: 1)
    )
  }
}

extension View {
  func screenBackground() -> some View {
    modifier(ScreenBackgroundModifier())
  }

  func cardBackground() -> some View {
    modifier(CardBackgroundModifier())
  }

  func heroCardBackground() -> some View {
    modifier(HeroCardBackgroundModifier())
  }

  func cardBorder() -> some View {
    modifier(CardBorderModifier())
  }

  func appTheming() -> some View {
    self.tint(DesignSystem.Theme.accent)
  }
}
