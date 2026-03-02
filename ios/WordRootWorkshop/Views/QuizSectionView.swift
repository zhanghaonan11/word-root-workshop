import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct QuizSectionView: View {
  let quiz: WordQuiz
  let onCorrect: () -> Void
  let onSubmitResult: ((Bool) -> Void)?

  private enum FeedbackState {
    case idle
    case invalid
    case correct
    case incorrect
  }

  @State private var selectedAnswer: Int?
  @State private var feedbackState: FeedbackState = .idle

  init(quiz: WordQuiz, onCorrect: @escaping () -> Void, onSubmitResult: ((Bool) -> Void)? = nil) {
    self.quiz = quiz
    self.onCorrect = onCorrect
    self.onSubmitResult = onSubmitResult
  }

  var body: some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.item) {
      Text("小测试")
        .font(.headline)

      Text(quiz.question)
        .font(.title3.weight(.semibold))

      VStack(spacing: DesignSystem.Spacing.compact) {
        ForEach(Array(quiz.options.enumerated()), id: \.offset) { idx, option in
          Button {
            selectAnswer(index: idx)
          } label: {
            HStack(spacing: DesignSystem.Spacing.compact) {
              Text(option)
                .frame(maxWidth: .infinity, alignment: .leading)

              feedbackIcon(for: idx)
            }
            .padding(.vertical, DesignSystem.Spacing.item)
            .padding(.horizontal, DesignSystem.Spacing.item)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .background(answerBackground(for: idx), in: RoundedRectangle(cornerRadius: DesignSystem.Radius.control, style: .continuous))
          .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.control, style: .continuous)
              .stroke(borderColor(for: idx), lineWidth: 1)
          )
          .disabled(isSubmitted)
        }
      }
      .animation(DesignSystem.Motion.standard, value: selectedAnswer)
      .animation(DesignSystem.Motion.standard, value: isSubmitted)

      HStack(spacing: DesignSystem.Spacing.compact) {
        Button {
          submitSelectedAnswer()
        } label: {
          Label("提交答案", systemImage: "checkmark.circle.fill")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(selectedAnswer == nil || isSubmitted)

        if isSubmitted {
          Button {
            resetQuiz()
          } label: {
            Label("重做", systemImage: "arrow.counterclockwise")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.bordered)
          .controlSize(.large)
        }
      }
      .font(.subheadline.weight(.semibold))

      feedbackBanner
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 24, alignment: .topLeading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("答题反馈")
        .accessibilityValue(feedbackAccessibilityValue)
    }
    .cardBackground()
    .onChange(of: quiz) { _, _ in
      resetQuiz()
    }
  }

  private var isSubmitted: Bool {
    feedbackState != .idle
  }

  @ViewBuilder
  private var feedbackBanner: some View {
    if isSubmitted {
      switch feedbackState {
      case .invalid:
        Text("题目数据异常，无法判题。")
          .font(.subheadline.weight(.medium))
          .foregroundStyle(.orange)
      case .correct:
        Text("回答正确，已记录为掌握。")
          .font(.subheadline.weight(.medium))
          .foregroundStyle(.green)
      case .incorrect:
        Text("回答错误，正确答案：\(correctOptionText)")
          .font(.subheadline.weight(.medium))
          .foregroundStyle(.red)
      case .idle:
        EmptyView()
      }
    } else {
      Text("选择一个答案后点击“提交答案”。")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
  }

  @ViewBuilder
  private func feedbackIcon(for index: Int) -> some View {
    if isSubmitted, quiz.hasValidCorrectAnswer {
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
    guard isSubmitted else {
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
    guard isSubmitted else {
      if index == selectedAnswer {
        return Color.accentColor.opacity(0.10)
      }
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

  private func selectAnswer(index: Int) {
    guard !isSubmitted else { return }
    selectedAnswer = index
    hapticSelection()
  }

  private func submitSelectedAnswer() {
    guard !isSubmitted else { return }
    guard let selectedAnswer else { return }

    let isCorrect = quiz.hasValidCorrectAnswer && selectedAnswer == quiz.correctAnswer

    if !quiz.hasValidCorrectAnswer {
      feedbackState = .invalid
    } else if isCorrect {
      feedbackState = .correct
      onCorrect()
    } else {
      feedbackState = .incorrect
    }

    onSubmitResult?(isCorrect)
    hapticResult(isCorrect: isCorrect)
  }

  private func resetQuiz() {
    selectedAnswer = nil
    feedbackState = .idle
  }

  private var feedbackAccessibilityValue: String {
    switch feedbackState {
    case .idle:
      return "未提交"
    case .invalid:
      return "题目数据异常"
    case .correct:
      return "回答正确"
    case .incorrect:
      return "回答错误"
    }
  }

  private func hapticSelection() {
    #if canImport(UIKit)
    let generator = UISelectionFeedbackGenerator()
    generator.selectionChanged()
    #endif
  }

  private func hapticResult(isCorrect: Bool) {
    #if canImport(UIKit)
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(isCorrect ? .success : .error)
    #endif
  }

  private var correctOptionText: String {
    guard quiz.hasValidCorrectAnswer else { return "（无）" }
    return quiz.options[quiz.correctAnswer]
  }
}
