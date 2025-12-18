import Foundation
import Darwin

struct WellBeingScorer {
    struct Weights: Hashable {
        var mood: Double = 0.35
        var stressInverse: Double = 0.15
        var energy: Double = 0.15
        var sentiment: Double = 0.15
        var sleep: Double = 0.10
        var steps: Double = 0.10
    }

    struct Component: Hashable, Identifiable {
        enum Kind: String, Hashable {
            case mood
            case stressInverse
            case energy
            case sentiment
            case sleep
            case steps
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
        let sleepNorm: Double? = entry.health.sleepHours.map { normalizeSleepHours($0) }
        let stepsNorm: Double? = entry.health.steps.map { normalizeSteps($0) }

        let raw: [(Component.Kind, String, Double, Double?)] = [
            (.mood, "Mood", weights.mood, mood),
            (.stressInverse, "Low stress", weights.stressInverse, stressInv),
            (.energy, "Energy", weights.energy, energy),
            (.sentiment, "Journal tone", weights.sentiment, sentimentNorm),
            (.sleep, "Sleep", weights.sleep, sleepNorm),
            (.steps, "Steps", weights.steps, stepsNorm)
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

    private func normalizeSleepHours(_ hours: Double) -> Double {
        // Soft target: 8 hours. Give full credit between ~7–9h, taper outside.
        let h = hours.clamped(to: 0...14)
        switch h {
        case 7.0...9.0: return 1.0
        case 5.0..<7.0: return (h - 5.0) / 2.0 // 0..1
        case 9.0..<11.0: return 1.0 - ((h - 9.0) / 2.0) * 0.25 // gently taper (1..0.75)
        default:
            // below 5h or above 11h: low score, but never 0.
            return 0.25
        }
    }

    private func normalizeSteps(_ steps: Double) -> Double {
        // Diminishing returns. 0 -> 0.1 baseline, 10k -> ~1.0 cap.
        let s = steps.clamped(to: 0...30_000)
        let t = (s / 10_000.0).clamped(to: 0...1)
        // Ease-out curve.
        let eased = 1 - pow(1 - t, 2)
        return max(0.10, eased)
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }

    func clamped01() -> Double { clamped(to: 0...1) }
}


