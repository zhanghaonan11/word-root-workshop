import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct LearningProgress: Codable, Hashable {
  var level: Int
  var masteredRoots: [Int]
  var currentRootIndex: Int
  var totalScore: Int
  var lastStudyDate: Date
  var studyStreak: Int
  var sessionCount: Int

  static let initial = LearningProgress(
    level: 1,
    masteredRoots: [],
    currentRootIndex: 0,
    totalScore: 0,
    lastStudyDate: Date(),
    studyStreak: 0,
    sessionCount: 0
  )
}

struct Achievement: Codable, Identifiable, Hashable {
  let id: String
  let type: String
  let title: String
  let description: String
  let icon: String
  let unlockedAt: Date
}

struct BackupPayload: Codable {
  let progress: LearningProgress
  let achievements: [Achievement]
  let exportDate: Date
}

struct ProgressBackupDocument: FileDocument {
  static var readableContentTypes: [UTType] { [.json] }

  var data: Data

  init(data: Data) {
    self.data = data
  }

  init(configuration: ReadConfiguration) throws {
    guard let data = configuration.file.regularFileContents else {
      throw CocoaError(.fileReadCorruptFile)
    }
    self.data = data
  }

  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    FileWrapper(regularFileWithContents: data)
  }
}
