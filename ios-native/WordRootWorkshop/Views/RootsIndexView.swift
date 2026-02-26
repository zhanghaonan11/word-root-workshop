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
      } else {
        List(filteredRoots) { root in
          NavigationLink {
            RootDetailView(rootID: root.id)
          } label: {
            RootRow(root: root, isMastered: progressStore.isMastered(rootID: root.id))
          }
        }
        .listStyle(.plain)
      }
    }
    .navigationTitle("词根索引")
    .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "搜索词根、释义或例词")
    .safeAreaInset(edge: .top) {
      Picker("分类", selection: $selectedCategory) {
        ForEach(WordRootCategory.allCases) { category in
          Text(category.title).tag(category)
        }
      }
      .pickerStyle(.segmented)
      .padding(.horizontal, 16)
      .padding(.top, 8)
      .padding(.bottom, 6)
      .background(Color(.systemBackground))
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
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(root.root)
          .font(.headline)
        Spacer()
        if isMastered {
          Label("已掌握", systemImage: "checkmark.seal.fill")
            .font(.caption)
            .foregroundStyle(.green)
        }
      }

      Text(root.meaning)
        .font(.subheadline.weight(.medium))

      Text("\(root.origin) · #\(root.id)")
        .font(.footnote)
        .foregroundStyle(.secondary)

      Text(root.examples.prefix(3).map(\.word).joined(separator: "、"))
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
    .padding(.vertical, 4)
  }
}
