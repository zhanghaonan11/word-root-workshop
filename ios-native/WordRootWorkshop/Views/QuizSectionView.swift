import SwiftUI

struct QuizSectionView: View {
  let quiz: WordQuiz
  let rootID: Int
  let onCorrect: () -> Void

  @State private var selectedAnswer: Int?
  @State private var hasSubmitted = false

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("小测试")
        .font(.headline)

      Text(quiz.question)
        .font(.title3.weight(.semibold))

      ForEach(Array(quiz.options.enumerated()), id: \.offset) { idx, option in
        Button {
          submitAnswer(index: idx)
        } label: {
          HStack {
            Text(option)
              .frame(maxWidth: .infinity, alignment: .leading)
            feedbackIcon(for: idx)
          }
          .padding(12)
          .background(answerBackground(for: idx))
          .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(hasSubmitted)
      }

      if hasSubmitted {
        if selectedAnswer == quiz.correctAnswer {
          Text("回答正确，已记录为掌握。")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.green)
        } else {
          Text("回答错误，正确答案：\(quiz.options[quiz.correctAnswer])")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.red)
        }
      }
    }
    .padding(14)
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
  }

  @ViewBuilder
  private func feedbackIcon(for index: Int) -> some View {
    if hasSubmitted {
      if index == quiz.correctAnswer {
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(.green)
      } else if index == selectedAnswer {
        Image(systemName: "xmark.circle.fill")
          .foregroundStyle(.red)
      }
    }
  }

  private func answerBackground(for index: Int) -> Color {
    guard hasSubmitted else {
      return Color(.systemBackground)
    }

    if index == quiz.correctAnswer {
      return Color.green.opacity(0.18)
    }

    if index == selectedAnswer {
      return Color.red.opacity(0.16)
    }

    return Color(.systemBackground)
  }

  private func submitAnswer(index: Int) {
    guard !hasSubmitted else { return }

    selectedAnswer = index
    hasSubmitted = true

    if index == quiz.correctAnswer {
      onCorrect()
    }
  }

  func resetState() {
    selectedAnswer = nil
    hasSubmitted = false
  }
}
