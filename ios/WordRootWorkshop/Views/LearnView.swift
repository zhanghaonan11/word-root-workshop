import SwiftUI

struct LearnView: View {
  @EnvironmentObject private var repository: WordRootRepository
  @EnvironmentObject private var progressStore: ProgressStore
  @EnvironmentObject private var pronunciationService: PronunciationService

  private enum ScrollAnchor {
    static let top = "learn_top"
  }

  @State private var currentIndex = 0
  @State private var quizID = UUID()
  @State private var lastQuizResult: QuizSectionView.SubmissionResult?
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
    ScrollViewReader { proxy in
      ScrollView {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.section) {
          Color.clear
            .frame(height: 0)
            .id(ScrollAnchor.top)

          heroProgressCard

          if let loadError = repository.loadError {
            ContentUnavailableView("数据加载失败", systemImage: "exclamationmark.triangle", description: Text(loadError))
              .frame(maxWidth: .infinity)
          } else if let root = currentRoot {
            rootCard(root)
            examplesCard(root)
            quizCard(root)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.tight) {
              Button {
                moveToNextRoot()
              } label: {
                Label(nextStepTitle, systemImage: "arrow.right.circle.fill")
                  .frame(maxWidth: .infinity)
              }
              .buttonStyle(.borderedProminent)
              .controlSize(.large)
              .accessibilityHint(nextStepHint)

              if let nextStepSupportingText {
                Text(nextStepSupportingText)
                  .font(.footnote)
                  .foregroundStyle(.secondary)
              }
            }
          } else {
            ProgressView("加载词根中...")
              .frame(maxWidth: .infinity, alignment: .center)
              .padding(.top, 40)
          }
        }
        .padding(DesignSystem.Spacing.page)
      }
      .navigationTitle("学习")
      .screenBackground()
      .onAppear {
        syncCurrentIndex()
        // 进入页面时确保在顶部
        proxy.scrollTo(ScrollAnchor.top, anchor: .top)
      }
      .onChange(of: repository.roots.count) { _, _ in
        syncCurrentIndex()
      }
      .onChange(of: safeIndex) { _, _ in
        // 切换到下一个词根后，强制回到顶部（否则会停留在按钮附近）
        withAnimation(DesignSystem.Motion.standard) {
          proxy.scrollTo(ScrollAnchor.top, anchor: .top)
        }
      }
    }
  }

  private var heroProgressCard: some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.item) {
      HStack(alignment: .center, spacing: DesignSystem.Spacing.regular) {
        progressRing

        VStack(alignment: .leading, spacing: DesignSystem.Spacing.tight) {
          HStack {
            Text("学习进度")
              .font(.headline)
            Spacer()
            Text("\(safeDisplayIndex)/\(max(totalCount, 1))")
              .font(.subheadline.weight(.semibold))
              .monospacedDigit()
              .foregroundStyle(.secondary)
          }

          HStack(spacing: DesignSystem.Spacing.compact) {
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
    .heroCardBackground()
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
    HStack(spacing: DesignSystem.Spacing.xSmall) {
      Image(systemName: icon)
        .foregroundStyle(tint)
      Text(text)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.85)
    }
    .padding(.horizontal, DesignSystem.Spacing.compact)
    .padding(.vertical, DesignSystem.Spacing.xSmall)
    .background(
      Capsule(style: .continuous)
        .fill(Color(.secondarySystemGroupedBackground))
    )
  }

  private func rootCard(_ root: WordRoot) -> some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.regular) {
      rootHeader(root)

      VStack(alignment: .leading, spacing: DesignSystem.Spacing.tight) {
        Text("详细说明")
          .font(.headline)
        Text(root.description)
          .font(.body)
          .foregroundStyle(.secondary)
      }
    }
    .cardBackground()
  }

  private func quizCard(_ root: WordRoot) -> some View {
    QuizSectionView(
      quiz: root.quiz,
      onCorrect: {
        progressStore.markRootAsMastered(root.id)
      },
      onSubmitResult: { result in
        lastQuizResult = result
      }
    )
    .id(quizID)
    .padding(.vertical, 2)
  }

  private func examplesCard(_ root: WordRoot) -> some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.item) {
      HStack {
        Text("例词解析")
          .font(.headline)
        Spacer()
      }

      ForEach(root.examples) { example in
        ExampleCardView(example: example)
      }
    }
  }

  @ViewBuilder
  private func rootHeader(_ root: WordRoot) -> some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.compact) {
      Button {
        pronunciationService.speak(root.root)
      } label: {
        HStack(spacing: DesignSystem.Spacing.tight) {
          Text(root.root)
            .font(.system(size: rootFontSize, weight: .bold, design: .rounded))
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
      .accessibilityHint("双击播放词根发音")

      HStack(spacing: DesignSystem.Spacing.tight) {
        Text(root.origin)
          .font(.footnote.weight(.semibold))
          .padding(.horizontal, DesignSystem.Spacing.compact)
          .padding(.vertical, DesignSystem.Spacing.xxSmall)
          .background(Color.blue.opacity(0.14), in: Capsule())

        Text(root.meaning)
          .font(.title3.weight(.semibold))
          .lineLimit(2)
          .minimumScaleFactor(0.85)
      }
    }
  }

  private var nextStepTitle: String {
    switch lastQuizResult {
    case .some(.correct):
      return "回答正确，继续下一个"
    case .some(.incorrect):
      return "先进入下一个，稍后再复习"
    case .some(.invalid):
      return "题目异常，跳到下一个"
    case .none:
      return "下一个词根"
    }
  }

  private var nextStepHint: String {
    switch lastQuizResult {
    case .some(.correct):
      return "你已完成当前测试，切换到下一个词根并刷新题目"
    case .some(.incorrect):
      return "继续学习下一个词根，并可稍后回来复习本题"
    case .some(.invalid):
      return "当前题目无法判题，切换到下一个词根继续学习"
    case .none:
      return "切换到下一个词根并刷新当前题目"
    }
  }

  private var nextStepSupportingText: String? {
    switch lastQuizResult {
    case .some(.correct):
      return "当前词根已计入掌握进度。"
    case .some(.incorrect):
      return "建议稍后回看当前词根的例词与解释。"
    case .some(.invalid):
      return "数据异常不会影响掌握进度，建议后续检查题库。"
    case .none:
      return nil
    }
  }

  private func moveToNextRoot() {
    guard totalCount > 0 else { return }
    currentIndex = (currentIndex + 1) % totalCount
    progressStore.setCurrentRootIndex(currentIndex)
    quizID = UUID()
    lastQuizResult = nil
  }

  private func syncCurrentIndex() {
    guard totalCount > 0 else { return }
    let saved = min(max(progressStore.progress.currentRootIndex, 0), totalCount - 1)
    currentIndex = saved
    quizID = UUID()
    lastQuizResult = nil
  }
}

private enum LearnViewConstants {
  static let baseRootFontSize: CGFloat = 44
}
