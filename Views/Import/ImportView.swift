import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var isImporting = false
    @State private var importedCount = 0
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Icon
                Image(systemName: "doc.text")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)
                
                // Title
                Text("Import Vocabulary")
                    .font(.title.bold())
                
                // Description
                Text("Import a CSV file with your vocabulary words.\nRequired columns: Word, Type, Definition, Level")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Import Button
                Button {
                    isImporting = true
                } label: {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "square.and.arrow.down")
                        }
                        Text(isProcessing ? "Processing..." : "Choose CSV File")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isProcessing)
                .padding(.horizontal, 32)
                
                // Error message
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // CSV Format hint
                VStack(alignment: .leading, spacing: 8) {
                    Text("CSV Format Example:")
                        .font(.caption.bold())
                    Text("Word,Type,Definition,Level,Vietnamese")
                        .font(.caption.monospaced())
                    Text("persistent,adjective,continuing to exist...,B2,kiên trì")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [UTType.commaSeparatedText, UTType.text],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .alert("Import Successful", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Imported \(importedCount) words successfully!")
            }
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            isProcessing = true
            errorMessage = nil
            
            Task {
                do {
                    // Request access to the file
                    guard url.startAccessingSecurityScopedResource() else {
                        throw ImportError.accessDenied
                    }
                    defer { url.stopAccessingSecurityScopedResource() }
                    
                    // Read file content
                    let content = try String(contentsOf: url, encoding: .utf8)
                    
                    // Parse CSV
                    let words = try CSVParser.parse(content)
                    
                    // Validate and filter words with empty definitions
                    let validWords = words.filter { !$0.definition.trimmingCharacters(in: .whitespaces).isEmpty }

                    guard !validWords.isEmpty else {
                        throw ImportError.noValidWords
                    }

                    // Save to SwiftData
                    await MainActor.run {
                        var savedCount = 0
                        for wordData in validWords {
                            // Check if word already exists
                            let existingWord = fetchWord(text: wordData.text)

                            if let existing = existingWord {
                                // Add new definition to existing word
                                let definition = Definition(
                                    text: wordData.definition,
                                    type: wordData.type,
                                    level: wordData.level,
                                    vietnamese: wordData.vietnamese
                                )
                                definition.synonyms = wordData.synonyms
                                existing.definitions.append(definition)
                            } else {
                                // Create new word
                                let word = Word(text: wordData.text, dateAdded: wordData.dateAdded)
                                let definition = Definition(
                                    text: wordData.definition,
                                    type: wordData.type,
                                    level: wordData.level,
                                    vietnamese: wordData.vietnamese
                                )
                                definition.synonyms = wordData.synonyms
                                word.definitions.append(definition)
                                modelContext.insert(word)
                            }
                            savedCount += 1
                        }

                        do {
                            try modelContext.save()
                            importedCount = savedCount
                            isProcessing = false
                            showSuccess = true
                        } catch {
                            errorMessage = "Failed to save: \(error.localizedDescription)"
                            isProcessing = false
                        }
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = "Import failed: \(error.localizedDescription)"
                        isProcessing = false
                    }
                }
            }
            
        case .failure(let error):
            errorMessage = "Could not access file: \(error.localizedDescription)"
        }
    }
    
    private func fetchWord(text: String) -> Word? {
        let descriptor = FetchDescriptor<Word>(
            predicate: #Predicate { $0.text == text }
        )
        return try? modelContext.fetch(descriptor).first
    }
}

enum ImportError: LocalizedError {
    case accessDenied
    case invalidFormat
    case noValidWords

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Cannot access the file"
        case .invalidFormat:
            return "Invalid CSV format"
        case .noValidWords:
            return "No valid words found. Each word must have a non-empty definition."
        }
    }
}

#Preview {
    ImportView()
        .modelContainer(for: [Word.self, Definition.self], inMemory: true)
}
