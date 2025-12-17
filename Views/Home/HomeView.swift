import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var words: [Word]
    
    @State private var showImport = false
    @State private var navigateToFlashcard = false
    @State private var navigateToExercise = false
    
    var dueWords: [Word] {
        words.filter { $0.nextReviewDate <= Date() }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Stats Card
                    StatsCard(
                        totalWords: words.count,
                        masteredWords: words.filter { $0.masteryLevel == .mastered }.count,
                        dueToday: dueWords.count
                    )
                    
                    // Quick Actions
                    VStack(spacing: 12) {
                        if words.isEmpty {
                            ImportPromptCard {
                                showImport = true
                            }
                        } else {
                            NavigationLink {
                                FlashcardView()
                            } label: {
                                QuickActionCard(
                                    title: "Start Learning",
                                    subtitle: "\(dueWords.count) words due",
                                    icon: "play.fill",
                                    color: .blue
                                )
                            }
                            .buttonStyle(.plain)
                            
                            NavigationLink {
                                ExerciseView()
                            } label: {
                                QuickActionCard(
                                    title: "Generate Exercises",
                                    subtitle: "AI-powered practice",
                                    icon: "sparkles",
                                    color: .purple
                                )
                            }
                            .buttonStyle(.plain)
                            
                            NavigationLink {
                                QuizView()
                            } label: {
                                QuickActionCard(
                                    title: "Quick Quiz",
                                    subtitle: "Test your knowledge",
                                    icon: "questionmark.circle",
                                    color: .orange
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("English Learn")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        showImport = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showImport) {
                ImportView()
            }
        }
    }
}

// MARK: - Components

struct StatsCard: View {
    let totalWords: Int
    let masteredWords: Int
    let dueToday: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                StatItem(value: "\(totalWords)", label: "Total", icon: "book.fill", color: .blue)
                StatItem(value: "\(masteredWords)", label: "Mastered", icon: "checkmark.seal.fill", color: .green)
                StatItem(value: "\(dueToday)", label: "Due Today", icon: "clock.fill", color: .orange)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ImportPromptCard: View {
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 48))
                .foregroundStyle(.blue)
            
            Text("Import Your Vocabulary")
                .font(.headline)
            
            Text("Start by importing a CSV file with your words")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Import CSV", action: action)
                .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Word.self, Definition.self], inMemory: true)
}
