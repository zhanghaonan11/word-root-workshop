import SwiftUI

private struct RootListItem: Identifiable, Hashable {
  let id: Int
  let root: String
  let origin: String
  let meaning: String
  let category: WordRootCategory
  let examplesPreview: String
}

struct RootsIndexView: View {
  private struct SearchEntry {
    let item: RootListItem
    let searchableText: String
  }

  private static let searchQueue = DispatchQueue(
    label: "com.shan.wordrootworkshop.search",
    qos: .userInitiated
  )
  private static let searchDebounceDelay: TimeInterval = 0.18

  @EnvironmentObject private var repository: WordRootRepository
  @EnvironmentObject private var progressStore: ProgressStore

  @State private var query = ""
  @State private var selectedCategory: WordRootCategory = .all
  @State private var indexedRoots: [SearchEntry] = []
  @State private var filteredRoots: [RootListItem] = []
  @State private var isFiltering = false

  @State private var indexingWorkItem: DispatchWorkItem?
  @State private var filteringWorkItem: DispatchWorkItem?
  @State private var indexingToken = 0
  @State private var filteringToken = 0
  @State private var lastFilterSignature = ""

  var body: some View {
    Group {
      if let loadError = repository.loadError {
        ContentUnavailableView("数据加载失败", systemImage: "exclamationmark.triangle", description: Text(loadError))
      } else if isFiltering, filteredRoots.isEmpty {
        ProgressView("筛选中...")
      } else if filteredRoots.isEmpty {
        ContentUnavailableView(
          query.isEmpty ? "暂无可显示的词根" : "未找到匹配结果",
          systemImage: query.isEmpty ? "tray" : "magnifyingglass",
          description: Text(query.isEmpty ? "请稍后重试或切换分类。" : "试试更短的关键词或切换分类。")
        )
      } else {
        List {
          ForEach(filteredRoots) { root in
            NavigationLink {
              RootDetailView(rootID: root.id)
            } label: {
              RootRow(item: root, isMastered: progressStore.isMastered(rootID: root.id))
                .equatable()
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(
              EdgeInsets(
                top: DesignSystem.Spacing.xxSmall,
                leading: DesignSystem.Spacing.page,
                bottom: DesignSystem.Spacing.xxSmall,
                trailing: DesignSystem.Spacing.page
              )
            )
          }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
      }
    }
    .navigationTitle("词根索引")
    .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "搜索词根、释义或例词")
    .screenBackground()
    .safeAreaInset(edge: .top) {
      VStack(spacing: 0) {
        Picker("分类", selection: $selectedCategory) {
          ForEach(WordRootCategory.allCases) { category in
            Text(category.title).tag(category)
          }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
      }
      .background(.thinMaterial)
      .overlay(
        Rectangle()
          .frame(height: 1)
          .foregroundStyle(Color(.separator).opacity(0.25)),
        alignment: .bottom
      )
    }
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Text("\(filteredRoots.count)/\(repository.roots.count)")
          .font(.footnote.monospacedDigit())
          .foregroundStyle(.secondary)
      }
    }
    .onAppear {
      if indexedRoots.isEmpty {
        rebuildSearchIndex()
      } else {
        scheduleRefilter(immediate: true)
      }
    }
    .onDisappear {
      indexingWorkItem?.cancel()
      filteringWorkItem?.cancel()
      isFiltering = false
    }
    .onChange(of: query) { _, _ in
      scheduleRefilter()
    }
    .onChange(of: selectedCategory) { _, _ in
      scheduleRefilter()
    }
    .onChange(of: repository.roots) { _, _ in
      rebuildSearchIndex()
    }
  }

  private func scheduleRefilter(immediate: Bool = false) {
    filteringWorkItem?.cancel()

    filteringToken &+= 1
    let token = filteringToken
    let keyword = normalizedQuery
    let selectedCategory = selectedCategory
    let indexedRoots = indexedRoots
    let signature = "\(indexingToken)|\(selectedCategory.rawValue)|\(keyword)"

    guard signature != lastFilterSignature else {
      return
    }
    lastFilterSignature = signature

    isFiltering = true

    let workItem = DispatchWorkItem {
      let results = indexedRoots.compactMap { entry -> RootListItem? in
        guard selectedCategory == .all || entry.item.category == selectedCategory else {
          return nil
        }

        guard keyword.isEmpty || entry.searchableText.contains(keyword) else {
          return nil
        }

        return entry.item
      }

      DispatchQueue.main.async {
        guard token == filteringToken else { return }
        filteredRoots = results
        isFiltering = false
      }
    }

    filteringWorkItem = workItem

    let delaySeconds = immediate ? 0.0 : Self.searchDebounceDelay
    Self.searchQueue.asyncAfter(deadline: .now() + delaySeconds, execute: workItem)
  }

  private func rebuildSearchIndex() {
    indexingWorkItem?.cancel()
    filteringWorkItem?.cancel()

    indexingToken &+= 1
    let token = indexingToken
    let roots = repository.roots

    isFiltering = true

    let workItem = DispatchWorkItem {
      let entries = roots.map { root in
        let item = RootListItem(
          id: root.id,
          root: root.root,
          origin: root.origin,
          meaning: root.meaning,
          category: root.category,
          examplesPreview: root.examples.prefix(3).map(\.word).joined(separator: "、")
        )

        return SearchEntry(
          item: item,
          searchableText: Self.buildSearchableText(for: root)
        )
      }

      DispatchQueue.main.async {
        guard token == indexingToken else { return }
        indexedRoots = entries
        scheduleRefilter(immediate: true)
      }
    }

    indexingWorkItem = workItem
    Self.searchQueue.async(execute: workItem)
  }

  private var normalizedQuery: String {
    query
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
  }

  private static func buildSearchableText(for root: WordRoot) -> String {
    let baseSegments = [root.root, root.origin, root.meaning, root.description]
    let exampleSegments = root.examples.flatMap { example in
      [example.word, example.meaning, example.explanation]
    }

    return (baseSegments + exampleSegments)
      .joined(separator: " ")
      .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
  }
}

private struct RootRow: View, Equatable {
  let item: RootListItem
  let isMastered: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.tight) {
      HStack(alignment: .firstTextBaseline) {
        Text(item.root)
          .font(.headline)

        Spacer()

        if isMastered {
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

      Text(item.meaning)
        .font(.subheadline.weight(.semibold))

      HStack(spacing: DesignSystem.Spacing.tight) {
        Text(item.origin)
          .font(.footnote.weight(.semibold))
          .padding(.horizontal, DesignSystem.Spacing.tight)
          .padding(.vertical, DesignSystem.Spacing.xxSmall)
          .background(Color.blue.opacity(0.12), in: Capsule(style: .continuous))

        Text("#\(item.id)")
          .font(.footnote.monospacedDigit())
          .foregroundStyle(.secondary)

        Spacer(minLength: 0)
      }

      Text(item.examplesPreview)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
    .padding(DesignSystem.Spacing.regular)
    .background(
      RoundedRectangle(cornerRadius: DesignSystem.Radius.card, style: .continuous)
        .fill(Color(.secondarySystemGroupedBackground))
    )
    .cardBorder()
    .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card, style: .continuous))
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(item.root)，\(item.meaning)")
    .accessibilityHint(isMastered ? "已掌握词根，双击查看详情" : "双击查看词根详情")
  }
}
