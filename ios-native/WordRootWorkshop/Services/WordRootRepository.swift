import Foundation

@MainActor
final class WordRootRepository: ObservableObject {
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
      }
    }
  }

  @Published private(set) var roots: [WordRoot] = []
  @Published private(set) var loadError: String?
  @Published private(set) var startupIssue: StartupIssue?

  private var rootsByID: [Int: WordRoot] = [:]

  init(bundle: Bundle = .main) {
    load(from: bundle)
  }

  func load(from bundle: Bundle = .main) {
    do {
      let loaded = try Self.loadRoots(from: bundle)
      roots = loaded
      rootsByID = Dictionary(uniqueKeysWithValues: loaded.map { ($0.id, $0) })
      loadError = nil
      startupIssue = nil
    } catch {
      roots = []
      rootsByID = [:]
      let resolvedError: RepositoryError
      if let error = error as? RepositoryError {
        resolvedError = error
      } else {
        resolvedError = .decodeFailed(
          filePath: "unknown",
          underlyingMessage: error.localizedDescription
        )
      }
      loadError = resolvedError.localizedDescription
      startupIssue = Self.makeStartupIssue(from: resolvedError)
    }
  }

  func root(for id: Int) -> WordRoot? {
    rootsByID[id]
  }

  static func makeStartupIssue(from error: RepositoryError) -> StartupIssue {
    let baseSteps = [
      "确认项目里存在 ios-native/WordRootWorkshop/Resources/wordRoots.json",
      "执行：node ios-native/scripts/export_word_roots_json.js",
      "执行：xcodegen generate --spec ios-native/project.yml",
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
    }
  }

  static func loadRoots(from bundle: Bundle) throws -> [WordRoot] {
    let resourceName = "wordRoots.json"
    guard let url = bundle.url(forResource: "wordRoots", withExtension: "json") else {
      throw RepositoryError.resourceMissing(
        resourceName: resourceName,
        bundlePath: bundle.bundlePath
      )
    }

    let data: Data
    do {
      data = try Data(contentsOf: url)
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
}
