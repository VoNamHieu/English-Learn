import Foundation
import SwiftData

@Model
class Word {
    var text: String
    var dateAdded: Date

    @Relationship(deleteRule: .cascade)
    var definitions: [Definition] = []

    // Section relationship
    var section: Section?

    // SRS fields
    var nextReviewDate: Date
    var reviewCount: Int = 0
    var correctCount: Int = 0
    var masteryLevelRaw: String = "New"  // Store as String
    
    // Computed property for enum access
    @Transient
    var masteryLevel: MasteryLevel {
        get { MasteryLevel(rawValue: masteryLevelRaw) ?? .new }
        set { masteryLevelRaw = newValue.rawValue }
    }
    
    var accuracy: Double {
        reviewCount > 0 ? Double(correctCount) / Double(reviewCount) : 0
    }

    init(text: String, dateAdded: Date = Date()) {
        self.text = text
        self.dateAdded = dateAdded
        self.nextReviewDate = dateAdded
    }

    /// Updates review statistics and calculates next review date using SRS algorithm
    func updateReview(correct: Bool) {
        reviewCount += 1
        if correct {
            correctCount += 1
        }

        // SRS algorithm based on accuracy and review count
        let currentAccuracy = accuracy
        if currentAccuracy >= 0.9 && reviewCount >= 5 {
            masteryLevel = .mastered
            nextReviewDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        } else if currentAccuracy >= 0.7 {
            masteryLevel = .familiar
            nextReviewDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        } else if currentAccuracy >= 0.5 {
            masteryLevel = .learning
            nextReviewDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        } else {
            masteryLevel = .new
            nextReviewDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        }
    }
}

enum MasteryLevel: String, Codable {
    case new = "New"
    case learning = "Learning"
    case familiar = "Familiar"
    case mastered = "Mastered"
}
