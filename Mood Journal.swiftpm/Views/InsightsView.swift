import SwiftUI

struct InsightsView: View {
    @EnvironmentObject private var entryStore: EntryStore
    @Environment(\.colorScheme) private var scheme

    @State private var use7DaySmoothing = true
    private let scorer = WellBeingScorer()
    @ScaledMetric(relativeTo: .largeTitle) private var scoreSize: CGFloat = 52

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        wellbeingCard
                        resetMomentCard
                        keywordsCard
                        gentlePromptCard
                    }
                    .padding()
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var latestEntry: MoodEntry? { entryStore.entries.first }

    private var wellbeingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Well‑Being score")
                    .font(.headline)
                Spacer()
                Toggle("7‑day", isOn: $use7DaySmoothing)
                    .labelsHidden()
            }

            if let entry = latestEntry {
                let today = scorer.breakdown(for: entry)
                let smoothed = Self.rollingAverageScore(entries: entryStore.entries, scorer: scorer, days: 7)
                let shown = use7DaySmoothing ? (smoothed ?? today.total) : today.total

                HStack(alignment: .firstTextBaseline) {
                    Text("\(Int(shown.rounded()))")
                        .font(.system(size: scoreSize, weight: .semibold, design: .rounded))
                    Text("/ 100")
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                Text("Why this score?")
                    .font(.subheadline.weight(.semibold))
                    .padding(.top, 6)

                VStack(spacing: 8) {
                    ForEach(today.components) { c in
                        ComponentRow(component: c)
                        Divider()
                    }
                }
                .font(.subheadline)

                Text("This is a supportive reflection tool—not a diagnosis.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            } else {
                Text("Add a check‑in to generate your first score.")
                    .foregroundStyle(.secondary)
            }
        }
        .appCard()
    }

    private var resetMomentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Reset moment")
                .font(.headline)
            Text("A 60‑second breathing guide to help you settle, especially on high‑stress days.")
                .foregroundStyle(.secondary)
            NavigationLink {
                BreathingView()
            } label: {
                Text("Start")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .appCard()
    }

    private var keywordsCard: some View {
        let keywords = Self.recentKeywords(entries: entryStore.entries)
        return VStack(alignment: .leading, spacing: 10) {
            Text("Recurring themes (from your journal)")
                .font(.headline)
            if keywords.isEmpty {
                Text("Write a short note in a few entries to see keywords here.")
                    .foregroundStyle(.secondary)
            } else {
                let cols = [GridItem(.adaptive(minimum: 90), spacing: 10)]
                LazyVGrid(columns: cols, alignment: .leading, spacing: 10) {
                    ForEach(keywords, id: \.self) { word in
                        Text(word)
                            .font(.callout.weight(.semibold))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .background(AppTheme.tint.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .appCard()
    }

    private var gentlePromptCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Gentle prompt")
                .font(.headline)
            Text(Self.prompt(from: entryStore.entries))
                .foregroundStyle(.secondary)
        }
        .appCard()
    }
}

private struct ComponentRow: View {
    let component: WellBeingScorer.Component

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(component.title)
                Text(componentDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(pointsText)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private var componentDetail: String {
        if component.weight == 0 {
            return "Not available"
        }
        let w = Int((component.weight * 100).rounded())
        let n = Int(((component.normalized ?? 0) * 100).rounded())
        return "\(w)% weight · \(n)% today"
    }

    private var pointsText: String {
        let sign = component.points >= 0 ? "+" : "−"
        let absPoints = abs(component.points)
        return "\(sign)\(String(format: "%.1f", absPoints))"
    }
}

private extension InsightsView {
    static func rollingAverageScore(entries: [MoodEntry], scorer: WellBeingScorer, days: Int) -> Double? {
        guard !entries.isEmpty else { return nil }
        let cal = Calendar.current
        let end = Date()
        let start = cal.date(byAdding: .day, value: -(days - 1), to: end) ?? end
        let recent = entries.filter { $0.timestamp >= start && $0.timestamp <= end }
        guard !recent.isEmpty else { return nil }
        let totals = recent.map { scorer.breakdown(for: $0).total }
        return totals.reduce(0, +) / Double(totals.count)
    }

    static func recentKeywords(entries: [MoodEntry]) -> [String] {
        let recent = entries.prefix(20)
        var counts: [String: Int] = [:]
        for e in recent {
            for k in e.derived.keywords {
                counts[k, default: 0] += 1
            }
        }
        return counts
            .sorted { a, b in
                if a.value != b.value { return a.value > b.value }
                return a.key < b.key
            }
            .prefix(10)
            .map(\.key)
    }

    static func prompt(from entries: [MoodEntry]) -> String {
        guard let latest = entries.first else {
            return "What’s one small thing you’d like to notice today?"
        }

        if latest.stress >= 7 {
            return "Stress looks high. What’s one thing you can make easier in the next hour?"
        }
        if latest.energy <= 3 {
            return "Energy looks low. If you could pick one gentle reset: water, sunlight, or a short walk—what would you choose?"
        }
        if latest.mood >= 8 {
            return "Mood is bright. What helped today—and how can you repeat that tomorrow?"
        }
        return "If you name the main feeling right now in one word, what is it?"
    }
}


