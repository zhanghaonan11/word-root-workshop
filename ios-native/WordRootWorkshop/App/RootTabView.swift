import SwiftUI

struct RootTabView: View {
  @EnvironmentObject private var repository: WordRootRepository
  @State private var presentedStartupIssue: WordRootRepository.StartupIssue?

  var body: some View {
    TabView {
      NavigationStack {
        LearnView()
      }
      .tabItem {
        Label("学习", systemImage: "book.fill")
      }

      NavigationStack {
        FlashcardView()
      }
      .tabItem {
        Label("闪卡", systemImage: "rectangle.stack.fill")
      }

      NavigationStack {
        RootsIndexView()
      }
      .tabItem {
        Label("索引", systemImage: "list.bullet.rectangle")
      }

      NavigationStack {
        ProgressDashboardView()
      }
      .tabItem {
        Label("进度", systemImage: "chart.bar.fill")
      }
    }
    .onAppear {
      if let issue = repository.startupIssue {
        presentedStartupIssue = issue
      }
    }
    .onChange(of: repository.startupIssue) { _, issue in
      presentedStartupIssue = issue
    }
    .sheet(item: $presentedStartupIssue) { issue in
      StartupIssueSheet(issue: issue)
    }
  }
}

private struct StartupIssueSheet: View {
  let issue: WordRootRepository.StartupIssue
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
      .navigationTitle(issue.title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("关闭") {
            dismiss()
          }
        }
      }
    }
  }
}
