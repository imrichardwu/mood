import Foundation

struct Goal: Identifiable, Codable, Hashable {
    enum Kind: String, Codable, CaseIterable, Identifiable {
        case entriesToday
        case entriesThisWeek
        case daysThisWeek
        case wordsToday
        case wordsThisWeek

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .entriesToday: return "Write entries today"
            case .entriesThisWeek: return "Write entries this week"
            case .daysThisWeek: return "Journal days this week"
            case .wordsToday: return "Write words today"
            case .wordsThisWeek: return "Write words this week"
            }
        }

        var unitLabel: String {
            switch self {
            case .entriesToday, .entriesThisWeek: return "entries"
            case .daysThisWeek: return "days"
            case .wordsToday, .wordsThisWeek: return "words"
            }
        }

        var defaultTarget: Double {
            switch self {
            case .entriesToday: return 1
            case .entriesThisWeek: return 5
            case .daysThisWeek: return 4
            case .wordsToday: return 150
            case .wordsThisWeek: return 800
            }
        }

        var targetStep: Double {
            switch self {
            case .wordsToday, .wordsThisWeek: return 25
            default: return 1
            }
        }

        var targetBounds: ClosedRange<Double> {
            switch self {
            case .entriesToday: return 1...10
            case .entriesThisWeek: return 1...50
            case .daysThisWeek: return 1...7
            case .wordsToday: return 25...2000
            case .wordsThisWeek: return 100...10_000
            }
        }
    }

    struct Progress: Hashable {
        var value: Double
        var target: Double
        var label: String

        var fraction: Double {
            guard target > 0 else { return 0 }
            return min(max(value / target, 0), 1)
        }

        var isComplete: Bool { value >= target && target > 0 }
    }

    var id: UUID
    var title: String
    var kind: Kind
    var target: Double
    var isActive: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String? = nil,
        kind: Kind,
        target: Double,
        isActive: Bool = true,
        createdAt: Date = .now
    ) {
        self.id = id
        self.kind = kind
        self.target = target
        self.isActive = isActive
        self.createdAt = createdAt
        self.title = (title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            ? title!
            : kind.displayName
    }

    func progress(entries: [MoodEntry]) -> Progress {
        let cal = Calendar.current

        switch kind {
        case .entriesToday:
            let today = cal.startOfDay(for: Date())
            let value = Double(entries.filter { cal.startOfDay(for: $0.timestamp) == today }.count)
            let label = "\(Int(value))/\(Int(target)) \(kind.unitLabel)"
            return Progress(value: value, target: target, label: label)

        case .entriesThisWeek:
            let now = Date()
            let interval = cal.dateInterval(of: .weekOfYear, for: now)
            let start = interval?.start ?? cal.startOfDay(for: now)
            let end = interval?.end ?? now
            let value = Double(entries.filter { $0.timestamp >= start && $0.timestamp < end }.count)
            let label = "\(Int(value))/\(Int(target)) \(kind.unitLabel)"
            return Progress(value: value, target: target, label: label)

        case .daysThisWeek:
            let now = Date()
            let interval = cal.dateInterval(of: .weekOfYear, for: now)
            let start = interval?.start ?? cal.startOfDay(for: now)
            let end = interval?.end ?? now
            let days = Set(entries
                .filter { $0.timestamp >= start && $0.timestamp < end }
                .map { cal.startOfDay(for: $0.timestamp) }
            )
            let value = Double(days.count)
            let label = "\(Int(value))/\(Int(target)) \(kind.unitLabel)"
            return Progress(value: value, target: target, label: label)

        case .wordsToday:
            let today = cal.startOfDay(for: Date())
            let text = entries
                .filter { cal.startOfDay(for: $0.timestamp) == today }
                .map(\.note)
                .joined(separator: " ")
            let v = Double(Self.wordCount(text))
            let label = "\(Int(v))/\(Int(target)) \(kind.unitLabel)"
            return Progress(value: v, target: target, label: label)

        case .wordsThisWeek:
            let now = Date()
            let interval = cal.dateInterval(of: .weekOfYear, for: now)
            let start = interval?.start ?? cal.startOfDay(for: now)
            let end = interval?.end ?? now
            let text = entries
                .filter { $0.timestamp >= start && $0.timestamp < end }
                .map(\.note)
                .joined(separator: " ")
            let v = Double(Self.wordCount(text))
            let label = "\(Int(v))/\(Int(target)) \(kind.unitLabel)"
            return Progress(value: v, target: target, label: label)
        }
    }

    private static func wordCount(_ text: String) -> Int {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .count
    }
}

