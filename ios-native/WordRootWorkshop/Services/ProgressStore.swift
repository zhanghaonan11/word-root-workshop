import Foundation

@MainActor
final class ProgressStore: ObservableObject {
  private enum Keys {
    static let progress = "wordRootProgress"
    static let achievements = "wordRootAchievements"
  }

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

  init(userDefaults: UserDefaults = .standard, calendar: Calendar = .current) {
    self.userDefaults = userDefaults
    self.calendar = calendar

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    self.encoder = encoder

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    self.decoder = decoder

    self.progress = Self.loadProgress(using: userDefaults, decoder: decoder)
    self.achievements = Self.loadAchievements(using: userDefaults, decoder: decoder)
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

    saveProgress()
  }

  func setCurrentRootIndex(_ index: Int) {
    progress.currentRootIndex = max(0, index)
    saveProgress()
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
      saveProgress()
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

    saveProgress()
  }

  func clearAll() {
    progress = .initial
    achievements = []
    masteredRootIDs = []
    saveProgress()
    saveAchievements()
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
    progress = payload.progress
    achievements = payload.achievements
    masteredRootIDs = Set(progress.masteredRoots)
    saveProgress()
    saveAchievements()
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
    saveAchievements()
  }

  private func saveProgress() {
    guard let data = try? encoder.encode(progress) else {
      return
    }
    userDefaults.set(data, forKey: Keys.progress)
  }

  private func saveAchievements() {
    guard let data = try? encoder.encode(achievements) else {
      return
    }
    userDefaults.set(data, forKey: Keys.achievements)
  }

  private static func loadProgress(using defaults: UserDefaults, decoder: JSONDecoder) -> LearningProgress {
    guard
      let data = defaults.data(forKey: Keys.progress),
      let decoded = try? decoder.decode(LearningProgress.self, from: data)
    else {
      return .initial
    }

    return decoded
  }

  private static func loadAchievements(using defaults: UserDefaults, decoder: JSONDecoder) -> [Achievement] {
    guard
      let data = defaults.data(forKey: Keys.achievements),
      let decoded = try? decoder.decode([Achievement].self, from: data)
    else {
      return []
    }

    return decoded
  }
}
