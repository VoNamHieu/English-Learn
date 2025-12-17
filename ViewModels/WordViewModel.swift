import Foundation
import SwiftData
import SwiftUI

@Observable
class WordViewModel {
    var words: [Word] = []
    var isLoading = false
    var errorMessage: String?
    
    private var modelContext: ModelContext?
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchWords()
    }
    
    func fetchWords() {
        guard let modelContext else { return }
        
        let descriptor = FetchDescriptor<Word>(
            sortBy: [SortDescriptor(\.text)]
        )
        
        do {
            words = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func wordsDueForReview() -> [Word] {
        words.filter { $0.nextReviewDate <= Date() }
    }
    
    func updateMastery(for word: Word, correct: Bool) {
        word.reviewCount += 1
        if correct {
            word.correctCount += 1
        }
        
        // Simple SRS logic
        let accuracy = word.accuracy
        if accuracy >= 0.9 && word.reviewCount >= 5 {
            word.masteryLevel = .mastered
            word.nextReviewDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        } else if accuracy >= 0.7 {
            word.masteryLevel = .familiar
            word.nextReviewDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        } else if accuracy >= 0.5 {
            word.masteryLevel = .learning
            word.nextReviewDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        } else {
            word.masteryLevel = .new
            word.nextReviewDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        }
        
        try? modelContext?.save()
    }
}
