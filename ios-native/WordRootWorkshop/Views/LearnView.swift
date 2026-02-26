import SwiftUI

struct LearnView: View {
  @EnvironmentObject private var repository: WordRootRepository
  @EnvironmentObject private var progressStore: ProgressStore
  @EnvironmentObject private var pronunciationService: PronunciationService

  @State private var currentIndex = 0
  @State private var quizID = UUID()
  @ScaledMetric(relativeTo: .largeTitle) private var rootFontSize: CGFloat = LearnViewConstants.baseRootFontSize

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

          Button {
            moveToNextRoot()
          } label: {
            Label("下一个词根", systemImage: "arrow.right.circle.fill")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.borderedProminent)
          .accessibilityHint("切换到下一个词根并刷新当前题目")
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
          .accessibilityLabel("学习进度")
          .accessibilityValue("第 \(safeDisplayIndex) 个，共 \(max(totalCount, 1)) 个")
      }

      ProgressView(value: Double(safeDisplayIndex), total: Double(max(totalCount, 1)))
        .accessibilityLabel("学习进度条")
        .accessibilityValue("\(safeDisplayIndex) / \(max(totalCount, 1))")

      HStack {
        Label("已掌握 \(progressStore.masteredCount)", systemImage: "checkmark.seal.fill")
          .foregroundStyle(.secondary)
          .accessibilityLabel("已掌握词根数")
          .accessibilityValue("\(progressStore.masteredCount)")

        Spacer()

        Text("Lv.\(progressStore.progress.level)")
          .font(.subheadline.weight(.semibold))
          .accessibilityLabel("当前等级")
          .accessibilityValue("等级 \(progressStore.progress.level)")
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
            .font(.system(size: rootFontSize, weight: .bold, design: .rounded))
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
      .accessibilityHint("双击播放词根发音")

      HStack(spacing: 8) {
        Text(root.origin)
          .font(.footnote.weight(.semibold))
          .padding(.horizontal, 10)
          .padding(.vertical, 4)
          .background(Color.blue.opacity(0.14), in: Capsule())

        Text(root.meaning)
          .font(.title3.weight(.semibold))
          .lineLimit(2)
          .minimumScaleFactor(0.85)
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
  static let baseRootFontSize: CGFloat = 44
}
