import Foundation

struct CSVParser {
    struct ParsedWord {
        let text: String
        let type: WordType
        let definition: String
        let level: CEFRLevel
        let vietnamese: String?
        let synonyms: [String]
        let dateAdded: Date
    }
    
    static func parse(_ content: String) throws -> [ParsedWord] {
        var results: [ParsedWord] = []
        
        // Split into lines
        let lines = content.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        guard lines.count > 1 else {
            throw CSVError.emptyFile
        }
        
        // Parse header
        let header = parseCSVLine(lines[0]).map { $0.lowercased() }
        
        // Find column indices
        guard let wordIndex = header.firstIndex(of: "word"),
              let typeIndex = header.firstIndex(of: "type"),
              let definitionIndex = header.firstIndex(of: "definition") else {
            throw CSVError.missingRequiredColumns
        }
        
        let levelIndex = header.firstIndex(of: "level")
        let vietnameseIndex = header.firstIndex(of: "vietnamese")
        let synonymIndex = header.firstIndex(of: "synonym")
        let dateIndex = header.firstIndex(of: "date added")
        
        // Parse data rows
        for i in 1..<lines.count {
            let columns = parseCSVLine(lines[i])
            
            guard columns.count > max(wordIndex, typeIndex, definitionIndex) else {
                continue // Skip invalid rows
            }
            
            let word = columns[wordIndex].trimmingCharacters(in: .whitespaces)
            guard !word.isEmpty else { continue }
            
            let typeString = columns[typeIndex].trimmingCharacters(in: .whitespaces)
            let definition = columns[definitionIndex].trimmingCharacters(in: .whitespaces)
            
            let level: CEFRLevel
            if let idx = levelIndex, columns.count > idx {
                level = CEFRLevel.from(columns[idx])
            } else {
                level = .B2
            }
            
            let vietnamese: String?
            if let idx = vietnameseIndex, columns.count > idx {
                let v = columns[idx].trimmingCharacters(in: .whitespaces)
                vietnamese = v.isEmpty ? nil : v
            } else {
                vietnamese = nil
            }
            
            let synonyms: [String]
            if let idx = synonymIndex, columns.count > idx {
                let s = columns[idx].trimmingCharacters(in: .whitespaces)
                synonyms = s.isEmpty ? [] : s.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            } else {
                synonyms = []
            }
            
            let dateAdded: Date
            if let idx = dateIndex, columns.count > idx {
                dateAdded = parseDate(columns[idx]) ?? Date()
            } else {
                dateAdded = Date()
            }
            
            let parsedWord = ParsedWord(
                text: word,
                type: WordType.from(typeString),
                definition: definition,
                level: level,
                vietnamese: vietnamese,
                synonyms: synonyms,
                dateAdded: dateAdded
            )
            
            results.append(parsedWord)
        }
        
        return results
    }
    
    // Handle CSV with quoted fields
    private static func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var insideQuotes = false
        
        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current)
        
        return result
    }
    
    private static func parseDate(_ string: String) -> Date? {
        let formatters = [
            "M/d/yyyy",
            "MM/dd/yyyy",
            "yyyy-MM-dd",
            "dd/MM/yyyy"
        ]
        
        let cleaned = string.trimmingCharacters(in: .whitespaces)
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: cleaned) {
                return date
            }
        }
        
        return nil
    }
}

enum CSVError: LocalizedError {
    case emptyFile
    case missingRequiredColumns
    
    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "The CSV file is empty"
        case .missingRequiredColumns:
            return "Missing required columns: Word, Type, Definition"
        }
    }
}
