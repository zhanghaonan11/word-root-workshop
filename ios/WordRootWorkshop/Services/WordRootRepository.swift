import Foundation

@MainActor
final class WordRootRepository: ObservableObject {
  private struct LoadedRootsSnapshot {
    let roots: [WordRoot]
    let rootsByID: [Int: WordRoot]
  }

  struct StartupIssue: Identifiable, Equatable {
    let id: String
    let title: String
    let summary: String
    let steps: [String]
    let diagnostics: [String]
  }

  enum RepositoryError: LocalizedError {
    case resourceMissing(resourceName: String, bundlePath: String)
    case fileReadFailed(filePath: String, underlyingMessage: String)
    case emptyData(filePath: String)
    case decodeFailed(filePath: String, underlyingMessage: String)
    case duplicateIDs(ids: [Int])

    var errorDescription: String? {
      switch self {
      case .resourceMissing:
        return "启动自检失败：未找到 wordRoots.json"
      case .fileReadFailed:
        return "启动自检失败：wordRoots.json 读取失败"
      case .emptyData:
        return "启动自检失败：wordRoots.json 内容为空"
      case .decodeFailed:
        return "启动自检失败：wordRoots.json 解析失败"
      case .duplicateIDs:
        return "启动自检失败：wordRoots.json 存在重复 ID"
      }
    }
  }

  @Published private(set) var roots: [WordRoot] = []
  @Published private(set) var loadError: String?
  @Published private(set) var startupIssue: StartupIssue?

  private var rootsByID: [Int: WordRoot] = [:]
  private var loadTask: Task<Void, Never>?
  private var cachedSnapshotsByBundlePath: [String: LoadedRootsSnapshot] = [:]
  private var activeLoadBundlePath: String?

  init(bundle: Bundle = .main) {
    load(from: bundle)
  }

  func load(from bundle: Bundle = .main) {
    let bundlePath = bundle.bundlePath

    if let cachedSnapshot = cachedSnapshotsByBundlePath[bundlePath] {
      applyLoadedSnapshot(cachedSnapshot)
      return
    }

    if activeLoadBundlePath == bundlePath {
      return
    }

    loadTask?.cancel()
    activeLoadBundlePath = bundlePath

    loadTask = Task { [weak self] in
      guard let self else { return }

      defer {
        if activeLoadBundlePath == bundlePath {
          activeLoadBundlePath = nil
        }
      }

      do {
        let loadedSnapshot = try await Self.loadRootsInBackground(bundlePath: bundlePath)
        guard !Task.isCancelled else { return }

        cachedSnapshotsByBundlePath[bundlePath] = loadedSnapshot
        applyLoadedSnapshot(loadedSnapshot)
      } catch {
        guard !Task.isCancelled else { return }

        roots = []
        rootsByID = [:]
        let resolvedError = Self.resolveRepositoryError(from: error)
        loadError = resolvedError.localizedDescription
        startupIssue = Self.makeStartupIssue(from: resolvedError)
      }
    }
  }

  func root(for id: Int) -> WordRoot? {
    rootsByID[id]
  }

  private func applyLoadedSnapshot(_ loadedSnapshot: LoadedRootsSnapshot) {
    roots = loadedSnapshot.roots
    rootsByID = loadedSnapshot.rootsByID
    loadError = nil
    startupIssue = nil
  }

  nonisolated static func makeStartupIssue(from error: RepositoryError) -> StartupIssue {
    let baseSteps = [
      "确认项目里存在 ios/WordRootWorkshop/Resources/wordRoots.json",
      "执行：node ios/scripts/export_word_roots_json.js",
      "执行：xcodegen generate --spec ios/project.yml",
      "Xcode 里执行 Product > Clean Build Folder，并删除旧 App 后重装"
    ]

    switch error {
    case let .resourceMissing(resourceName, bundlePath):
      return StartupIssue(
        id: "startup_resource_missing",
        title: "启动自检失败：缺少词库资源",
        summary: "\(resourceName) 未打包进 App Bundle。",
        steps: baseSteps,
        diagnostics: ["Bundle path: \(bundlePath)"]
      )
    case let .fileReadFailed(filePath, underlyingMessage):
      return StartupIssue(
        id: "startup_file_read_failed",
        title: "启动自检失败：词库读取失败",
        summary: "App 找到了词库文件，但读取时发生错误。",
        steps: baseSteps,
        diagnostics: ["File path: \(filePath)", "Error: \(underlyingMessage)"]
      )
    case let .emptyData(filePath):
      return StartupIssue(
        id: "startup_empty_data",
        title: "启动自检失败：词库为空",
        summary: "wordRoots.json 内容为空或损坏。",
        steps: baseSteps,
        diagnostics: ["File path: \(filePath)"]
      )
    case let .decodeFailed(filePath, underlyingMessage):
      return StartupIssue(
        id: "startup_decode_failed",
        title: "启动自检失败：词库格式无效",
        summary: "wordRoots.json 结构不符合预期，无法解析。",
        steps: baseSteps,
        diagnostics: ["File path: \(filePath)", "Error: \(underlyingMessage)"]
      )
    case let .duplicateIDs(ids):
      return StartupIssue(
        id: "startup_duplicate_ids",
        title: "启动自检失败：词库存在重复 ID",
        summary: "wordRoots.json 里存在重复的词根 ID，应用无法建立索引。",
        steps: baseSteps,
        diagnostics: ["Duplicate IDs: \(ids.map(String.init).joined(separator: ", "))"]
      )
    }
  }

  nonisolated static func loadRoots(from bundle: Bundle) throws -> [WordRoot] {
    // NOTE: Duplicate ID validation is handled during background loading,
    // so we can surface a friendly, recoverable startup error instead of trapping.

    let resourceName = "wordRoots.json"
    guard let url = bundle.url(forResource: "wordRoots", withExtension: "json") else {
      throw RepositoryError.resourceMissing(
        resourceName: resourceName,
        bundlePath: bundle.bundlePath
      )
    }

    let data: Data
    do {
      data = try Data(contentsOf: url, options: [.mappedIfSafe])
    } catch {
      throw RepositoryError.fileReadFailed(
        filePath: url.path,
        underlyingMessage: error.localizedDescription
      )
    }

    guard !data.isEmpty else {
      throw RepositoryError.emptyData(filePath: url.path)
    }

    let decoder = JSONDecoder()
    do {
      return try decoder.decode([WordRoot].self, from: data)
    } catch {
      throw RepositoryError.decodeFailed(
        filePath: url.path,
        underlyingMessage: error.localizedDescription
      )
    }
  }

  private nonisolated static func loadRootsInBackground(bundlePath: String) async throws -> LoadedRootsSnapshot {
    try await withCheckedThrowingContinuation { continuation in
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          guard let bundle = Bundle(path: bundlePath) else {
            throw RepositoryError.resourceMissing(
              resourceName: "wordRoots.json",
              bundlePath: bundlePath
            )
          }

          let loadedRoots = try loadRoots(from: bundle)
          let duplicateIDs = findDuplicateIDs(in: loadedRoots)
          if !duplicateIDs.isEmpty {
            throw RepositoryError.duplicateIDs(ids: duplicateIDs)
          }

          let rootsByID = Dictionary(uniqueKeysWithValues: loadedRoots.map { ($0.id, $0) })
          continuation.resume(
            returning: LoadedRootsSnapshot(
              roots: loadedRoots,
              rootsByID: rootsByID
            )
          )
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }

  private nonisolated static func resolveRepositoryError(from error: Error) -> RepositoryError {
    if let error = error as? RepositoryError {
      return error
    }

    return .decodeFailed(
      filePath: "unknown",
      underlyingMessage: error.localizedDescription
    )
  }

  private nonisolated static func findDuplicateIDs(in roots: [WordRoot]) -> [Int] {
    var seen: Set<Int> = []
    var duplicates: Set<Int> = []

    for root in roots {
      if !seen.insert(root.id).inserted {
        duplicates.insert(root.id)
      }
    }

    return duplicates.sorted()
  }
}
