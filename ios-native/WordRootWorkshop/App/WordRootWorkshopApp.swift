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
    }
    .onChange(of: scenePhase) { _, newPhase in
      if newPhase == .active {
        progressStore.updateStudyStreakIfNeeded()
      }
    }
  }
}
