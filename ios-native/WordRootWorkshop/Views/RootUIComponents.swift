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
    HStack(spacing: 8) {
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
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .foregroundStyle(color)
      .background(color.opacity(0.12))
      .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .stroke(color.opacity(0.25), lineWidth: 1)
      )
  }
}

struct ExampleCardView: View {
  let example: WordExample

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      VStack(alignment: .leading, spacing: 4) {
        Text(example.word)
          .font(.title3.weight(.bold))

        if let phonetic = example.phonetic, !phonetic.isEmpty {
          Text(phonetic)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
      }

      BreakdownChipsView(breakdown: example.breakdown)
      Text(example.meaning)
        .font(.headline)
      Text(example.explanation)
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .fill(Color(.systemBackground))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
    )
  }
}
