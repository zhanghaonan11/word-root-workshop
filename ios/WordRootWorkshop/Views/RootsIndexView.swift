import SwiftUI

struct RootsIndexView: View {
  private struct SearchEntry {
    let root: WordRoot
    let category: WordRootCategory
    let searchableText: String
  }

  @EnvironmentObject private var repository: WordRootRepository
  @EnvironmentObject private var progressStore: ProgressStore

  @State private var query = ""
  @State private var selectedCategory: WordRootCategory = .all
  @State private var indexedRoots: [SearchEntry] = []
  @State private var filteredRoots: [WordRoot] = []

  var body: some View {
    Group {
      if let loadError = repository.loadError {
        ContentUnavailableView("数据加载失败", systemImage: "exclamationmark.triangle", description: Text(loadError))
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
              RootRow(root: root, isMastered: progressStore.isMastered(rootID: root.id))
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
      rebuildSearchIndex()
      refilter()
    }
    .onChange(of: query) { _, _ in refilter() }
    .onChange(of: selectedCategory) { _, _ in refilter() }
    .onChange(of: repository.roots) { _, _ in
      rebuildSearchIndex()
      refilter()
    }
    .animation(DesignSystem.Motion.standard, value: filteredRoots.count)
  }

  private func refilter() {
    let keyword = normalizedQuery

    filteredRoots = indexedRoots.compactMap { entry in
      guard selectedCategory == .all || entry.category == selectedCategory else {
        return nil
      }

      guard keyword.isEmpty || entry.searchableText.contains(keyword) else {
        return nil
      }

      return entry.root
    }
  }

  private func rebuildSearchIndex() {
    indexedRoots = repository.roots.map { root in
      SearchEntry(
        root: root,
        category: root.category,
        searchableText: buildSearchableText(for: root)
      )
    }
  }

  private var normalizedQuery: String {
    query
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
  }

  private func buildSearchableText(for root: WordRoot) -> String {
    let baseSegments = [root.root, root.origin, root.meaning, root.description]
    let exampleSegments = root.examples.flatMap { example in
      [example.word, example.meaning, example.explanation]
    }

    return (baseSegments + exampleSegments)
      .joined(separator: " ")
      .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
  }
}

private struct RootRow: View {
  let root: WordRoot
  let isMastered: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.tight) {
      HStack(alignment: .firstTextBaseline) {
        Text(root.root)
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

      Text(root.meaning)
        .font(.subheadline.weight(.semibold))

      HStack(spacing: DesignSystem.Spacing.tight) {
        Text(root.origin)
          .font(.footnote.weight(.semibold))
          .padding(.horizontal, DesignSystem.Spacing.tight)
          .padding(.vertical, DesignSystem.Spacing.xxSmall)
          .background(Color.blue.opacity(0.12), in: Capsule(style: .continuous))

        Text("#\(root.id)")
          .font(.footnote.monospacedDigit())
          .foregroundStyle(.secondary)

        Spacer(minLength: 0)
      }

      Text(root.examples.prefix(3).map(\.word).joined(separator: "、"))
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
    .accessibilityLabel("\(root.root)，\(root.meaning)")
    .accessibilityHint(isMastered ? "已掌握词根，双击查看详情" : "双击查看词根详情")
  }
}
