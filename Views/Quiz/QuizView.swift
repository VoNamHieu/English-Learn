import SwiftUI
import SwiftData

struct QuizView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Word.text) private var allWords: [Word]
    
    @State private var quizWords: [Word] = []
    @State private var currentIndex = 0
    @State private var selectedAnswer: Int?
    @State private var showResult = false
    @State private var correctCount = 0
    @State private var options: [String] = []
    @State private var quizComplete = false
    
    private let quizSize = 10
    
    var currentWord: Word? {
        guard currentIndex < quizWords.count else { return nil }
        return quizWords[currentIndex]
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if allWords.count < 4 {
                    ContentUnavailableView(
                        "Not Enough Words",
                        systemImage: "book.closed",
                        description: Text("Import at least 4 words to start a quiz")
                    )
                } else if quizWords.isEmpty {
                    startView
                } else if quizComplete {
                    resultView
                } else if let word = currentWord {
                    quizContent(word: word)
                }
            }
            .navigationTitle("Quiz")
        }
    }
    
    var startView: some View {
        VStack(spacing: 24) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
            
            Text("Definition Quiz")
                .font(.title.bold())
            
            Text("Match words with their definitions")
                .foregroundStyle(.secondary)
            
            Button("Start Quiz") {
                startQuiz()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
    
    var resultView: some View {
        VStack(spacing: 24) {
            let percentage = Double(correctCount) / Double(quizWords.count) * 100
            
            Image(systemName: percentage >= 70 ? "star.fill" : "arrow.clockwise")
                .font(.system(size: 64))
                .foregroundStyle(percentage >= 70 ? .yellow : .blue)
            
            Text(percentage >= 70 ? "Great Job!" : "Keep Practicing!")
                .font(.title.bold())
            
            Text("\(correctCount) / \(quizWords.count) correct")
                .font(.title2)
            
            Text("\(Int(percentage))%")
                .font(.largeTitle.bold())
                .foregroundStyle(percentage >= 70 ? .green : .orange)
            
            Button("Try Again") {
                startQuiz()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    func quizContent(word: Word) -> some View {
        VStack(spacing: 24) {
            // Progress
            ProgressView(value: Double(currentIndex), total: Double(quizWords.count))
                .padding(.horizontal)
            
            Text("Question \(currentIndex + 1) of \(quizWords.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            // Word
            VStack(spacing: 8) {
                Text("What does this word mean?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(word.text)
                    .font(.largeTitle.bold())
                
                if let type = word.definitions.first?.type {
                    Text(type.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.secondary.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            
            Spacer()
            
            // Options
            VStack(spacing: 12) {
                ForEach(0..<options.count, id: \.self) { index in
                    OptionButton(
                        text: options[index],
                        isSelected: selectedAnswer == index,
                        isCorrect: showResult ? options[index] == word.definitions.first?.text : nil
                    ) {
                        if !showResult {
                            selectAnswer(index)
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Next button
            if showResult {
                Button(currentIndex < quizWords.count - 1 ? "Next" : "See Results") {
                    nextQuestion()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding()
    }
    
    private func startQuiz() {
        quizWords = Array(allWords.shuffled().prefix(min(quizSize, allWords.count)))
        currentIndex = 0
        correctCount = 0
        quizComplete = false
        selectedAnswer = nil
        showResult = false
        generateOptions()
    }
    
    private func generateOptions() {
        guard let currentWord = currentWord,
              let correctDef = currentWord.definitions.first?.text else { return }
        
        // Get wrong options from other words
        var wrongOptions = allWords
            .filter { $0.text != currentWord.text }
            .compactMap { $0.definitions.first?.text }
            .shuffled()
            .prefix(3)
        
        options = ([correctDef] + wrongOptions).shuffled()
    }
    
    private func selectAnswer(_ index: Int) {
        selectedAnswer = index
        showResult = true
        
        if let word = currentWord,
           options[index] == word.definitions.first?.text {
            correctCount += 1
        }
    }
    
    private func nextQuestion() {
        if currentIndex < quizWords.count - 1 {
            currentIndex += 1
            selectedAnswer = nil
            showResult = false
            generateOptions()
        } else {
            quizComplete = true
        }
    }
}

struct OptionButton: View {
    let text: String
    let isSelected: Bool
    let isCorrect: Bool?
    let action: () -> Void
    
    var backgroundColor: Color {
        if let isCorrect {
            return isCorrect ? .green.opacity(0.2) : (isSelected ? .red.opacity(0.2) : .clear)
        }
        return isSelected ? .blue.opacity(0.2) : .clear
    }
    
    var borderColor: Color {
        if let isCorrect {
            return isCorrect ? .green : (isSelected ? .red : .secondary.opacity(0.3))
        }
        return isSelected ? .blue : .secondary.opacity(0.3)
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if let isCorrect {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : (isSelected ? "xmark.circle.fill" : ""))
                        .foregroundStyle(isCorrect ? .green : .red)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    QuizView()
        .modelContainer(for: [Word.self, Definition.self], inMemory: true)
}
