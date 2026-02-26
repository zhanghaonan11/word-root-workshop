import Foundation

enum WordRootCategory: String, CaseIterable, Identifiable {
  case all
  case prefix
  case root
  case suffix

  var id: String { rawValue }

  var title: String {
    switch self {
    case .all:
      return "全部"
    case .prefix:
      return "前缀"
    case .root:
      return "词根"
    case .suffix:
      return "后缀"
    }
  }
}

struct WordRoot: Codable, Identifiable, Hashable {
  let id: Int
  let root: String
  let origin: String
  let meaning: String
  let meaningEn: String
  let description: String
  let examples: [WordExample]
  let quiz: WordQuiz

  private enum CodingKeys: String, CodingKey {
    case id, root, origin, meaning, meaningEn, description, examples, quiz
  }

  var category: WordRootCategory {
    let lowerRoot = root.lowercased()
    let lowerMeaning = meaning.lowercased()

    if lowerRoot.hasPrefix("-") || lowerRoot.hasPrefix("suffix") || lowerMeaning.contains("后缀") {
      return .suffix
    }

    if lowerRoot.hasSuffix("-") || lowerRoot.contains("-/") || lowerRoot.hasPrefix("prefix") || lowerMeaning.contains("前缀") {
      return .prefix
    }

    return .root
  }
}

struct WordExample: Codable, Hashable {
  let word: String
  let phonetic: String?
  let breakdown: WordBreakdown
  let meaning: String
  let explanation: String

  private enum CodingKeys: String, CodingKey {
    case word, phonetic, breakdown, meaning, explanation
  }
}

struct WordBreakdown: Codable, Hashable {
  let prefix: String
  let root: String
  let suffix: String
}

struct WordQuiz: Codable, Hashable {
  let question: String
  let options: [String]
  let correctAnswer: Int

  var hasValidCorrectAnswer: Bool {
    options.indices.contains(correctAnswer)
  }

  private enum CodingKeys: String, CodingKey {
    case question, options, correctAnswer
  }

  init(question: String, options: [String], correctAnswer: Int) {
    self.question = question
    self.options = options
    self.correctAnswer = correctAnswer
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let question = try container.decode(String.self, forKey: .question)
    let options = try container.decode([String].self, forKey: .options)
    let correctAnswer = try container.decode(Int.self, forKey: .correctAnswer)

    guard !options.isEmpty else {
      throw DecodingError.dataCorruptedError(
        forKey: .options,
        in: container,
        debugDescription: "Quiz options must not be empty."
      )
    }

    guard options.indices.contains(correctAnswer) else {
      throw DecodingError.dataCorruptedError(
        forKey: .correctAnswer,
        in: container,
        debugDescription: "correctAnswer index is out of bounds."
      )
    }

    self.init(question: question, options: options, correctAnswer: correctAnswer)
  }
}
