import SwiftUI

enum DesignSystem {
  enum Spacing {
    static let xxSmall: CGFloat = 4
    static let xSmall: CGFloat = 6
    static let compact: CGFloat = 10
    static let regular: CGFloat = 14
    static let page: CGFloat = 16
    static let section: CGFloat = 16
    static let item: CGFloat = 12
    static let tight: CGFloat = 8
    static let largeSection: CGFloat = 20
  }

  enum Radius {
    static let card: CGFloat = 18
    static let largeCard: CGFloat = 22
    static let control: CGFloat = 12
    static let chip: CGFloat = 10
  }

  enum Stroke {
    static let subtle: CGFloat = 1
  }

  enum Motion {
    static let standard: Animation = .easeInOut(duration: 0.25)
    static let spring: Animation = .spring(response: 0.35, dampingFraction: 0.86)
  }
}

extension View {
  func screenBackground() -> some View {
    background(Color(.systemGroupedBackground))
  }

  func cardBorder(cornerRadius: CGFloat = DesignSystem.Radius.card) -> some View {
    overlay(
      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .stroke(Color(.separator).opacity(0.20), lineWidth: DesignSystem.Stroke.subtle)
    )
  }

  func cardBackground(_ fill: Color = Color(.secondarySystemGroupedBackground)) -> some View {
    self
      .padding(DesignSystem.Spacing.section)
      .background(
        RoundedRectangle(cornerRadius: DesignSystem.Radius.card, style: .continuous)
          .fill(fill)
      )
  }

  func heroCardBackground() -> some View {
    self
      .padding(DesignSystem.Spacing.section)
      .background(
        RoundedRectangle(cornerRadius: DesignSystem.Radius.card, style: .continuous)
          .fill(.thinMaterial)
      )
      .cardBorder()
  }
}
