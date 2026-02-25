import SwiftUI

struct RootsIndexView: View {
  @EnvironmentObject private var repository: WordRootRepository
  @EnvironmentObject private var progressStore: ProgressStore

  @State private var query = ""
  @State private var selectedCategory: WordRootCategory = .all
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
    .onAppear(perform: refilter)
    .onChange(of: query) { _, _ in refilter() }
    .onChange(of: selectedCategory) { _, _ in refilter() }
    .onChange(of: repository.roots.count) { _, _ in refilter() }
  }

  private func refilter() {
    filteredRoots = repository.roots.filter { root in
      matchesCategory(root) && matchesQuery(root)
    }
  }

  private func matchesCategory(_ root: WordRoot) -> Bool {
    selectedCategory == .all || root.category == selectedCategory
  }

  private func matchesQuery(_ root: WordRoot) -> Bool {
    let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !keyword.isEmpty else { return true }

    let lower = keyword.lowercased()
    return root.root.lowercased().contains(lower)
      || root.origin.lowercased().contains(lower)
      || root.meaning.lowercased().contains(lower)
      || root.description.lowercased().contains(lower)
      || root.examples.contains(where: { example in
        example.word.lowercased().contains(lower)
          || example.meaning.lowercased().contains(lower)
          || example.explanation.lowercased().contains(lower)
      })
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

