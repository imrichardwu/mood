import Foundation

struct WellBeingScorer {
    struct Weights: Hashable {
        var mood: Double = 0.40
        var stressInverse: Double = 0.20
        var energy: Double = 0.20
        var sentiment: Double = 0.20
    }

    struct Component: Hashable, Identifiable {
        enum Kind: String, Hashable {
            case mood
            case stressInverse
            case energy
            case sentiment
        }

        let kind: Kind
        let title: String
        let weight: Double          // after availability renormalization
        let normalized: Double?     // 0...1 if available
        let points: Double          // contribution in 0...100 space

        var id: String { kind.rawValue }
    }

    struct Breakdown: Hashable {
        let total: Double           // 0...100
        let components: [Component]
    }

    var weights: Weights = .init()

    func breakdown(for entry: MoodEntry) -> Breakdown {
        let mood = (entry.mood / 10.0).clamped01()
        let energy = (entry.energy / 10.0).clamped01()
        let stressInv = (1.0 - (entry.stress / 10.0)).clamped01()

        let sentimentNorm: Double? = entry.derived.sentimentScore.map { (($0 + 1.0) / 2.0).clamped01() }

        let raw: [(Component.Kind, String, Double, Double?)] = [
            (.mood, "Mood", weights.mood, mood),
            (.stressInverse, "Low stress", weights.stressInverse, stressInv),
            (.energy, "Energy", weights.energy, energy),
            (.sentiment, "Journal tone", weights.sentiment, sentimentNorm)
        ]

        let availableWeightSum = raw.reduce(0.0) { acc, item in
            acc + (item.3 == nil ? 0.0 : item.2)
        }

        // Always have at least mood/stress/energy. But guard anyway.
        let denom = max(availableWeightSum, 0.0001)

        let components: [Component] = raw.map { kind, title, baseWeight, normalized in
            let w = normalized == nil ? 0.0 : (baseWeight / denom)
            let points = (normalized ?? 0.0) * w * 100.0
            return Component(kind: kind, title: title, weight: w, normalized: normalized, points: points)
        }

        let total = components.reduce(0.0) { $0 + $1.points }.clamped(to: 0...100)
        return Breakdown(total: total, components: components)
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }

    func clamped01() -> Double { clamped(to: 0...1) }
}


