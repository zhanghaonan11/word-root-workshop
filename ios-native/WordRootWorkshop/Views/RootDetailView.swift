import SwiftUI

struct RootDetailView: View {
  let rootID: Int

  @EnvironmentObject private var repository: WordRootRepository
  @EnvironmentObject private var progressStore: ProgressStore

  private var root: WordRoot? {
    repository.root(for: rootID)
  }

  var body: some View {
    ScrollView {
      if let root {
        VStack(alignment: .leading, spacing: 16) {
          header(root)
          description(root)
          examples(root)

          QuizSectionView(quiz: root.quiz, rootID: root.id) {
            progressStore.markRootAsMastered(root.id)
          }
        }
        .padding(16)
      } else {
        ContentUnavailableView("词根不存在", systemImage: "questionmark.circle")
          .padding(.top, 50)
      }
    }
    .navigationTitle(root?.root ?? "词根详情")
    .navigationBarTitleDisplayMode(.inline)
  }

  @ViewBuilder
  private func header(_ root: WordRoot) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(root.root)
        .font(.system(size: 38, weight: .bold, design: .rounded))

      HStack(spacing: 10) {
        Text(root.origin)
          .font(.footnote.weight(.semibold))
          .padding(.horizontal, 10)
          .padding(.vertical, 4)
          .background(Color.blue.opacity(0.14), in: Capsule())
        Text(root.meaning)
          .font(.title3.weight(.semibold))
      }

      if progressStore.isMastered(rootID: root.id) {
        Label("已掌握", systemImage: "checkmark.seal.fill")
          .foregroundStyle(.green)
      }
    }
  }

  @ViewBuilder
  private func description(_ root: WordRoot) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("详细说明")
        .font(.headline)
      Text(root.description)
        .foregroundStyle(.secondary)
    }
    .padding(14)
    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
  }

  @ViewBuilder
  private func examples(_ root: WordRoot) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("例词解析")
        .font(.headline)
      ForEach(root.examples, id: \.word) { example in
        ExampleCardView(example: example)
      }
    }
  }
}

