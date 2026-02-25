import SwiftUI

struct LearnView: View {
  @EnvironmentObject private var repository: WordRootRepository
  @EnvironmentObject private var progressStore: ProgressStore
  @EnvironmentObject private var pronunciationService: PronunciationService

  @State private var currentIndex = 0
  @State private var quizID = UUID()

  private var totalCount: Int {
    repository.roots.count
  }

  private var currentRoot: WordRoot? {
    guard totalCount > 0 else { return nil }
    let safeIndex = min(max(currentIndex, 0), totalCount - 1)
    return repository.roots[safeIndex]
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        progressHeader

        if let loadError = repository.loadError {
          ContentUnavailableView("数据加载失败", systemImage: "exclamationmark.triangle", description: Text(loadError))
        } else if let root = currentRoot {
          rootHeader(root)
          descriptionSection(root)
          examplesSection(root)

          QuizSectionView(quiz: root.quiz, rootID: root.id) {
            progressStore.markRootAsMastered(root.id)
          }
          .id(quizID)

          Button("下一个词根") {
            moveToNextRoot()
          }
          .buttonStyle(.borderedProminent)
          .tint(.yellow)
          .foregroundStyle(.black)
        } else {
          ProgressView("加载词根中...")
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 40)
        }
      }
      .padding(16)
    }
    .navigationTitle("学习")
    .onAppear(perform: syncCurrentIndex)
    .onChange(of: repository.roots.count) { _, _ in
      syncCurrentIndex()
    }
  }

  private var progressHeader: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text("当前进度")
          .font(.headline)
        Spacer()
        Text("\(safeDisplayIndex)/\(max(totalCount, 1))")
          .font(.subheadline.weight(.semibold))
      }

      ProgressView(value: Double(safeDisplayIndex), total: Double(max(totalCount, 1)))
        .tint(.yellow)

      HStack {
        Label("已掌握 \(progressStore.masteredCount)", systemImage: "checkmark.seal.fill")
          .foregroundStyle(.secondary)
        Spacer()
        Text("Lv.\(progressStore.progress.level)")
          .font(.subheadline.weight(.semibold))
      }
      .font(.subheadline)
    }
    .padding(14)
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
  }

  private var safeDisplayIndex: Int {
    guard totalCount > 0 else { return 0 }
    let safeIndex = min(max(currentIndex, 0), totalCount - 1)
    return safeIndex + 1
  }

  @ViewBuilder
  private func rootHeader(_ root: WordRoot) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Button {
        pronunciationService.speak(root.root)
      } label: {
        HStack(spacing: 8) {
          Text(root.root)
            .font(.system(size: LearnViewConstants.rootFontSize, weight: .bold, design: .rounded))
          Image(systemName: "speaker.wave.2.fill")
            .font(.title3.weight(.semibold))
            .foregroundStyle(.blue)
        }
      }
      .buttonStyle(.plain)
      .accessibilityLabel("播放 \(root.root) 发音")

      HStack(spacing: 8) {
        Text(root.origin)
          .font(.footnote.weight(.semibold))
          .padding(.horizontal, 10)
          .padding(.vertical, 4)
          .background(Color.blue.opacity(0.14), in: Capsule())

        Text(root.meaning)
          .font(.title3.weight(.semibold))
      }
    }
  }

  @ViewBuilder
  private func descriptionSection(_ root: WordRoot) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("详细说明")
        .font(.headline)
      Text(root.description)
        .font(.body)
        .foregroundStyle(.secondary)
    }
    .padding(14)
    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
  }

  @ViewBuilder
  private func examplesSection(_ root: WordRoot) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("例词解析")
        .font(.headline)
      ForEach(root.examples, id: \.word) { example in
        ExampleCardView(example: example)
      }
    }
  }

  private func moveToNextRoot() {
    guard totalCount > 0 else { return }
    currentIndex = (currentIndex + 1) % totalCount
    progressStore.setCurrentRootIndex(currentIndex)
    quizID = UUID()
  }

  private func syncCurrentIndex() {
    guard totalCount > 0 else { return }
    let saved = min(max(progressStore.progress.currentRootIndex, 0), totalCount - 1)
    currentIndex = saved
    quizID = UUID()
  }
}

private enum LearnViewConstants {
  static let rootFontSize: CGFloat = 44
}
