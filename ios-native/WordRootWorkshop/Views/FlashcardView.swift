import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct FlashcardView: View {
  @EnvironmentObject private var repository: WordRootRepository
  @EnvironmentObject private var progressStore: ProgressStore

  @State private var currentIndex = 0
  @State private var isFlipped = false

  private var roots: [WordRoot] { repository.roots }

  private var currentRoot: WordRoot? {
    guard !roots.isEmpty else { return nil }
    return roots[min(max(currentIndex, 0), roots.count - 1)]
  }

  var body: some View {
    VStack(spacing: 16) {
      if let root = currentRoot {
        header

        Button {
          withAnimation(.easeInOut(duration: 0.35)) {
            isFlipped.toggle()
          }
          hapticLight()
        } label: {
          FlashcardContent(root: root, isFlipped: isFlipped)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("翻转卡片")
        .accessibilityValue(isFlipped ? "当前为背面" : "当前为正面")
        .accessibilityHint("双击可在正反面之间切换")

        HStack(spacing: 12) {
          Button {
            prevCard()
          } label: {
            Label("上一个", systemImage: "chevron.left")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.bordered)
          .accessibilityHint("切换到上一张卡片")

          Button {
            markKnown()
          } label: {
            Label("已掌握", systemImage: "checkmark")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.borderedProminent)
          .accessibilityHint("将当前词根标记为已掌握，并自动切换下一张")

          Button {
            nextCard()
          } label: {
            Label("下一个", systemImage: "chevron.right")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.bordered)
          .accessibilityHint("切换到下一张卡片")
        }
      } else if let loadError = repository.loadError {
        ContentUnavailableView("数据加载失败", systemImage: "exclamationmark.triangle", description: Text(loadError))
      } else {
        Spacer()
        ProgressView("加载词根中...")
        Spacer()
      }
    }
    .padding(16)
    .navigationTitle("闪卡")
    .onAppear(perform: syncCurrentIndex)
    .onChange(of: repository.roots.count) { _, _ in
      syncCurrentIndex()
    }
  }

  private var header: some View {
    HStack {
      Text("\(displayIndex)/\(max(roots.count, 1))")
        .font(.headline)
        .accessibilityLabel("当前卡片位置")
        .accessibilityValue("第 \(displayIndex) 张，共 \(max(roots.count, 1)) 张")

      Spacer()

      Text("已掌握: \(progressStore.masteredCount)")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .accessibilityLabel("已掌握词根数")
        .accessibilityValue("\(progressStore.masteredCount)")
    }
  }

  private var displayIndex: Int {
    guard !roots.isEmpty else { return 0 }
    return min(max(currentIndex, 0), roots.count - 1) + 1
  }

  private func syncCurrentIndex() {
    guard !roots.isEmpty else { return }
    currentIndex = min(max(progressStore.progress.currentRootIndex, 0), roots.count - 1)
    isFlipped = false
  }

  private func nextCard() {
    guard !roots.isEmpty else { return }
    currentIndex = (currentIndex + 1) % roots.count
    progressStore.setCurrentRootIndex(currentIndex)
    isFlipped = false
  }

  private func prevCard() {
    guard !roots.isEmpty else { return }
    currentIndex = (currentIndex - 1 + roots.count) % roots.count
    progressStore.setCurrentRootIndex(currentIndex)
    isFlipped = false
  }

  private func markKnown() {
    guard let root = currentRoot else { return }
    progressStore.markRootAsMastered(root.id)
    hapticSuccess()
    nextCard()
  }

  private func hapticLight() {
    #if canImport(UIKit)
    let generator = UIImpactFeedbackGenerator(style: .light)
    generator.impactOccurred()
    #endif
  }

  private func hapticSuccess() {
    #if canImport(UIKit)
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.success)
    #endif
  }
}

private struct FlashcardContent: View {
  let root: WordRoot
  let isFlipped: Bool

  @ScaledMetric(relativeTo: .largeTitle) private var rootFontSize: CGFloat = 44

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(Color(.secondarySystemBackground))
        .frame(maxWidth: .infinity)
        .aspectRatio(3.0 / 2.0, contentMode: .fit)

      front
        .opacity(isFlipped ? 0 : 1)

      back
        .opacity(isFlipped ? 1 : 0)
    }
    .overlay(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .stroke(Color(.separator), lineWidth: 1)
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
    .padding(20)
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

      ForEach(root.examples.prefix(3), id: \.word) { ex in
        Text("• \(ex.word)：\(ex.meaning)")
          .font(.footnote)
          .lineLimit(2)
          .minimumScaleFactor(0.85)
      }
    }
    .padding(18)
    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
    .accessibilityElement(children: .combine)
    .accessibilityLabel("词根卡片背面")
    .accessibilityValue("\(root.root) 的解释与例词")
  }
}
