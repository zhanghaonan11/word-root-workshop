import SwiftUI

struct QuizSectionView: View {
  let quiz: WordQuiz
  let rootID: Int
  let onMastered: () -> Void

  @EnvironmentObject private var progressStore: ProgressStore

  @State private var selectedIndex: Int?
  @State private var submitted = false
  @State private var didMarkMastered = false

  private var isCorrect: Bool {
    selectedIndex == quiz.correctAnswer
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("小测验")
        .font(.headline)

      Text(quiz.question)
        .font(.subheadline)

      VStack(spacing: 8) {
        ForEach(Array(quiz.options.enumerated()), id: \.offset) { index, option in
          Button {
            guard !submitted else { return }
            selectedIndex = index
          } label: {
            HStack {
              Text(option)
                .foregroundStyle(.primary)
              Spacer()
              if selectedIndex == index {
                Image(systemName: "checkmark.circle.fill")
                  .foregroundStyle(.blue)
              }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
          }
          .buttonStyle(.plain)
        }
      }

      Button(submitted ? "再试一次" : "提交答案") {
        if submitted {
          submitted = false
          selectedIndex = nil
          return
        }

        guard selectedIndex != nil else { return }
        submitted = true

        if isCorrect, !didMarkMastered, !progressStore.isMastered(rootID: rootID) {
          didMarkMastered = true
          onMastered()
        }
      }
      .buttonStyle(.borderedProminent)
      .disabled(!submitted && selectedIndex == nil)

      if submitted {
        Label(
          isCorrect ? "回答正确，已计入掌握进度" : "回答不正确，请再试一次",
          systemImage: isCorrect ? "checkmark.seal.fill" : "xmark.octagon.fill"
        )
        .foregroundStyle(isCorrect ? .green : .red)
        .font(.subheadline.weight(.semibold))
      }
    }
    .padding(14)
    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
  }
}
