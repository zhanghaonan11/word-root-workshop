import XCTest
@testable import WordRootWorkshop

final class WordRootWorkshopTests: XCTestCase {
  func testWordRootDecoding() throws {
    let json = """
    [
      {
        "id": 1,
        "root": "spect",
        "origin": "Latin",
        "meaning": "看",
        "meaningEn": "look",
        "description": "spect 表示看",
        "examples": [
          {
            "word": "inspect",
            "breakdown": {
              "prefix": "in",
              "root": "spect",
              "suffix": ""
            },
            "meaning": "检查",
            "explanation": "向内看"
          }
        ],
        "quiz": {
          "question": "inspect 的意思是什么？",
          "options": ["检查", "尊重", "观看", "运输"],
          "correctAnswer": 0
        }
      }
    ]
    """

    let data = try XCTUnwrap(json.data(using: .utf8))
    let roots = try JSONDecoder().decode([WordRoot].self, from: data)

    XCTAssertEqual(roots.count, 1)
    XCTAssertEqual(roots[0].root, "spect")
    XCTAssertEqual(roots[0].examples.first?.word, "inspect")
  }

  func testWordRootDecodingRejectsInvalidQuizAnswerIndex() throws {
    let json = """
    [
      {
        "id": 1,
        "root": "spect",
        "origin": "Latin",
        "meaning": "看",
        "meaningEn": "look",
        "description": "spect 表示看",
        "examples": [
          {
            "word": "inspect",
            "breakdown": {
              "prefix": "in",
              "root": "spect",
              "suffix": ""
            },
            "meaning": "检查",
            "explanation": "向内看"
          }
        ],
        "quiz": {
          "question": "inspect 的意思是什么？",
          "options": ["检查", "尊重"],
          "correctAnswer": 9
        }
      }
    ]
    """

    let data = try XCTUnwrap(json.data(using: .utf8))
    XCTAssertThrowsError(try JSONDecoder().decode([WordRoot].self, from: data))
  }

  @MainActor
  func testProgressStoreAvoidsDuplicateMastery() {
    let defaults = UserDefaults(suiteName: #function)!
    defaults.removePersistentDomain(forName: #function)

    let store = ProgressStore(userDefaults: defaults)
    store.markRootAsMastered(12)
    store.markRootAsMastered(12)

    XCTAssertEqual(store.progress.masteredRoots, [12])
    XCTAssertEqual(store.progress.totalScore, 10)
  }

  @MainActor
  func testStartupIssueHasRepairGuidance() {
    let issue = WordRootRepository.makeStartupIssue(
      from: .resourceMissing(resourceName: "wordRoots.json", bundlePath: "/tmp/mock.bundle")
    )

    XCTAssertEqual(issue.id, "startup_resource_missing")
    XCTAssertTrue(issue.summary.contains("wordRoots.json"))
    XCTAssertTrue(issue.steps.contains(where: { $0.contains("xcodegen") }))
    XCTAssertTrue(issue.diagnostics.contains(where: { $0.contains("/tmp/mock.bundle") }))
  }

  // MARK: - 连学天数测试

  @MainActor
  func testStudyStreakIncrementsOnConsecutiveDays() {
    let defaults = UserDefaults(suiteName: #function)!
    defaults.removePersistentDomain(forName: #function)

    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

    let store = ProgressStore(userDefaults: defaults)
    // 模拟昨天学习过
    store.updateStudyStreakIfNeeded(now: yesterday)
    let streakAfterYesterday = store.progress.studyStreak

    // 今天再学习
    store.updateStudyStreakIfNeeded(now: today)
    XCTAssertEqual(store.progress.studyStreak, streakAfterYesterday + 1,
                   "连续学习天数应该 +1")
  }

  @MainActor
  func testStudyStreakResetsAfterGap() {
    let defaults = UserDefaults(suiteName: #function)!
    defaults.removePersistentDomain(forName: #function)

    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

    let store = ProgressStore(userDefaults: defaults)
    store.updateStudyStreakIfNeeded(now: twoDaysAgo)

    // 隔了一天（中断），今天再学
    store.updateStudyStreakIfNeeded(now: today)
    XCTAssertEqual(store.progress.studyStreak, 1,
                   "中断后连学天数应该重置为 1")
  }

  @MainActor
  func testStudyStreakNoChangeOnSameDay() {
    let defaults = UserDefaults(suiteName: #function)!
    defaults.removePersistentDomain(forName: #function)

    let now = Date()
    let store = ProgressStore(userDefaults: defaults)
    store.updateStudyStreakIfNeeded(now: now)
    let streak = store.progress.studyStreak
    let sessions = store.progress.sessionCount

    // 同一天再次调用
    store.updateStudyStreakIfNeeded(now: now)
    XCTAssertEqual(store.progress.studyStreak, streak,
                   "同一天不应改变连学天数")
    XCTAssertEqual(store.progress.sessionCount, sessions,
                   "同一天不应增加学习次数")
  }

  // MARK: - 导入导出测试

  @MainActor
  func testExportImportRoundTrip() throws {
    let defaults = UserDefaults(suiteName: #function)!
    defaults.removePersistentDomain(forName: #function)

    let store = ProgressStore(userDefaults: defaults)
    store.markRootAsMastered(1)
    store.markRootAsMastered(5)
    store.markRootAsMastered(10)

    let exported = try store.exportData()

    // 清空后导入
    store.clearAll()
    XCTAssertEqual(store.masteredCount, 0)

    try store.importData(exported)
    XCTAssertEqual(store.masteredCount, 3)
    XCTAssertTrue(store.isMastered(rootID: 1))
    XCTAssertTrue(store.isMastered(rootID: 5))
    XCTAssertTrue(store.isMastered(rootID: 10))
  }
}
