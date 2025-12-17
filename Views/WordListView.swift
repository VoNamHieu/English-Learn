import SwiftUI
import SwiftData

struct WordListView: View {
    @Query(sort: \Word.text) private var words: [Word]
    
    var body: some View {
        NavigationStack {
            List(words) { word in
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
            .navigationTitle("My Words")
            .overlay {
                if words.isEmpty {
                    ContentUnavailableView(
                        "No Words Yet",
                        systemImage: "book.closed",
                        description: Text("Import a CSV file to get started")
                    )
                }
            }
        }
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
        .modelContainer(for: [Word.self, Definition.self], inMemory: true)
}
