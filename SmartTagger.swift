import Foundation
import NaturalLanguage

class SmartTagger {
    
    static let shared = SmartTagger()
    
    // Words to ignore even if capitalized
    private let stopWords: Set<String> = ["The", "A", "An", "In", "On", "At", "To", "For", "Is", "Are", "Was", "Were", "Meeting", "Discuss", "Note", "We", "I", "Me"]
    
    func generateTags(from text: String) -> [String] {
        var foundTags: [String: Int] = [:]
        
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = text
        
        // Force English to help the Simulator
        tagger.setLanguage(.english, range: text.startIndex..<text.endIndex)
        
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        
        // 1. Scan for Entities
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
            let word = String(text[tokenRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let tag = tag {
                // LOGIC UPDATE: Accept specific tags OR capitalized 'Other' tags
                let isSpecificEntity = (tag == .personalName || tag == .placeName || tag == .organizationName)
                let isCapitalizedOther = (tag == .other && word.first?.isUppercase == true && !stopWords.contains(word))
                
                if isSpecificEntity || isCapitalizedOther {
                    foundTags[word, default: 0] += 10
                }
            }
            return true
        }
        
        // 2. Scan for Nouns (Secondary pass)
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
            let word = String(text[tokenRange])
            
            // Only keep nouns that are NOT in the stop list and longer than 3 letters
            if let tag = tag, tag == .noun, word.count > 3 {
                 let cleanWord = word.capitalized
                 if !stopWords.contains(cleanWord) {
                     foundTags[cleanWord, default: 0] += 1
                 }
            }
            return true
        }
        
        // 3. Sort by frequency and return Top 5
        return foundTags.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
    }
}
