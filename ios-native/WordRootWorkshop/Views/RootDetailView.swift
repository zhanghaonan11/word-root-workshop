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
        VStack(alignment: .leading, spacing: 16) {
          headerCard(root)
          quizCard(root)
          examplesCard(root)
        }
        .padding(16)
      } else {
        ContentUnavailableView("词根不存在", systemImage: "questionmark.circle")
          .padding(.top, 50)
      }
    }
    .navigationTitle(root?.root ?? "词根详情")
    .navigationBarTitleDisplayMode(.inline)
    .background(Color(.systemGroupedBackground))
  }

  private func headerCard(_ root: WordRoot) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(alignment: .firstTextBaseline, spacing: 10) {
        Button {
          pronunciationService.speak(root.root)
        } label: {
          HStack(spacing: 10) {
            Text(root.root)
              .font(.system(size: 38, weight: .bold, design: .rounded))
              .lineLimit(1)
              .minimumScaleFactor(0.6)

            Image(systemName: "speaker.wave.2.fill")
              .font(.title3.weight(.semibold))
              .foregroundStyle(.blue)
          }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("播放发音")
        .accessibilityValue(root.root)

        Spacer(minLength: 0)

        if progressStore.isMastered(rootID: root.id) {
          HStack(spacing: 6) {
            Image(systemName: "checkmark.seal.fill")
            Text("已掌握")
          }
          .font(.caption.weight(.semibold))
          .foregroundStyle(.green)
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(
            Capsule(style: .continuous)
              .fill(Color.green.opacity(0.12))
          )
        }
      }

      HStack(spacing: 8) {
        Text(root.origin)
          .font(.footnote.weight(.semibold))
          .padding(.horizontal, 10)
          .padding(.vertical, 4)
          .background(Color.blue.opacity(0.14), in: Capsule(style: .continuous))

        Text(root.meaning)
          .font(.title3.weight(.semibold))
          .lineLimit(2)
          .minimumScaleFactor(0.85)
      }

      VStack(alignment: .leading, spacing: 8) {
        Text("详细说明")
          .font(.headline)
        Text(root.description)
          .foregroundStyle(.secondary)
      }
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(Color(.secondarySystemGroupedBackground))
    )
  }

  private func quizCard(_ root: WordRoot) -> some View {
    QuizSectionView(quiz: root.quiz, rootID: root.id) {
      progressStore.markRootAsMastered(root.id)
    }
  }

  private func examplesCard(_ root: WordRoot) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("例词解析")
        .font(.headline)

      ForEach(Array(root.examples.enumerated()), id: \.offset) { _, example in
        ExampleCardView(example: example)
      }
    }
  }
}
