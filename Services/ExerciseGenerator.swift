import Foundation
import SwiftData

class ExerciseGenerator {
    static let shared = ExerciseGenerator()
    
    private let openAI = OpenAIService.shared
    
    private let systemPrompt = """
    You are a vocabulary exercise generator for a language learning app.
    
    ## Your Tasks:
    1. Analyze the provided vocabulary list
    2. Group words intelligently by:
       - Word type (verbs, nouns, adjectives, adverbs)
       - Semantic themes (business, science, emotions, academic...)
       - CEFR level
    3. Generate exercises for each group
    
    ## Exercise Types:
    1. fill_blank: Sentence with ___ for target word
    2. multiple_choice: Word with 4 definition options
    3. word_group_paragraph: Paragraph using multiple words from group
    4. confusion_pair: Compare similar words
    
    ## Output: Return ONLY valid JSON, no markdown.
    """
    
    struct GenerationResponse: Codable {
        let word_groups: [WordGroup]
    }
    
    struct WordGroup: Codable {
        let group_id: String
        let group_name: String
        let words: [String]
        let exercises: [ExerciseData]
    }
    
    struct ExerciseData: Codable {
        let id: String
        let type: String
        let instruction: String
        let sentence: String
        let answer: String
        let hint: String?
        let options: [String]?
        let difficulty: String?
    }
    
    func generateExercises(for words: [Word], modelContext: ModelContext) async throws -> [ExerciseGroup] {
        // Build payload
        let wordPayload = words.map { word -> [String: Any] in
            [
                "word": word.text,
                "type": word.definitions.first?.typeRaw ?? "other",
                "definitions": word.definitions.map { $0.text },
                "level": word.definitions.first?.levelRaw ?? "B2"
            ]
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: ["vocabulary": wordPayload])
        let userMessage = String(data: jsonData, encoding: .utf8) ?? ""
        
        // Call OpenAI
        let response = try await openAI.chat(
            systemPrompt: systemPrompt,
            userMessage: userMessage,
            jsonMode: true
        )
        
        // Parse response
        guard let data = response.data(using: .utf8) else {
            throw GeneratorError.invalidResponse
        }
        
        let generationResponse = try JSONDecoder().decode(GenerationResponse.self, from: data)
        
        // Convert to SwiftData models
        var exerciseGroups: [ExerciseGroup] = []
        
        for group in generationResponse.word_groups {
            let exerciseGroup = ExerciseGroup(
                id: group.group_id,
                name: group.group_name,
                wordIds: group.words
            )
            
            for exerciseData in group.exercises {
                let exercise = Exercise(
                    id: exerciseData.id,
                    type: ExerciseType(rawValue: exerciseData.type) ?? .fillBlank,
                    instruction: exerciseData.instruction,
                    sentence: exerciseData.sentence,
                    answer: exerciseData.answer,
                    hint: exerciseData.hint,
                    options: exerciseData.options,
                    difficulty: exerciseData.difficulty ?? "B2"
                )
                exerciseGroup.exercises.append(exercise)
            }
            
            modelContext.insert(exerciseGroup)
            exerciseGroups.append(exerciseGroup)
        }
        
        try modelContext.save()
        
        return exerciseGroups
    }
    
    enum GeneratorError: LocalizedError {
        case invalidResponse
        
        var errorDescription: String? {
            "Failed to generate exercises"
        }
    }
}
