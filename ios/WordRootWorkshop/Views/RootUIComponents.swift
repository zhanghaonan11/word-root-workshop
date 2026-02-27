import AVFoundation
import SwiftUI

@MainActor
final class PronunciationService: ObservableObject {
  private let synthesizer = AVSpeechSynthesizer()

  func speak(_ text: String) {
    let cleanedText = Self.cleanForSpeech(text)
    guard !cleanedText.isEmpty else { return }

    if synthesizer.isSpeaking {
      synthesizer.stopSpeaking(at: .immediate)
    }

    let utterance = AVSpeechUtterance(string: cleanedText)
    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
    utterance.rate = 0.45
    synthesizer.speak(utterance)
  }

  private static func cleanForSpeech(_ text: String) -> String {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return "" }

    let withoutSymbols = trimmed.replacingOccurrences(
      of: #"[^A-Za-z\-\s']"#,
      with: " ",
      options: .regularExpression
    )
    let normalizedWhitespace = withoutSymbols.replacingOccurrences(
      of: #"\s+"#,
      with: " ",
      options: .regularExpression
    )
    return normalizedWhitespace.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

struct BreakdownChipsView: View {
  let breakdown: WordBreakdown

  var body: some View {
    HStack(spacing: DesignSystem.Spacing.tight) {
      if !breakdown.prefix.isEmpty {
        MorphChip(text: breakdown.prefix, color: .red)
      }

      if !breakdown.root.isEmpty {
        MorphChip(text: breakdown.root, color: .blue)
      }

      if !breakdown.suffix.isEmpty {
        MorphChip(text: breakdown.suffix, color: .orange)
      }
    }
  }
}

private struct MorphChip: View {
  let text: String
  let color: Color

  var body: some View {
    Text(text)
      .font(.system(.caption, design: .monospaced).weight(.semibold))
      .padding(.horizontal, DesignSystem.Spacing.compact)
      .padding(.vertical, DesignSystem.Spacing.xSmall)
      .foregroundStyle(color)
      .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: DesignSystem.Radius.chip, style: .continuous))
  }
}

struct ExampleCardView: View {
  let example: WordExample
  @EnvironmentObject private var pronunciationService: PronunciationService

  @State private var isExpanded = true

  private var normalizedPhonetic: String? {
    guard let phonetic = example.phonetic?.trimmingCharacters(in: .whitespacesAndNewlines),
          !phonetic.isEmpty else {
      return nil
    }
    return phonetic
  }

  var body: some View {
    DisclosureGroup(isExpanded: $isExpanded) {
      VStack(alignment: .leading, spacing: DesignSystem.Spacing.item) {
        BreakdownChipsView(breakdown: example.breakdown)

        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
          Text(example.meaning)
            .font(.headline)
          Text(example.explanation)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
      }
      .padding(.top, DesignSystem.Spacing.tight)
    } label: {
      HStack(alignment: .firstTextBaseline, spacing: DesignSystem.Spacing.compact) {
        Text(example.word)
          .font(.headline)
          .foregroundStyle(.primary)

        Button {
          pronunciationService.speak(example.word)
        } label: {
          Image(systemName: "speaker.wave.2.fill")
            .font(.subheadline.weight(.semibold))
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.tint)
        .accessibilityLabel("发音")
        .accessibilityHint("朗读单词发音")

        Spacer(minLength: 0)

        Text(normalizedPhonetic ?? "")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
    .accentColor(DesignSystem.Theme.accent)
    .padding(DesignSystem.Spacing.section)
    .background(
      RoundedRectangle(cornerRadius: DesignSystem.Radius.card, style: .continuous)
        .fill(Color(.secondarySystemGroupedBackground))
    )
    .cardBorder()
    .animation(DesignSystem.Motion.standard, value: isExpanded)
  }
}
