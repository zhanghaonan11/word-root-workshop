import SwiftUI

struct RootDetailView: View {
  let rootID: Int

  @EnvironmentObject private var repository: WordRootRepository
  @EnvironmentObject private var progressStore: ProgressStore
  @EnvironmentObject private var pronunciationService: PronunciationService

  private var root: WordRoot? {
    repository.root(for: rootID)
  }

  var body: some View {
    ScrollView {
      if let root {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.section) {
          headerCard(root)
          quizCard(root)
          examplesCard(root)
        }
        .padding(DesignSystem.Spacing.page)
      } else {
        ContentUnavailableView("词根不存在", systemImage: "questionmark.circle")
          .padding(.top, 50)
      }
    }
    .navigationTitle(root?.root ?? "词根详情")
    .navigationBarTitleDisplayMode(.inline)
    .screenBackground()
  }

  private func headerCard(_ root: WordRoot) -> some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.regular) {
      HStack(alignment: .firstTextBaseline, spacing: DesignSystem.Spacing.compact) {
        Button {
          pronunciationService.speak(root.root)
        } label: {
          HStack(spacing: DesignSystem.Spacing.compact) {
            Text(root.root)
              .font(.system(size: 38, weight: .bold, design: .rounded))
              .lineLimit(1)
              .minimumScaleFactor(0.6)

            Image(systemName: "speaker.wave.2.fill")
              .font(.title3.weight(.semibold))
              .foregroundStyle(.tint)
          }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("播放发音")
        .accessibilityValue(root.root)

        Spacer(minLength: 0)

        if progressStore.isMastered(rootID: root.id) {
          HStack(spacing: DesignSystem.Spacing.xSmall) {
            Image(systemName: "checkmark.seal.fill")
            Text("已掌握")
          }
          .font(.caption.weight(.semibold))
          .foregroundStyle(.green)
          .padding(.horizontal, DesignSystem.Spacing.compact)
          .padding(.vertical, DesignSystem.Spacing.xSmall)
          .background(
            Capsule(style: .continuous)
              .fill(Color.green.opacity(0.12))
          )
        }
      }

      HStack(spacing: DesignSystem.Spacing.tight) {
        Text(root.origin)
          .font(.footnote.weight(.semibold))
          .padding(.horizontal, DesignSystem.Spacing.compact)
          .padding(.vertical, DesignSystem.Spacing.xxSmall)
          .background(Color.blue.opacity(0.14), in: Capsule(style: .continuous))

        Text(root.meaning)
          .font(.title3.weight(.semibold))
          .lineLimit(2)
          .minimumScaleFactor(0.85)
      }

      VStack(alignment: .leading, spacing: DesignSystem.Spacing.tight) {
        Text("详细说明")
          .font(.headline)
        Text(root.description)
          .foregroundStyle(.secondary)
      }
    }
    .cardBackground()
  }

  private func quizCard(_ root: WordRoot) -> some View {
    QuizSectionView(quiz: root.quiz) {
      progressStore.markRootAsMastered(root.id)
    }
  }

  private func examplesCard(_ root: WordRoot) -> some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.item) {
      Text("例词解析")
        .font(.headline)

      ForEach(root.examples) { example in
        ExampleCardView(example: example)
      }
    }
  }
}
