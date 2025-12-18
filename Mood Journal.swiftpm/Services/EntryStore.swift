import Foundation
import SwiftUI
#if canImport(NaturalLanguage)
import NaturalLanguage
#endif

@MainActor
final class EntryStore: ObservableObject {
    @Published private(set) var entries: [MoodEntry] = []

    private let persistence = LocalPersistence()
    private let nlp = EntryNoteAnalyzer()

    init() {
        load()
    }

    func load() {
        do {
            if let loaded = try persistence.loadEntries() {
                entries = loaded.sorted(by: { $0.timestamp > $1.timestamp })
            } else {
                // First launch (no saved file yet): start empty.
                entries = []
            }
        } catch {
            // If anything goes wrong (e.g., decode mismatch), fall back to safe empty state.
            entries = []
        }
    }

    func add(_ entry: MoodEntry) {
        var e = entry
        e.derived = nlp.derive(from: entry.note)
        entries.insert(e, at: 0)
        persistBestEffort()
    }

    func update(_ entry: MoodEntry) {
        guard let idx = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        var e = entry
        e.derived = nlp.derive(from: entry.note)
        entries[idx] = e
        entries.sort(by: { $0.timestamp > $1.timestamp })
        persistBestEffort()
    }

    func delete(_ entry: MoodEntry) {
        entries.removeAll(where: { $0.id == entry.id })
        persistBestEffort()
    }

    func deleteAllEntries() {
        entries = []
        do { try persistence.deleteEntriesFile() } catch { /* best-effort */ }
    }

    private func persistBestEffort() {
        do { try persistence.saveEntries(entries) } catch { /* best-effort */ }
    }

    // Intentionally no hard-coded sample entries.
}

/// Kept inside this file so it is always compiled as part of the main target
/// (some Swift Playgrounds/Xcode setups can miss new standalone files until refresh).
private struct EntryNoteAnalyzer {
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


