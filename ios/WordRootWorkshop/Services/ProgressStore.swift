import Foundation

private let progressStoreProgressKey = "wordRootProgress"
private let progressStoreAchievementsKey = "wordRootAchievements"
private let progressStorePersistenceDebounceSeconds: TimeInterval = 0.25

private struct ProgressPersistenceSnapshot {
  let progress: LearningProgress
  let achievements: [Achievement]
}

@MainActor
final class ProgressStore: ObservableObject {
  private enum Constants {
    static let pointsPerMastery = 10
    static let rootsPerLevel = 10
  }

  @Published private(set) var progress: LearningProgress
  @Published private(set) var achievements: [Achievement]

  /// O(1) 缓存，与 progress.masteredRoots 保持同步
  private var masteredRootIDs: Set<Int> = []

  private let userDefaults: UserDefaults
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder
  private let calendar: Calendar
  private let persistenceQueue: DispatchQueue
  private var persistenceWorkItem: DispatchWorkItem?

  init(userDefaults: UserDefaults = .standard, calendar: Calendar = .current) {
    self.userDefaults = userDefaults
    self.calendar = calendar
    self.persistenceQueue = DispatchQueue(
      label: "com.shan.wordrootworkshop.progress.persistence",
      qos: .utility
    )

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    self.encoder = encoder

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    self.decoder = decoder

    let loadedProgress = Self.loadProgress(using: userDefaults, decoder: decoder)
    self.progress = Self.sanitizeProgress(loadedProgress)
    self.achievements = Self.sanitizeAchievements(
      Self.loadAchievements(using: userDefaults, decoder: decoder)
    )
    self.masteredRootIDs = Set(progress.masteredRoots)

    updateStudyStreakIfNeeded()
  }

  var masteredCount: Int {
    progress.masteredRoots.count
  }

  var rootsNeededForNextLevel: Int {
    max((progress.level * Constants.rootsPerLevel) - masteredCount, 0)
  }

  func isMastered(rootID: Int) -> Bool {
    masteredRootIDs.contains(rootID)
  }

  func markRootAsMastered(_ rootID: Int) {
    guard !masteredRootIDs.contains(rootID) else {
      return
    }

    progress.masteredRoots.append(rootID)
    masteredRootIDs.insert(rootID)
    progress.totalScore += Constants.pointsPerMastery

    let newLevel = (progress.masteredRoots.count / Constants.rootsPerLevel) + 1
    if newLevel > progress.level {
      progress.level = newLevel
      unlockAchievement(
        id: "level_\(newLevel)",
        type: "level",
        title: "等级 \(newLevel)",
        description: "恭喜升级到 Lv.\(newLevel)！",
        icon: "⭐"
      )
    }

    switch progress.masteredRoots.count {
    case 1:
      unlockAchievement(
        id: "first_root",
        type: "milestone",
        title: "初出茅庐",
        description: "掌握第一个词根",
        icon: "🌱"
      )
    case 50:
      unlockAchievement(
        id: "roots_50",
        type: "milestone",
        title: "小有所成",
        description: "掌握 50 个词根",
        icon: "🎯"
      )
    case 100:
      unlockAchievement(
        id: "roots_100",
        type: "milestone",
        title: "百词宗师",
        description: "掌握 100 个词根",
        icon: "💎"
      )
    default:
      break
    }

    schedulePersistence()
  }

  func setCurrentRootIndex(_ index: Int) {
    let clampedIndex = max(0, index)
    guard progress.currentRootIndex != clampedIndex else {
      return
    }

    progress.currentRootIndex = clampedIndex
    schedulePersistence()
  }

  func updateStudyStreakIfNeeded(now: Date = Date()) {
    let today = calendar.startOfDay(for: now)
    let lastStudy = calendar.startOfDay(for: progress.lastStudyDate)

    guard today != lastStudy else {
      return
    }

    guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
      progress.studyStreak = 1
      progress.lastStudyDate = now
      progress.sessionCount += 1
      schedulePersistence()
      return
    }

    if calendar.isDate(lastStudy, inSameDayAs: yesterday) {
      progress.studyStreak += 1
    } else {
      progress.studyStreak = 1
    }

    progress.lastStudyDate = now
    progress.sessionCount += 1

    if progress.studyStreak == 7 {
      unlockAchievement(
        id: "streak_7",
        type: "streak",
        title: "七日修行",
        description: "连续学习 7 天",
        icon: "🔥"
      )
    } else if progress.studyStreak == 30 {
      unlockAchievement(
        id: "streak_30",
        type: "streak",
        title: "月度大师",
        description: "连续学习 30 天",
        icon: "👑"
      )
    }

    schedulePersistence()
  }

  func clearAll() {
    progress = .initial
    achievements = []
    masteredRootIDs = []
    persistImmediately()
  }

  func exportData() throws -> Data {
    let payload = BackupPayload(
      progress: progress,
      achievements: achievements,
      exportDate: Date()
    )
    return try encoder.encode(payload)
  }

  func importData(_ data: Data) throws {
    let payload = try decoder.decode(BackupPayload.self, from: data)
    progress = Self.sanitizeProgress(payload.progress)
    achievements = Self.sanitizeAchievements(payload.achievements)
    masteredRootIDs = Set(progress.masteredRoots)
    persistImmediately()
  }

  func importDataInBackground(_ data: Data) async throws {
    let payload = try await Self.decodePayloadInBackground(data)
    progress = Self.sanitizeProgress(payload.progress)
    achievements = Self.sanitizeAchievements(payload.achievements)
    masteredRootIDs = Set(progress.masteredRoots)
    persistImmediately()
  }

  func flushPendingWrites() {
    persistImmediately()
  }

  private func unlockAchievement(id: String, type: String, title: String, description: String, icon: String) {
    guard !achievements.contains(where: { $0.id == id }) else {
      return
    }

    let achievement = Achievement(
      id: id,
      type: type,
      title: title,
      description: description,
      icon: icon,
      unlockedAt: Date()
    )
    achievements.append(achievement)
    achievements.sort { $0.unlockedAt < $1.unlockedAt }
  }

  private func schedulePersistence() {
    persistenceWorkItem?.cancel()

    let snapshot = ProgressPersistenceSnapshot(
      progress: progress,
      achievements: achievements
    )
    let defaults = userDefaults

    let workItem = DispatchWorkItem {
      Self.persist(snapshot, to: defaults)
    }

    persistenceWorkItem = workItem
    persistenceQueue.asyncAfter(
      deadline: .now() + progressStorePersistenceDebounceSeconds,
      execute: workItem
    )
  }

  private func persistImmediately() {
    persistenceWorkItem?.cancel()
    persistenceWorkItem = nil

    let snapshot = ProgressPersistenceSnapshot(
      progress: progress,
      achievements: achievements
    )
    let defaults = userDefaults

    persistenceQueue.sync {
      Self.persist(snapshot, to: defaults)
    }
  }

  private nonisolated static func persist(_ snapshot: ProgressPersistenceSnapshot, to defaults: UserDefaults) {
    let encoder = makeEncoder()

    if let progressData = try? encoder.encode(snapshot.progress) {
      defaults.set(progressData, forKey: progressStoreProgressKey)
    }

    if let achievementsData = try? encoder.encode(snapshot.achievements) {
      defaults.set(achievementsData, forKey: progressStoreAchievementsKey)
    }
  }

  private static func loadProgress(using defaults: UserDefaults, decoder: JSONDecoder) -> LearningProgress {
    guard
      let data = defaults.data(forKey: progressStoreProgressKey),
      let decoded = try? decoder.decode(LearningProgress.self, from: data)
    else {
      return .initial
    }

    return decoded
  }

  private static func loadAchievements(using defaults: UserDefaults, decoder: JSONDecoder) -> [Achievement] {
    guard
      let data = defaults.data(forKey: progressStoreAchievementsKey),
      let decoded = try? decoder.decode([Achievement].self, from: data)
    else {
      return []
    }

    return decoded
  }

  private static func sanitizeProgress(_ progress: LearningProgress) -> LearningProgress {
    var sanitized = progress

    var seenMasteredRoots = Set<Int>()
    sanitized.masteredRoots = progress.masteredRoots.filter { rootID in
      rootID >= 0 && seenMasteredRoots.insert(rootID).inserted
    }

    sanitized.level = max(1, progress.level)
    sanitized.currentRootIndex = max(0, progress.currentRootIndex)
    sanitized.totalScore = max(0, progress.totalScore)
    sanitized.studyStreak = max(0, progress.studyStreak)
    sanitized.sessionCount = max(0, progress.sessionCount)

    let minimumLevel = (sanitized.masteredRoots.count / Constants.rootsPerLevel) + 1
    sanitized.level = max(sanitized.level, minimumLevel)

    let minimumScore = sanitized.masteredRoots.count * Constants.pointsPerMastery
    sanitized.totalScore = max(sanitized.totalScore, minimumScore)

    return sanitized
  }

  private static func sanitizeAchievements(_ achievements: [Achievement]) -> [Achievement] {
    var seenAchievementIDs = Set<String>()
    let deduplicated = achievements.filter { achievement in
      seenAchievementIDs.insert(achievement.id).inserted
    }

    return deduplicated.sorted { $0.unlockedAt < $1.unlockedAt }
  }

  private nonisolated static func decodePayloadInBackground(_ data: Data) async throws -> BackupPayload {
    try await Task.detached(priority: .userInitiated) {
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      return try decoder.decode(BackupPayload.self, from: data)
    }
    .value
  }

  private nonisolated static func makeEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    return encoder
  }
}
