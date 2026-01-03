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
        // Use consolidated SRS algorithm from Word model
        word.updateReview(correct: correct)

        do {
            try modelContext?.save()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }
}
