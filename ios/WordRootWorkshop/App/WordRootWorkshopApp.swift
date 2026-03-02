import SwiftUI
import OSLog

#if DEBUG
private enum AppStartupPerfLog {
  private static let logger = Logger(subsystem: "com.shan.wordrootworkshop", category: "AppStartupPerf")

  static func mark(_ name: String, from start: ContinuousClock.Instant) {
    let elapsed = start.duration(to: .now).components
    let ms = Double(elapsed.seconds) * 1000 + Double(elapsed.attoseconds) / 1_000_000_000_000_000
    logger.debug("\(name, privacy: .public) +\(ms, format: .fixed(precision: 2))ms")
  }
}
#endif

@main
struct WordRootWorkshopApp: App {
  @Environment(\.scenePhase) private var scenePhase

  #if DEBUG
  private static let launchStart = ContinuousClock.now
  #endif

  @StateObject private var repository = WordRootRepository()
  @StateObject private var progressStore = ProgressStore()
  @StateObject private var pronunciationService = PronunciationService()

  var body: some Scene {
    WindowGroup {
      RootTabView()
        #if DEBUG
        .onAppear {
          AppStartupPerfLog.mark("RootTabView first appear", from: Self.launchStart)
        }
        #endif
        .environmentObject(repository)
        .environmentObject(progressStore)
        .environmentObject(pronunciationService)
        .appTheming()
    }
    .onChange(of: scenePhase) { _, newPhase in
      switch newPhase {
      case .active:
        progressStore.updateStudyStreakIfNeeded()
      case .inactive, .background:
        progressStore.flushPendingWrites()
      @unknown default:
        break
      }
    }
  }
}
