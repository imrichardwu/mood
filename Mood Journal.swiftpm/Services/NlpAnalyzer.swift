import Foundation
#if canImport(NaturalLanguage)
import NaturalLanguage
#endif

struct NlpAnalyzer {
    func derive(from note: String) -> MoodEntry.Derived {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .init(sentimentScore: nil, keywords: [])
        }

        let sentiment = sentimentScore(for: trimmed)
        let keywords = extractKeywords(from: trimmed)
        return .init(sentimentScore: sentiment, keywords: keywords)
    }

    private func sentimentScore(for text: String) -> Double? {
#if canImport(NaturalLanguage)
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        let (tag, _) = tagger.tag(
            at: text.startIndex,
            unit: .paragraph,
            scheme: .sentimentScore
        )
        guard let raw = tag?.rawValue, let value = Double(raw) else { return nil }
        return min(1, max(-1, value))
#else
        // Fallback heuristic: count a few positive/negative words (non-clinical).
        // Returns a best-effort score in [-1, 1].
        let lower = text.lowercased()
        let positive = ["good", "great", "better", "calm", "happy", "relieved", "grateful", "excited", "proud"]
        let negative = ["bad", "worse", "sad", "angry", "anxious", "stress", "stressed", "tired", "overwhelmed"]

        let posCount = positive.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let negCount = negative.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let total = max(posCount + negCount, 1)
        let score = Double(posCount - negCount) / Double(total)
        return min(1, max(-1, score))
#endif
    }

    private func extractKeywords(from text: String) -> [String] {
#if canImport(NaturalLanguage)
        let tagger = NLTagger(tagSchemes: [.lemma, .lexicalClass])
        tagger.string = text

        let stopwords: Set<String> = [
            "a","an","the","and","or","but","to","of","in","on","for","with","at","from",
            "i","me","my","we","our","you","your","they","their","he","she","it","this","that",
            "is","are","was","were","be","been","being","do","did","does","have","has","had",
            "as","so","if","then","than","too","very","just","not","no","yes"
        ]

        var counts: [String: Int] = [:]

        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .lexicalClass,
            options: [.omitWhitespace, .omitPunctuation, .omitOther]
        ) { tag, range in
            guard let tag else { return true }
            // Focus on thematic words (nouns/adjectives).
            guard tag == .noun || tag == .adjective else { return true }

            let token = String(text[range]).lowercased()
            guard token.count >= 3 else { return true }
            guard token.allSatisfy({ $0.isLetter }) else { return true }

            let lemma = tagger.tag(at: range.lowerBound, unit: .word, scheme: .lemma).0?.rawValue.lowercased()
            let normalized = (lemma?.isEmpty == false ? lemma! : token)
            guard !stopwords.contains(normalized) else { return true }

            counts[normalized, default: 0] += 1
            return true
        }

        return counts
            .sorted { (a, b) in
                if a.value != b.value { return a.value > b.value }
                return a.key < b.key
            }
            .prefix(6)
            .map(\.key)
#else
        // Fallback: take the most common words (letters only), excluding stopwords.
        let stopwords: Set<String> = [
            "a","an","the","and","or","but","to","of","in","on","for","with","at","from",
            "i","me","my","we","our","you","your","they","their","he","she","it","this","that",
            "is","are","was","were","be","been","being","do","did","does","have","has","had",
            "as","so","if","then","than","too","very","just","not","no","yes"
        ]

        let words = text
            .lowercased()
            .split(whereSeparator: { !$0.isLetter })
            .map(String.init)
            .filter { $0.count >= 3 && !stopwords.contains($0) }

        var counts: [String: Int] = [:]
        for w in words { counts[w, default: 0] += 1 }

        return counts
            .sorted { a, b in
                if a.value != b.value { return a.value > b.value }
                return a.key < b.key
            }
            .prefix(6)
            .map(\.key)
#endif
    }
}


