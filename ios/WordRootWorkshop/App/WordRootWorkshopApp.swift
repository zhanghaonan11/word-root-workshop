import SwiftUI

@main
struct WordRootWorkshopApp: App {
  @Environment(\.scenePhase) private var scenePhase

  @StateObject private var repository = WordRootRepository()
  @StateObject private var progressStore = ProgressStore()
  @StateObject private var pronunciationService = PronunciationService()

  var body: some Scene {
    WindowGroup {
      RootTabView()
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
