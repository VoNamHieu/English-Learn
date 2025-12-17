import SwiftUI
import SwiftData

struct ExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExerciseGroup.generatedAt, order: .reverse) private var exerciseGroups: [ExerciseGroup]
    @Query private var words: [Word]
    
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var selectedGroup: ExerciseGroup?
    
    var body: some View {
        NavigationStack {
            List {
                if exerciseGroups.isEmpty {
                    Section {
                        generatePrompt
                    }
                } else {
                    Section("Your Exercise Sets") {
                        ForEach(exerciseGroups) { group in
                            NavigationLink {
                                ExerciseSessionView(group: group)
                            } label: {
                                ExerciseGroupRow(group: group)
                            }
                        }
                        .onDelete(perform: deleteGroups)
                    }
                    
                    Section {
                        generateButton
                    }
                }
            }
            .navigationTitle("AI Exercises")
            .overlay {
                if isGenerating {
                    generatingOverlay
                }
            }
            .alert("Error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    var generatePrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(.purple)
            
            Text("Generate AI Exercises")
                .font(.headline)
            
            Text("Create personalized exercises based on your vocabulary")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            generateButton
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    var generateButton: some View {
        Button {
            generateExercises()
        } label: {
            HStack {
                Image(systemName: "sparkles")
                Text("Generate New Exercises")
            }
        }
        .disabled(words.isEmpty || isGenerating)
    }
    
    var generatingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                
                Text("Generating exercises...")
                    .font(.headline)
                
                Text("AI is analyzing your vocabulary")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private func generateExercises() {
        isGenerating = true
        
        Task {
            do {
                _ = try await ExerciseGenerator.shared.generateExercises(
                    for: Array(words),
                    modelContext: modelContext
                )
                
                await MainActor.run {
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isGenerating = false
                }
            }
        }
    }
    
    private func deleteGroups(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(exerciseGroups[index])
        }
    }
}

struct ExerciseGroupRow: View {
    let group: ExerciseGroup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(group.name)
                .font(.headline)
            
            HStack {
                Label("\(group.exercises.count) exercises", systemImage: "list.bullet")
                
                Spacer()
                
                Text(group.generatedAt, style: .date)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct ExerciseSessionView: View {
    let group: ExerciseGroup
    
    @Environment(\.modelContext) private var modelContext
    @State private var currentIndex = 0
    @State private var userAnswer = ""
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var sessionComplete = false
    @State private var correctCount = 0
    
    var currentExercise: Exercise? {
        guard currentIndex < group.exercises.count else { return nil }
        return group.exercises[currentIndex]
    }
    
    var body: some View {
        VStack {
            if sessionComplete {
                completeView
            } else if let exercise = currentExercise {
                exerciseContent(exercise)
            }
        }
        .navigationTitle(group.name)
    }
    
    var completeView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            
            Text("Exercise Complete!")
                .font(.title.bold())
            
            Text("\(correctCount) / \(group.exercises.count) correct")
                .font(.title2)
        }
    }
    
    func exerciseContent(_ exercise: Exercise) -> some View {
        VStack(spacing: 24) {
            // Progress
            ProgressView(value: Double(currentIndex), total: Double(group.exercises.count))
                .padding(.horizontal)
            
            Spacer()
            
            // Instruction
            Text(exercise.instruction)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            // Sentence with blank
            Text(exercise.sentence.replacingOccurrences(of: "___", with: "______"))
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding()
            
            // Hint
            if let hint = exercise.hint {
                Text("Hint: \(hint)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Answer input
            if exercise.type == .fillBlank {
                TextField("Type your answer", text: $userAnswer)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 32)
                    .autocapitalization(.none)
                    .disabled(showResult)
            } else if let options = exercise.options {
                ForEach(options, id: \.self) { option in
                    Button {
                        userAnswer = option
                        checkAnswer()
                    } label: {
                        Text(option)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                userAnswer == option
                                    ? (showResult ? (isCorrect ? Color.green.opacity(0.2) : Color.red.opacity(0.2)) : Color.blue.opacity(0.2))
                                    : Color.secondary.opacity(0.1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .disabled(showResult)
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Result or Submit
            if showResult {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        Text(isCorrect ? "Correct!" : "Incorrect")
                    }
                    .font(.headline)
                    .foregroundStyle(isCorrect ? .green : .red)
                    
                    if !isCorrect {
                        Text("Answer: \(exercise.answer)")
                            .font(.subheadline)
                    }
                    
                    Button(currentIndex < group.exercises.count - 1 ? "Next" : "Finish") {
                        nextExercise()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if exercise.type == .fillBlank {
                Button("Check Answer") {
                    checkAnswer()
                }
                .buttonStyle(.borderedProminent)
                .disabled(userAnswer.isEmpty)
            }
        }
        .padding()
    }
    
    private func checkAnswer() {
        guard let exercise = currentExercise else { return }
        
        isCorrect = userAnswer.lowercased().trimmingCharacters(in: .whitespaces) ==
                    exercise.answer.lowercased().trimmingCharacters(in: .whitespaces)
        
        if isCorrect {
            correctCount += 1
        }
        
        // Update exercise stats
        exercise.timesShown += 1
        if isCorrect {
            exercise.timesCorrect += 1
        }
        exercise.lastShownAt = Date()
        try? modelContext.save()
        
        showResult = true
    }
    
    private func nextExercise() {
        if currentIndex < group.exercises.count - 1 {
            currentIndex += 1
            userAnswer = ""
            showResult = false
            isCorrect = false
        } else {
            sessionComplete = true
        }
    }
}

#Preview {
    ExerciseView()
        .modelContainer(for: [Word.self, Definition.self, ExerciseGroup.self, Exercise.self], inMemory: true)
}
