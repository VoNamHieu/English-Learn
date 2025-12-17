import Foundation
import SwiftData

@Model
class Word {
    var text: String
    var dateAdded: Date
    
    @Relationship(deleteRule: .cascade)
    var definitions: [Definition] = []
    
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
}

enum MasteryLevel: String, Codable {
    case new = "New"
    case learning = "Learning"
    case familiar = "Familiar"
    case mastered = "Mastered"
}
