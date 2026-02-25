import SwiftUI
import UniformTypeIdentifiers

struct ProgressDashboardView: View {
  @EnvironmentObject private var repository: WordRootRepository
  @EnvironmentObject private var progressStore: ProgressStore

  @State private var isExporting = false
  @State private var isImporting = false
  @State private var exportDocument = ProgressBackupDocument(data: Data())
  @State private var alertMessage: String?
  @State private var showingAlert = false
  @State private var showingResetDialog = false

  private var totalRoots: Int {
    max(repository.roots.count, 1)
  }

  private var masteredCount: Int {
    progressStore.masteredCount
  }

  private var percentage: Int {
    Int((Double(masteredCount) / Double(totalRoots)) * 100)
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 14) {
        metricGrid

        VStack(alignment: .leading, spacing: 10) {
          HStack {
            Text("整体进度")
              .font(.headline)
            Spacer()
            Text("\(percentage)%")
              .font(.headline)
          }

          ProgressView(value: Double(masteredCount), total: Double(totalRoots))
            .tint(.yellow)

          Text("距离下一级还需掌握 \(progressStore.rootsNeededForNextLevel) 个词根")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

        actionButtons

        achievementsSection
      }
      .padding(16)
    }
    .navigationTitle("学习进度")
    .fileExporter(
      isPresented: $isExporting,
      document: exportDocument,
      contentType: .json,
      defaultFilename: "word-roots-progress"
    ) { result in
      switch result {
      case .success:
        showAlert("学习数据已导出。")
      case .failure(let error):
        showAlert("导出失败：\(error.localizedDescription)")
      }
    }
    .fileImporter(
      isPresented: $isImporting,
      allowedContentTypes: [.json],
      allowsMultipleSelection: false
    ) { result in
      switch result {
      case .success(let urls):
        guard let url = urls.first else { return }
        do {
          let shouldStop = url.startAccessingSecurityScopedResource()
          defer {
            if shouldStop {
              url.stopAccessingSecurityScopedResource()
            }
          }

          let data = try Data(contentsOf: url)
          try progressStore.importData(data)
          showAlert("学习数据已导入。")
        } catch {
          showAlert("导入失败：\(error.localizedDescription)")
        }
      case .failure(let error):
        showAlert("导入失败：\(error.localizedDescription)")
      }
    }
    .alert("提示", isPresented: $showingAlert) {
      Button("确定", role: .cancel) { }
    } message: {
      Text(alertMessage ?? "")
    }
    .confirmationDialog("清除全部学习数据？", isPresented: $showingResetDialog, titleVisibility: .visible) {
      Button("清除", role: .destructive) {
        progressStore.clearAll()
      }
      Button("取消", role: .cancel) { }
    } message: {
      Text("此操作不可恢复")
    }
  }

  private var metricGrid: some View {
    VStack(spacing: 10) {
      HStack(spacing: 10) {
        metricCard(title: "已掌握", value: "\(masteredCount)/\(repository.roots.count)", icon: "book.closed.fill")
        metricCard(title: "等级", value: "Lv.\(progressStore.progress.level)", icon: "star.fill")
      }

      HStack(spacing: 10) {
        metricCard(title: "连续学习", value: "\(progressStore.progress.studyStreak) 天", icon: "flame.fill")
        metricCard(title: "总积分", value: "\(progressStore.progress.totalScore)", icon: "bolt.fill")
      }

      HStack(spacing: 10) {
        metricCard(title: "学习次数", value: "\(progressStore.progress.sessionCount)", icon: "number")
        metricCard(title: "上次学习", value: lastStudyText(), icon: "calendar")
      }
    }
  }

  private var actionButtons: some View {
    HStack(spacing: 10) {
      Button {
        exportData()
      } label: {
        Label("导出", systemImage: "square.and.arrow.up")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.bordered)

      Button {
        isImporting = true
      } label: {
        Label("导入", systemImage: "square.and.arrow.down")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.bordered)

      Button(role: .destructive) {
        showingResetDialog = true
      } label: {
        Label("重置", systemImage: "trash")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.bordered)
    }
  }

  private var achievementsSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("成就")
        .font(.headline)

      if progressStore.achievements.isEmpty {
        Text("还没有解锁成就，继续学习就会点亮。")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(14)
          .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
      } else {
        ForEach(progressStore.achievements.reversed()) { achievement in
          HStack(spacing: 12) {
            Text(achievement.icon)
              .font(.system(size: 28))
            VStack(alignment: .leading, spacing: 3) {
              Text(achievement.title)
                .font(.headline)
              Text(achievement.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
              Text(achievement.unlockedAt.formatted(date: .numeric, time: .omitted))
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
            Spacer()
          }
          .padding(12)
          .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
      }
    }
  }

  private func metricCard(title: String, value: String, icon: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Label(title, systemImage: icon)
        .font(.subheadline)
        .foregroundStyle(.secondary)
      Text(value)
        .font(.headline)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
  }

  private func lastStudyText() -> String {
    let now = Date()
    let dayDiff = Calendar.current.dateComponents([.day], from: progressStore.progress.lastStudyDate, to: now).day ?? 0

    if dayDiff <= 0 {
      return "今天"
    }

    if dayDiff == 1 {
      return "昨天"
    }

    return "\(dayDiff) 天前"
  }

  private func exportData() {
    do {
      let data = try progressStore.exportData()
      exportDocument = ProgressBackupDocument(data: data)
      isExporting = true
    } catch {
      showAlert("导出失败：\(error.localizedDescription)")
    }
  }

  private func showAlert(_ message: String) {
    alertMessage = message
    showingAlert = true
  }
}
