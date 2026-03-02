import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct FlashcardView: View {
  @EnvironmentObject private var repository: WordRootRepository
  @EnvironmentObject private var progressStore: ProgressStore

  @StateObject private var haptics = FlashcardHaptics()

  @State private var currentIndex = 0
  @State private var isFlipped = false
  @State private var dragOffset: CGFloat = 0

  private var roots: [WordRoot] { repository.roots }

  private var safeIndex: Int {
    guard !roots.isEmpty else { return 0 }
    return min(max(currentIndex, 0), roots.count - 1)
  }

  private var displayIndex: Int {
    guard !roots.isEmpty else { return 0 }
    return safeIndex + 1
  }

  private var currentRoot: WordRoot? {
    guard !roots.isEmpty else { return nil }
    return roots[safeIndex]
  }

  private var canNavigate: Bool {
    roots.count > 1
  }

  private var isCurrentRootMastered: Bool {
    guard let currentRoot else { return false }
    return progressStore.isMastered(rootID: currentRoot.id)
  }

  var body: some View {
    VStack(spacing: DesignSystem.Spacing.section) {
      if let root = currentRoot {
        headerCard

        Button {
          withAnimation(DesignSystem.Motion.standard) {
            isFlipped.toggle()
          }
          haptics.light()
        } label: {
          FlashcardContent(root: root, isFlipped: isFlipped)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("翻转卡片")
        .accessibilityValue(isFlipped ? "当前为背面" : "当前为正面")
        .accessibilityHint("双击可在正反面之间切换")
        .offset(x: dragOffset)
        .rotationEffect(.degrees(Double(dragOffset / 30)))
        .simultaneousGesture(
          DragGesture(minimumDistance: 16)
            .onChanged(handleCardDragChanged)
            .onEnded(handleCardDragEnded)
        )

        controlButtons
      } else if let loadError = repository.loadError {
        ContentUnavailableView("数据加载失败", systemImage: "exclamationmark.triangle", description: Text(loadError))
      } else {
        Spacer()
        ProgressView("加载词根中...")
        Spacer()
      }
    }
    .padding(DesignSystem.Spacing.page)
    .navigationTitle("闪卡")
    .screenBackground()
    .onAppear {
      syncCurrentIndex()
      haptics.prepare()
    }
    .onChange(of: repository.roots.count) { _, _ in
      syncCurrentIndex()
    }
  }

  private var headerCard: some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.compact) {
      HStack {
        Text("\(displayIndex)/\(max(roots.count, 1))")
          .font(.headline)
          .contentTransition(.numericText(value: Double(displayIndex)))
          .monospacedDigit()
          .accessibilityLabel("当前卡片位置")
          .accessibilityValue("第 \(displayIndex) 张，共 \(max(roots.count, 1)) 张")

        Spacer()

        HStack(spacing: DesignSystem.Spacing.xSmall) {
          Image(systemName: "checkmark.seal.fill")
            .foregroundStyle(.green)
          Text("已掌握 \(progressStore.masteredCount)")
            .contentTransition(.numericText(value: Double(progressStore.masteredCount)))
            .foregroundStyle(.secondary)
        }
        .font(.subheadline.weight(.semibold))
      }

      ProgressView(value: Double(displayIndex), total: Double(max(roots.count, 1)))
        .tint(.yellow)
        .animation(DesignSystem.Motion.standard, value: displayIndex)
    }
    .heroCardBackground()
  }

  private var controlButtons: some View {
    HStack(spacing: DesignSystem.Spacing.item) {
      Button {
        prevCard()
      } label: {
        Label("上一个", systemImage: "chevron.left")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.bordered)
      .controlSize(.large)
      .disabled(!canNavigate)
      .accessibilityHint("切换到上一张卡片")

      Button {
        markKnown()
      } label: {
        Label(isCurrentRootMastered ? "已掌握" : "标记掌握", systemImage: isCurrentRootMastered ? "checkmark.circle.fill" : "checkmark")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .disabled(isCurrentRootMastered)
      .accessibilityHint("将当前词根标记为已掌握，并自动切换下一张")

      Button {
        nextCard()
      } label: {
        Label("下一个", systemImage: "chevron.right")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.bordered)
      .controlSize(.large)
      .disabled(!canNavigate)
      .accessibilityHint("切换到下一张卡片")
    }
    .animation(DesignSystem.Motion.standard, value: isCurrentRootMastered)
  }

  private func syncCurrentIndex() {
    guard !roots.isEmpty else { return }
    currentIndex = min(max(progressStore.progress.currentRootIndex, 0), roots.count - 1)
    isFlipped = false
    dragOffset = 0
  }

  private func nextCard() {
    guard !roots.isEmpty else { return }
    withAnimation(DesignSystem.Motion.spring) {
      currentIndex = (safeIndex + 1) % roots.count
    }
    progressStore.setCurrentRootIndex(currentIndex)
    isFlipped = false
    dragOffset = 0
  }

  private func prevCard() {
    guard !roots.isEmpty else { return }
    withAnimation(DesignSystem.Motion.spring) {
      currentIndex = (safeIndex - 1 + roots.count) % roots.count
    }
    progressStore.setCurrentRootIndex(currentIndex)
    isFlipped = false
    dragOffset = 0
  }

  private func markKnown() {
    guard let root = currentRoot else { return }
    guard !progressStore.isMastered(rootID: root.id) else { return }
    progressStore.markRootAsMastered(root.id)
    haptics.success()
    nextCard()
  }

  private func handleCardDragChanged(_ value: DragGesture.Value) {
    guard canNavigate else { return }

    var transaction = Transaction()
    transaction.animation = nil
    withTransaction(transaction) {
      dragOffset = value.translation.width
    }
  }

  private func handleCardDragEnded(_ value: DragGesture.Value) {
    guard canNavigate else {
      dragOffset = 0
      return
    }

    let threshold: CGFloat = 80
    let projectedTranslation = value.predictedEndTranslation.width

    if projectedTranslation < -threshold {
      nextCard()
      haptics.light()
    } else if projectedTranslation > threshold {
      prevCard()
      haptics.light()
    } else {
      withAnimation(DesignSystem.Motion.spring) {
        dragOffset = 0
      }
    }
  }
}

private struct FlashcardContent: View {
  let root: WordRoot
  let isFlipped: Bool

  @ScaledMetric(relativeTo: .largeTitle) private var rootFontSize: CGFloat = 44

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .fill(Color(.secondarySystemGroupedBackground))
        .frame(maxWidth: .infinity)
        .aspectRatio(3.0 / 2.0, contentMode: .fit)

      front
        .opacity(isFlipped ? 0 : 1)

      back
        .opacity(isFlipped ? 1 : 0)
    }
    .overlay(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .stroke(Color(.separator).opacity(0.18), lineWidth: 1)
    )
    .rotation3DEffect(
      .degrees(isFlipped ? 180 : 0),
      axis: (x: 0, y: 1, z: 0),
      perspective: 0.4
    )
  }

  private var front: some View {
    VStack(spacing: 10) {
      Text(root.root)
        .font(.system(size: rootFontSize, weight: .bold, design: .rounded))
        .lineLimit(1)
        .minimumScaleFactor(0.6)

      Text(root.meaning)
        .font(.title2.weight(.semibold))
        .lineLimit(2)
        .minimumScaleFactor(0.8)

      Text(root.origin)
        .font(.subheadline)
        .foregroundStyle(.secondary)

      Text("点击翻转")
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(.top, 8)
    }
    .padding(22)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("词根卡片正面")
    .accessibilityValue("\(root.root)，含义 \(root.meaning)，来源 \(root.origin)")
  }

  private var back: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(root.root)
        .font(.title.weight(.bold))
        .lineLimit(1)
        .minimumScaleFactor(0.8)

      Text(root.description)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .lineLimit(6)

      Divider()

      ForEach(Array(root.examples.prefix(3))) { ex in
        Text("• \(ex.word)：\(ex.meaning)")
          .font(.footnote)
          .lineLimit(2)
          .minimumScaleFactor(0.85)
      }
    }
    .padding(20)
    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
    .accessibilityElement(children: .combine)
    .accessibilityLabel("词根卡片背面")
    .accessibilityValue("\(root.root) 的解释与例词")
  }
}

@MainActor
private final class FlashcardHaptics: ObservableObject {
  #if canImport(UIKit)
  private let impactGenerator = UIImpactFeedbackGenerator(style: .light)
  private let notificationGenerator = UINotificationFeedbackGenerator()
  #endif

  func prepare() {
    #if canImport(UIKit)
    impactGenerator.prepare()
    notificationGenerator.prepare()
    #endif
  }

  func light() {
    #if canImport(UIKit)
    impactGenerator.impactOccurred()
    impactGenerator.prepare()
    #endif
  }

  func success() {
    #if canImport(UIKit)
    notificationGenerator.notificationOccurred(.success)
    notificationGenerator.prepare()
    #endif
  }
}
