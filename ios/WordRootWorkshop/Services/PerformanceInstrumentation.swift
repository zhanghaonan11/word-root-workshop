import Foundation
import OSLog

enum PerformanceMetric: String {
  case appStartup = "app.startup"
  case rootsIndexFirstInteractive = "rootsIndex.firstInteractive"
  case flashcardFirstDisplay = "flashcard.firstDisplay"

  fileprivate var signpostName: StaticString {
    switch self {
    case .appStartup:
      return "AppStartup"
    case .rootsIndexFirstInteractive:
      return "RootsIndexFirstInteractive"
    case .flashcardFirstDisplay:
      return "FlashcardFirstDisplay"
    }
  }
}

struct PerformanceSpan {
  let metric: PerformanceMetric
  let start: ContinuousClock.Instant
  #if DEBUG
  let signpostState: OSSignpostIntervalState
  #endif
}

enum PerformanceInstrumentation {
  #if DEBUG
  private static let logger = Logger(subsystem: "com.shan.wordrootworkshop", category: "Performance")
  private static let signposter = OSSignposter(logger: logger)
  #endif

  @inline(__always)
  static func begin(_ metric: PerformanceMetric) -> PerformanceSpan {
    let start = ContinuousClock.now
    #if DEBUG
    let signpostState = signposter.beginInterval(metric.signpostName)
    return PerformanceSpan(metric: metric, start: start, signpostState: signpostState)
    #else
    return PerformanceSpan(metric: metric, start: start)
    #endif
  }

  @inline(__always)
  static func end(_ span: PerformanceSpan, detail: String? = nil) {
    #if DEBUG
    let elapsed = span.start.duration(to: .now).components
    let elapsedMs = Double(elapsed.seconds) * 1000
      + Double(elapsed.attoseconds) / 1_000_000_000_000_000

    if let detail, !detail.isEmpty {
      logger.debug("\(span.metric.rawValue, privacy: .public) \(elapsedMs, format: .fixed(precision: 2))ms \(detail, privacy: .public)")
    } else {
      logger.debug("\(span.metric.rawValue, privacy: .public) \(elapsedMs, format: .fixed(precision: 2))ms")
    }

    signposter.endInterval(span.metric.signpostName, span.signpostState)
    #endif
  }
}
