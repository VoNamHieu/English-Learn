import SwiftUI
import SwiftData

struct FlashcardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Word.nextReviewDate) private var allWords: [Word]
    
    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var offset: CGSize = .zero
    @State private var showComplete = false
    
    // Filter due words locally
    var dueWords: [Word] {
        allWords.filter { $0.nextReviewDate <= Date() }
    }
    
    var currentWord: Word? {
        guard currentIndex < dueWords.count else { return nil }
        return dueWords[currentIndex]
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if dueWords.isEmpty {
                    emptyState
                } else if showComplete {
                    completeState
                } else if let word = currentWord {
                    // Progress
                    ProgressView(value: Double(currentIndex), total: Double(dueWords.count))
                        .padding(.horizontal)
                    
                    Text("\(currentIndex + 1) / \(dueWords.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    // Flashcard
                    FlashcardCard(word: word, isFlipped: $isFlipped)
                        .offset(offset)
                        .rotationEffect(.degrees(Double(offset.width / 20)))
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    offset = gesture.translation
                                }
                                .onEnded { gesture in
                                    handleSwipe(gesture.translation.width)
                                }
                        )
                    
                    Spacer()
                    
                    // Instructions
                    HStack(spacing: 40) {
                        VStack {
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.title)
                                .foregroundStyle(.red)
                            Text("Again")
                                .font(.caption)
                        }
                        
                        VStack {
                            Image(systemName: "hand.tap.fill")
                                .font(.title)
                                .foregroundStyle(.blue)
                            Text("Tap to flip")
                                .font(.caption)
                        }
                        
                        VStack {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title)
                                .foregroundStyle(.green)
                            Text("Got it")
                                .font(.caption)
                        }
                    }
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Flashcards")
        }
    }
    
    var emptyState: some View {
        ContentUnavailableView(
            "No Cards Due",
            systemImage: "checkmark.circle.fill",
            description: Text("Great job! Come back later for more review.")
        )
    }
    
    var completeState: some View {
        VStack(spacing: 20) {
            Image(systemName: "party.popper.fill")
                .font(.system(size: 64))
                .foregroundStyle(.yellow)
            
            Text("Session Complete!")
                .font(.title.bold())
            
            Text("You reviewed \(dueWords.count) words")
                .foregroundStyle(.secondary)
            
            Button("Done") {
                currentIndex = 0
                showComplete = false
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private func handleSwipe(_ width: CGFloat) {
        if width > 100 {
            // Swipe right - correct
            markWord(correct: true)
        } else if width < -100 {
            // Swipe left - incorrect
            markWord(correct: false)
        }
        
        withAnimation {
            offset = .zero
            isFlipped = false
        }
    }
    
    private func markWord(correct: Bool) {
        guard let word = currentWord else { return }
        
        word.reviewCount += 1
        if correct {
            word.correctCount += 1
            // Move next review further
            word.nextReviewDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        } else {
            // Review again soon
            word.nextReviewDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        }
        
        try? modelContext.save()
        
        withAnimation {
            if currentIndex < dueWords.count - 1 {
                currentIndex += 1
            } else {
                showComplete = true
            }
        }
    }
}

struct FlashcardCard: View {
    let word: Word
    @Binding var isFlipped: Bool
    
    var body: some View {
        ZStack {
            // Front
            cardFront
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            
            // Back
            cardBack
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .frame(width: 320, height: 400)
        .onTapGesture {
            withAnimation(.spring(duration: 0.4)) {
                isFlipped.toggle()
            }
        }
    }
    
    var cardFront: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Text(word.text)
                .font(.largeTitle.bold())
            
            if let type = word.definitions.first?.type {
                Text(type.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(.secondary.opacity(0.2))
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            Text("Tap to see definition")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 10)
    }
    
    var cardBack: some View {
        VStack(spacing: 16) {
            Text(word.text)
                .font(.title2.bold())
                .foregroundStyle(.secondary)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(word.definitions.enumerated()), id: \.offset) { index, def in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(def.type.rawValue)
                                    .font(.caption.bold())
                                    .foregroundStyle(.blue)
                                
                                Text(def.level.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text(def.text)
                                .font(.body)
                            
                            if let vn = def.vietnamese, !vn.isEmpty {
                                Text(vn)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        if index < word.definitions.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 10)
    }
}

#Preview {
    FlashcardView()
        .modelContainer(for: [Word.self, Definition.self], inMemory: true)
}
