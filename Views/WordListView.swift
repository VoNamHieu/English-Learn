import SwiftUI
import SwiftData

struct WordListView: View {
    @Query(sort: \Word.text) private var allWords: [Word]
    @Query(sort: \Section.sortOrder) private var sections: [Section]

    @State private var selectedSection: Section?
    @State private var showAllSections = true

    var filteredWords: [Word] {
        if showAllSections {
            return allWords
        } else if let section = selectedSection {
            return allWords.filter { $0.section?.id == section.id }
        }
        return allWords
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Section filter
                if !sections.isEmpty {
                    sectionPicker
                }

                // Word list
                List {
                    if showAllSections && !sections.isEmpty {
                        // Group by sections
                        ForEach(sections) { section in
                            let sectionWords = allWords.filter { $0.section?.id == section.id }
                            if !sectionWords.isEmpty {
                                Section {
                                    ForEach(sectionWords) { word in
                                        WordRow(word: word)
                                    }
                                } header: {
                                    SectionHeader(section: section)
                                }
                            }
                        }

                        // Words without section
                        let orphanWords = allWords.filter { $0.section == nil }
                        if !orphanWords.isEmpty {
                            Section("Uncategorized") {
                                ForEach(orphanWords) { word in
                                    WordRow(word: word)
                                }
                            }
                        }
                    } else {
                        // Flat list for single section
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

    var sectionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All button
                Button {
                    showAllSections = true
                    selectedSection = nil
                } label: {
                    Text("All")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(showAllSections ? Color.blue : Color.secondary.opacity(0.15))
                        .foregroundStyle(showAllSections ? .white : .primary)
                        .clipShape(Capsule())
                }

                // Section buttons
                ForEach(sections) { section in
                    Button {
                        showAllSections = false
                        selectedSection = section
                    } label: {
                        HStack(spacing: 4) {
                            Text(section.name)
                            Text("(\(section.wordCount))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            !showAllSections && selectedSection?.id == section.id
                                ? Color.blue
                                : Color.secondary.opacity(0.15)
                        )
                        .foregroundStyle(
                            !showAllSections && selectedSection?.id == section.id
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

struct SectionHeader: View {
    let section: Section

    var body: some View {
        HStack {
            Text(section.name)
            Spacer()
            Text("\(section.masteredCount)/\(section.wordCount) mastered")
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
        .modelContainer(for: [Word.self, Definition.self, Section.self], inMemory: true)
}
