import SwiftUI
import SwiftData

struct WordListView: View {
    @Query(sort: \Word.text) private var allWords: [Word]
    @Query(sort: \Lesson.sortOrder) private var lessons: [Lesson]

    @State private var selectedLesson: Lesson?
    @State private var showAllLessons = true

    var filteredWords: [Word] {
        if showAllLessons {
            return allWords
        } else if let lesson = selectedLesson {
            return allWords.filter { $0.lesson?.id == lesson.id }
        }
        return allWords
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Lesson filter
                if !lessons.isEmpty {
                    lessonPicker
                }

                // Word list
                List {
                    if showAllLessons && !lessons.isEmpty {
                        // Group by lessons
                        ForEach(lessons) { lesson in
                            let lessonWords = allWords.filter { $0.lesson?.id == lesson.id }
                            if !lessonWords.isEmpty {
                                Section {
                                    ForEach(lessonWords) { word in
                                        WordRow(word: word)
                                    }
                                } header: {
                                    LessonHeader(lesson: lesson)
                                }
                            }
                        }

                        // Words without lesson
                        let orphanWords = allWords.filter { $0.lesson == nil }
                        if !orphanWords.isEmpty {
                            Section("Uncategorized") {
                                ForEach(orphanWords) { word in
                                    WordRow(word: word)
                                }
                            }
                        }
                    } else {
                        // Flat list for single lesson
                        ForEach(filteredWords) { word in
                            WordRow(word: word)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("My Words")
            .overlay {
                if allWords.isEmpty {
                    ContentUnavailableView(
                        "No Words Yet",
                        systemImage: "book.closed",
                        description: Text("Import a CSV file to get started")
                    )
                }
            }
        }
    }

    var lessonPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All button
                Button {
                    showAllLessons = true
                    selectedLesson = nil
                } label: {
                    Text("All")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(showAllLessons ? Color.blue : Color.secondary.opacity(0.15))
                        .foregroundStyle(showAllLessons ? .white : .primary)
                        .clipShape(Capsule())
                }

                // Lesson buttons
                ForEach(lessons) { lesson in
                    Button {
                        showAllLessons = false
                        selectedLesson = lesson
                    } label: {
                        HStack(spacing: 4) {
                            Text(lesson.name)
                            Text("(\(lesson.wordCount))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            !showAllLessons && selectedLesson?.id == lesson.id
                                ? Color.blue
                                : Color.secondary.opacity(0.15)
                        )
                        .foregroundStyle(
                            !showAllLessons && selectedLesson?.id == lesson.id
                                ? .white
                                : .primary
                        )
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct LessonHeader: View {
    let lesson: Lesson

    var body: some View {
        HStack {
            Text(lesson.name)
            Spacer()
            Text("\(lesson.masteredCount)/\(lesson.wordCount) mastered")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct WordRow: View {
    let word: Word

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(word.text)
                    .font(.headline)

                Spacer()

                Text(word.masteryLevel.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(masteryColor(word.masteryLevel).opacity(0.2))
                    .foregroundStyle(masteryColor(word.masteryLevel))
                    .clipShape(Capsule())
            }

            if let firstDef = word.definitions.first {
                Text(firstDef.text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    func masteryColor(_ level: MasteryLevel) -> Color {
        switch level {
        case .new: return .gray
        case .learning: return .orange
        case .familiar: return .blue
        case .mastered: return .green
        }
    }
}

#Preview {
    WordListView()
        .modelContainer(for: [Word.self, Definition.self, Lesson.self], inMemory: true)
}
