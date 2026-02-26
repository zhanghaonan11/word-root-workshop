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

      VStack(spacing: 10) {
        ForEach(Array(quiz.options.enumerated()), id: \.offset) { idx, option in
          Button {
            submitAnswer(index: idx)
          } label: {
            HStack(spacing: 10) {
              Text(option)
                .frame(maxWidth: .infinity, alignment: .leading)

              feedbackIcon(for: idx)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .background(answerBackground(for: idx), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
          .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
              .stroke(borderColor(for: idx), lineWidth: 1)
          )
          .disabled(hasSubmitted)
        }
      }

      if hasSubmitted {
        if !quiz.hasValidCorrectAnswer {
          Text("题目数据异常，无法判题。")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.orange)
        } else if selectedAnswer == quiz.correctAnswer {
          Text("回答正确，已记录为掌握。")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.green)
        } else {
          Text("回答错误，正确答案：\(correctOptionText)")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.red)
        }
      }
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(Color(.secondarySystemGroupedBackground))
    )
  }

  @ViewBuilder
  private func feedbackIcon(for index: Int) -> some View {
    if hasSubmitted, quiz.hasValidCorrectAnswer {
      if index == quiz.correctAnswer {
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(.green)
      } else if index == selectedAnswer {
        Image(systemName: "xmark.circle.fill")
          .foregroundStyle(.red)
      }
    } else if selectedAnswer == index {
      Image(systemName: "checkmark")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)
    }
  }

  private func borderColor(for index: Int) -> Color {
    guard hasSubmitted else {
      return selectedAnswer == index ? Color.accentColor.opacity(0.35) : Color(.separator).opacity(0.20)
    }

    if quiz.hasValidCorrectAnswer, index == quiz.correctAnswer {
      return Color.green.opacity(0.35)
    }

    if index == selectedAnswer {
      return Color.red.opacity(0.30)
    }

    return Color(.separator).opacity(0.18)
  }

  private func answerBackground(for index: Int) -> Color {
    guard hasSubmitted else {
      return Color(.systemBackground)
    }

    if quiz.hasValidCorrectAnswer, index == quiz.correctAnswer {
      return Color.green.opacity(0.14)
    }

    if index == selectedAnswer {
      return Color.red.opacity(0.12)
    }

    return Color(.systemBackground)
  }

  private func submitAnswer(index: Int) {
    guard !hasSubmitted else { return }

    selectedAnswer = index
    hasSubmitted = true

    if quiz.hasValidCorrectAnswer, index == quiz.correctAnswer {
      onCorrect()
    }
  }

  private var correctOptionText: String {
    guard quiz.hasValidCorrectAnswer else { return "（无）" }
    return quiz.options[quiz.correctAnswer]
  }
}
