import Foundation

struct MoodEntry: Identifiable, Codable, Hashable {
    struct Derived: Codable, Hashable {
        /// Rough sentiment score from on-device NLP, in range [-1, 1], where 1 is positive.
        var sentimentScore: Double?
        /// A few keywords/topics extracted on-device to aid insight cards and tag suggestions.
        var keywords: [String]
    }

    var id: UUID
    /// Device-local timestamp at creation/edit time.
    var timestamp: Date

    /// Primary check-in inputs.
    var mood: Double       // 0...10
    var energy: Double     // 0...10
    var stress: Double     // 0...10 (higher = more stress)

    var tags: [Tag]
    var note: String

    /// Enriched data computed on-device.
    var derived: Derived

    init(
        id: UUID = UUID(),
        timestamp: Date = .now,
        mood: Double,
        energy: Double,
        stress: Double,
        tags: [Tag] = [],
        note: String = "",
        derived: Derived = .init(sentimentScore: nil, keywords: [])
    ) {
        self.id = id
        self.timestamp = timestamp
        self.mood = mood
        self.energy = energy
        self.stress = stress
        self.tags = tags
        self.note = note
        self.derived = derived
    }
}


