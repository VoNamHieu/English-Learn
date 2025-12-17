import Foundation
import SwiftData

@Model
class Definition {
    var text: String
    var typeRaw: String
    var levelRaw: String
    var vietnamese: String?
    var synonyms: [String] = []
    
    var word: Word?
    
    var type: WordType {
        get { WordType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }
    
    var level: CEFRLevel {
        get { CEFRLevel(rawValue: levelRaw) ?? .B2 }
        set { levelRaw = newValue.rawValue }
    }
    
    init(text: String, type: WordType, level: CEFRLevel, vietnamese: String? = nil) {
        self.text = text
        self.typeRaw = type.rawValue
        self.levelRaw = level.rawValue
        self.vietnamese = vietnamese
    }
}

enum WordType: String, Codable, CaseIterable {
    case noun = "noun"
    case verb = "verb"
    case adjective = "adjective"
    case adverb = "adverb"
    case other = "other"
    
    // Add this static func
    static func from(_ string: String) -> WordType {
        switch string.lowercased().trimmingCharacters(in: .whitespaces) {
        case "noun": return .noun
        case "verb": return .verb
        case "adjective", "adj": return .adjective
        case "adverb", "adv": return .adverb
        default: return .other
        }
    }
}

enum CEFRLevel: String, Codable, CaseIterable, Comparable {
    case A1 = "A1"
    case A2 = "A2"
    case B1 = "B1"
    case B2 = "B2"
    case C1 = "C1"
    case C2 = "C2"
    
    static func < (lhs: CEFRLevel, rhs: CEFRLevel) -> Bool {
        let order: [CEFRLevel] = [.A1, .A2, .B1, .B2, .C1, .C2]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
    
    // Add this static func
    static func from(_ string: String) -> CEFRLevel {
        CEFRLevel(rawValue: string.uppercased().trimmingCharacters(in: .whitespaces)) ?? .B2
    }
}
