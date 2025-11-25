import Foundation
import NaturalLanguage

class SentimentAnalyzer {
    
    static let shared = SentimentAnalyzer()
    
    func getSentimentEmoji(for text: String?) -> String {
        guard let text = text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "📝"
        }
        
        // 1. Try Apple's NLTagger first
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        // Force English to help Simulator
        tagger.setLanguage(.english, range: text.startIndex..<text.endIndex)
        
        let (sentiment, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        var score = Double(sentiment?.rawValue ?? "0") ?? 0.0
        
        print("DEBUG: CoreML Score: \(score)")
        
        // 2. SIMULATOR FIX: If CoreML fails (0.0) on emotional text, use manual keywords
        if score == 0.0 {
            score = calculateManualScore(for: text)
            if score != 0.0 {
                print("DEBUG: Using Manual Fallback Score: \(score)")
            }
        }
        
        print("DEBUG: Final Sentiment Score: \(String(format: "%.2f", score)) | Text: \(text.prefix(20))...")
        
        // 3. Return Emoji
        if score > 0.4 {
            return "🔥" // Positive
        } else if score > 0.1 {
            return "🙂" // Mildly Positive
        } else if score < -0.4 {
            return "🌧️" // Negative
        } else if score < -0.1 {
            return "⚠️" // Mildly Negative
        } else {
            return "🧠" // Neutral
        }
    }
    
    // A primitive fallback for the Simulator
    private func calculateManualScore(for text: String) -> Double {
        let lowerText = text.lowercased()
        
        // Positive keywords
        let positives = ["happy", "good", "great", "excellent", "love", "amazing", "success", "winner", "best", "works"]
        // Negative keywords
        let negatives = ["sad", "bad", "terrible", "hate", "error", "fail", "failure", "broken", "worst", "angry"]
        
        for word in positives {
            if lowerText.contains(word) { return 0.8 }
        }
        
        for word in negatives {
            if lowerText.contains(word) { return -0.8 }
        }
        
        return 0.0
    }
}
