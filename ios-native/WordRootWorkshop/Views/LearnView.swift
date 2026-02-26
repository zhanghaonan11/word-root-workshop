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

  private var safeIndex: Int {
    guard totalCount > 0 else { return 0 }
    return min(max(currentIndex, 0), totalCount - 1)
  }

  private var safeDisplayIndex: Int {
    guard totalCount > 0 else { return 0 }
    return safeIndex + 1
  }

  private var completionRatio: Double {
    guard totalCount > 0 else { return 0 }
    return min(max(Double(safeDisplayIndex) / Double(totalCount), 0), 1)
  }

  private var currentRoot: WordRoot? {
    guard totalCount > 0 else { return nil }
    return repository.roots[safeIndex]
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        heroProgressCard

        if let loadError = repository.loadError {
          ContentUnavailableView("数据加载失败", systemImage: "exclamationmark.triangle", description: Text(loadError))
            .frame(maxWidth: .infinity)
        } else if let root = currentRoot {
          rootCard(root)
          quizCard(root)
          examplesCard(root)

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
    .background(Color(.systemGroupedBackground))
    .onAppear(perform: syncCurrentIndex)
    .onChange(of: repository.roots.count) { _, _ in
      syncCurrentIndex()
    }
  }

  private var heroProgressCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .center, spacing: 14) {
        progressRing

        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("学习进度")
              .font(.headline)
            Spacer()
            Text("\(safeDisplayIndex)/\(max(totalCount, 1))")
              .font(.subheadline.weight(.semibold))
              .monospacedDigit()
              .foregroundStyle(.secondary)
          }

          HStack(spacing: 10) {
            metricPill(icon: "checkmark.seal.fill", text: "已掌握 \(progressStore.masteredCount)", tint: .green)
            metricPill(icon: "star.fill", text: "Lv.\(progressStore.progress.level)", tint: .yellow)
            metricPill(icon: "flame.fill", text: "\(progressStore.progress.studyStreak) 天", tint: .orange)
          }
          .font(.subheadline)
        }

        Spacer(minLength: 0)
      }

      ProgressView(value: Double(safeDisplayIndex), total: Double(max(totalCount, 1)))
        .tint(.yellow)
        .accessibilityLabel("学习进度条")
        .accessibilityValue("\(safeDisplayIndex) / \(max(totalCount, 1))")
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(.thinMaterial)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .stroke(Color(.separator).opacity(0.20), lineWidth: 1)
    )
  }

  private var progressRing: some View {
    ZStack {
      Circle()
        .stroke(Color(.tertiarySystemFill), lineWidth: 10)

      Circle()
        .trim(from: 0, to: completionRatio)
        .stroke(
          AngularGradient(
            gradient: Gradient(colors: [.yellow, .orange, .pink, .yellow]),
            center: .center
          ),
          style: StrokeStyle(lineWidth: 10, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))

      VStack(spacing: 2) {
        Text("\(Int(completionRatio * 100))%")
          .font(.title3.weight(.bold))
          .monospacedDigit()
        Text("完成")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .frame(width: 84, height: 84)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("整体学习进度")
    .accessibilityValue("\(Int(completionRatio * 100))%，第 \(safeDisplayIndex) 个，共 \(max(totalCount, 1)) 个")
  }

  private func metricPill(icon: String, text: String, tint: Color) -> some View {
    HStack(spacing: 6) {
      Image(systemName: icon)
        .foregroundStyle(tint)
      Text(text)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.85)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(
      Capsule(style: .continuous)
        .fill(Color(.secondarySystemGroupedBackground))
    )
  }

  private func rootCard(_ root: WordRoot) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      rootHeader(root)

      VStack(alignment: .leading, spacing: 8) {
        Text("详细说明")
          .font(.headline)
        Text(root.description)
          .font(.body)
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
    .id(quizID)
    .padding(.vertical, 2)
  }

  private func examplesCard(_ root: WordRoot) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("例词解析")
          .font(.headline)
        Spacer()
      }

      ForEach(Array(root.examples.enumerated()), id: \.offset) { _, example in
        ExampleCardView(example: example)
      }
    }
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
