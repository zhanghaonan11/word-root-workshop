import SwiftUI

@main
struct WordRootWorkshopApp: App {
  @Environment(\.scenePhase) private var scenePhase
  @State private var didReportStartup = false

  private static let startupSpan = PerformanceInstrumentation.begin(.appStartup)

  @StateObject private var repository = WordRootRepository()
  @StateObject private var progressStore = ProgressStore()
  @StateObject private var pronunciationService = PronunciationService()

  var body: some Scene {
    WindowGroup {
      RootTabView()
        .onAppear {
          guard !didReportStartup else { return }
          didReportStartup = true
          PerformanceInstrumentation.end(
            Self.startupSpan,
            detail: "RootTabView firstAppear"
          )
        }
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
