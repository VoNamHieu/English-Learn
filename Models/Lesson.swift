import Foundation
import SwiftData

@Model
class Lesson {
    var name: String
    var createdAt: Date
    var sortOrder: Int

    @Relationship(deleteRule: .cascade, inverse: \Word.lesson)
    var words: [Word] = []

    var wordCount: Int {
        words.count
    }

    var masteredCount: Int {
        words.filter { $0.masteryLevel == .mastered }.count
    }

    var progress: Double {
        guard wordCount > 0 else { return 0 }
        return Double(masteredCount) / Double(wordCount)
    }

    init(name: String, sortOrder: Int = 0) {
        self.name = name
        self.createdAt = Date()
        self.sortOrder = sortOrder
    }
}
