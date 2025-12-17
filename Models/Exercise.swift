import Foundation
import SwiftData

@Model
class ExerciseGroup {
    var id: String
    var name: String
    var wordIds: [String]  // Store word texts
    var generatedAt: Date
    
    @Relationship(deleteRule: .cascade)
    var exercises: [Exercise] = []
    
    init(id: String, name: String, wordIds: [String]) {
        self.id = id
        self.name = name
        self.wordIds = wordIds
        self.generatedAt = Date()
    }
}

@Model
class Exercise {
    var id: String
    var type: ExerciseType
    var instruction: String
    var sentence: String
    var answer: String
    var hint: String?
    var options: [String]?  // For multiple choice
    var difficulty: String
    
    // Tracking
    var timesShown: Int = 0
    var timesCorrect: Int = 0
    var lastShownAt: Date?
    
    var group: ExerciseGroup?
    
    var accuracy: Double {
        timesShown > 0 ? Double(timesCorrect) / Double(timesShown) : 0
    }
    
    init(id: String, type: ExerciseType, instruction: String, sentence: String, answer: String, hint: String? = nil, options: [String]? = nil, difficulty: String = "B2") {
        self.id = id
        self.type = type
        self.instruction = instruction
        self.sentence = sentence
        self.answer = answer
        self.hint = hint
        self.options = options
        self.difficulty = difficulty
    }
}

enum ExerciseType: String, Codable {
    case fillBlank = "fill_blank"
    case multipleChoice = "multiple_choice"
    case wordGroupParagraph = "word_group_paragraph"
    case confusionPair = "confusion_pair"
}
