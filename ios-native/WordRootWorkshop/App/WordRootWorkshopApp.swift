import SwiftUI

@main
struct WordRootWorkshopApp: App {
  @Environment(\.scenePhase) private var scenePhase

  @StateObject private var repository = WordRootRepository()
  @StateObject private var progressStore = ProgressStore()

  var body: some Scene {
    WindowGroup {
      RootTabView()
        .environmentObject(repository)
        .environmentObject(progressStore)
    }
    .onChange(of: scenePhase) { _, newPhase in
      if newPhase == .active {
        progressStore.updateStudyStreakIfNeeded()
      }
    }
  }
}
