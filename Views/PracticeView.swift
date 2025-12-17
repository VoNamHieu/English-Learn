import SwiftUI

struct PracticeView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Learning Modes") {
                    NavigationLink {
                        FlashcardView()
                    } label: {
                        Label("Flashcards", systemImage: "rectangle.on.rectangle")
                    }
                    
                    NavigationLink {
                        QuizView()
                    } label: {
                        Label("Multiple Choice", systemImage: "list.bullet.circle")
                    }
                }
                
                Section("AI Exercises") {
                    NavigationLink {
                        ExerciseView()
                    } label: {
                        Label("Smart Practice", systemImage: "sparkles")
                    }
                }
            }
            .navigationTitle("Practice")
        }
    }
}

#Preview {
    PracticeView()
}
