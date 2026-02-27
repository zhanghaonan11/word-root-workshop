import SwiftUI

private enum RootTab: String, Hashable {
  case learn
  case flashcard
  case library
  case progress
}

struct RootTabView: View {
  @EnvironmentObject private var repository: WordRootRepository
  @AppStorage("selectedRootTab") private var selectedTabRawValue: String = RootTab.learn.rawValue
  @State private var presentedStartupIssue: WordRootRepository.StartupIssue?

  private var selectedTabBinding: Binding<RootTab> {
    Binding(
      get: { RootTab(rawValue: selectedTabRawValue) ?? .learn },
      set: { selectedTabRawValue = $0.rawValue }
    )
  }

  var body: some View {
    TabView(selection: selectedTabBinding) {
      NavigationStack {
        LearnView()
      }
      .tabItem {
        Label("学习", systemImage: "book.fill")
      }
      .tag(RootTab.learn)

      NavigationStack {
        FlashcardView()
      }
      .tabItem {
        Label("闪卡", systemImage: "rectangle.stack.fill")
      }
      .tag(RootTab.flashcard)

      NavigationStack {
        RootsIndexView()
      }
      .tabItem {
        Label("词根库", systemImage: "list.bullet.rectangle")
      }
      .tag(RootTab.library)

      NavigationStack {
        ProgressDashboardView()
      }
      .tabItem {
        Label("进度", systemImage: "chart.bar.fill")
      }
      .tag(RootTab.progress)
    }
    .toolbarBackground(.visible, for: .tabBar)
    .toolbarBackground(Color(.systemBackground), for: .tabBar)
    .onAppear {
      if let issue = repository.startupIssue {
        presentedStartupIssue = issue
      }
    }
    .onChange(of: repository.startupIssue) { _, issue in
      presentedStartupIssue = issue
    }
    .sheet(item: $presentedStartupIssue) { issue in
      StartupIssueSheet(issue: issue) {
        repository.load()
      }
      .presentationDetents([.medium, .large])
      .presentationDragIndicator(.visible)
      .presentationBackground(.regularMaterial)
      .presentationCornerRadius(22)
    }
  }
}

private struct StartupIssueSheet: View {
  let issue: WordRootRepository.StartupIssue
  let onRetry: () -> Void

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      List {
        Section("问题") {
          Text(issue.summary)
        }

        Section("修复步骤") {
          ForEach(Array(issue.steps.enumerated()), id: \.offset) { idx, step in
            Text("\(idx + 1). \(step)")
          }
        }

        if !issue.diagnostics.isEmpty {
          Section("诊断信息") {
            ForEach(issue.diagnostics, id: \.self) { line in
              Text(line)
                .font(.footnote.monospaced())
                .textSelection(.enabled)
            }
          }
        }
      }
      .listStyle(.insetGrouped)
      .navigationTitle(issue.title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("关闭") {
            dismiss()
          }
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button("重试加载") {
            onRetry()
            dismiss()
          }
        }
      }
    }
  }
}
