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

  private var completionRatio: Double {
    guard totalRoots > 0 else { return 0 }
    return min(max(Double(masteredCount) / Double(totalRoots), 0), 1)
  }

  private var percentage: Int {
    Int(completionRatio * 100)
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        heroProgressCard
        metricGrid
        actionButtons
        achievementsSection
      }
      .padding(16)
    }
    .navigationTitle("学习进度")
    .background(Color(.systemGroupedBackground))
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

  private var heroProgressCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .center, spacing: 14) {
        progressRing

        VStack(alignment: .leading, spacing: 6) {
          Text("整体进度")
            .font(.headline)

          Text("\(masteredCount)/\(repository.roots.count) 已掌握")
            .font(.subheadline)
            .foregroundStyle(.secondary)

          Text("距离下一级还需掌握 \(progressStore.rootsNeededForNextLevel) 个词根")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .minimumScaleFactor(0.9)
        }

        Spacer(minLength: 0)
      }

      ProgressView(value: Double(masteredCount), total: Double(totalRoots))
        .tint(.yellow)
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(.thinMaterial)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .stroke(Color(.separator).opacity(0.20), lineWidth: 1)
    )
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
        Text("\(percentage)%")
          .font(.title3.weight(.bold))
          .monospacedDigit()

        Text("完成")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .frame(width: 84, height: 84)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("整体进度")
    .accessibilityValue("\(percentage)%，已掌握 \(masteredCount)，总数 \(repository.roots.count)")
  }

  private var metricGrid: some View {
    Grid(horizontalSpacing: 10, verticalSpacing: 10) {
      GridRow {
        metricCard(title: "已掌握", value: "\(masteredCount)", unit: "个", icon: "book.closed.fill", tint: .green)
        metricCard(title: "等级", value: "\(progressStore.progress.level)", unit: "Lv", icon: "star.fill", tint: .yellow)
      }

      GridRow {
        metricCard(title: "连续学习", value: "\(progressStore.progress.studyStreak)", unit: "天", icon: "flame.fill", tint: .orange)
        metricCard(title: "总积分", value: "\(progressStore.progress.totalScore)", unit: "分", icon: "bolt.fill", tint: .blue)
      }

      GridRow {
        metricCard(title: "学习次数", value: "\(progressStore.progress.sessionCount)", unit: "次", icon: "number", tint: .purple)
        metricCard(title: "上次学习", value: lastStudyText(), unit: nil, icon: "calendar", tint: .indigo)
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
      HStack {
        Text("成就")
          .font(.headline)
        Spacer()
      }

      if progressStore.achievements.isEmpty {
        Text("还没有解锁成就，继续学习就会点亮。")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(14)
          .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
              .fill(Color(.secondarySystemGroupedBackground))
          )
      } else {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 12) {
            ForEach(progressStore.achievements.reversed()) { achievement in
              achievementCard(achievement)
            }
          }
          .padding(.vertical, 2)
        }
      }
    }
  }

  private func metricCard(
    title: String,
    value: String,
    unit: String?,
    icon: String,
    tint: Color
  ) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 8) {
        Image(systemName: icon)
          .foregroundStyle(tint)
        Text(title)
          .foregroundStyle(.secondary)
        Spacer()
      }
      .font(.subheadline)

      HStack(alignment: .firstTextBaseline, spacing: 6) {
        Text(value)
          .font(.title3.weight(.bold))
          .monospacedDigit()
          .lineLimit(1)
          .minimumScaleFactor(0.75)

        if let unit {
          Text(unit)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(14)
    .background(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(Color(.secondarySystemGroupedBackground))
    )
  }

  private func achievementCard(_ achievement: Achievement) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 10) {
        Text(achievement.icon)
          .font(.system(size: 30))

        VStack(alignment: .leading, spacing: 2) {
          Text(achievement.title)
            .font(.headline)
            .lineLimit(1)

          Text(achievement.unlockedAt.formatted(date: .abbreviated, time: .omitted))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer(minLength: 0)
      }

      Text(achievement.description)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .lineLimit(2)
    }
    .frame(width: 240, alignment: .leading)
    .padding(14)
    .background(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(Color(.secondarySystemGroupedBackground))
    )
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
