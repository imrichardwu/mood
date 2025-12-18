import SwiftUI

struct InsightsView: View {
    @EnvironmentObject private var entryStore: EntryStore
    @Environment(\.colorScheme) private var scheme

    private let scorer = WellBeingScorer()
    @ScaledMetric(relativeTo: .largeTitle) private var scoreSize: CGFloat = 52
    @State private var selectedKeyword: SelectedKeyword?

    private struct SelectedKeyword: Identifiable {
        let word: String
        var id: String { word }
    }

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
                        
                    }
                    .padding()
                }
            }
            .navigationTitle("Insights")
        }
        .sheet(item: $selectedKeyword) { sel in
            KeywordEntriesSheet(
                keyword: sel.word,
                entries: entries(matching: sel.word)
            )
        }
    }

    private var todayEntries: [MoodEntry] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return entryStore.entries
            .filter { cal.startOfDay(for: $0.timestamp) == today }
            .sorted(by: { $0.timestamp > $1.timestamp })
    }

    private var wellbeingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Daily well‑being")
                    .font(.headline)
                Spacer()
            }

            if let daily = dailyWellbeingBreakdown(entries: todayEntries) {
                let shown = daily.total

                HStack(alignment: .firstTextBaseline) {
                    Text("\(Int(shown.rounded()))")
                        .font(.system(size: scoreSize, weight: .semibold, design: .rounded))
                    Text("/ 100")
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                Text("Average of \(daily.entryCount) entr\(daily.entryCount == 1 ? "y" : "ies") today")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text("Why this score?")
                    .font(.subheadline.weight(.semibold))
                    .padding(.top, 6)

                VStack(spacing: 8) {
                    ForEach(daily.components) { c in
                        ComponentRow(component: c)
                        Divider()
                    }
                }
                .font(.subheadline)

              
            } else {
                Text("Write an entry today to generate your daily score.")
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
        let keywords = Self.recentKeywordStats(entries: entryStore.entries)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recurring themes")
                    .font(.headline)
                Spacer()
                Text("Last 20 entries")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if keywords.isEmpty {
                Text("Write a short note in a few entries to see keywords here.")
                    .foregroundStyle(.secondary)
            } else {
                Text("Tap a theme to see the entries behind it.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                let cols = [GridItem(.adaptive(minimum: 120), spacing: 10)]
                LazyVGrid(columns: cols, alignment: .leading, spacing: 10) {
                    ForEach(keywords, id: \.word) { item in
                        Button {
                            selectedKeyword = SelectedKeyword(word: item.word)
                        } label: {
                            KeywordChip(word: item.word, count: item.count)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .appCard()
    }

    
    private func entries(matching keyword: String) -> [MoodEntry] {
        let k = keyword.lowercased()
        return entryStore.entries
            .filter { entry in
                entry.derived.keywords.contains { $0.lowercased() == k }
            }
            .sorted(by: { $0.timestamp > $1.timestamp })
    }

    private struct DailyWellbeing: Hashable {
        let entryCount: Int
        let total: Double
        let components: [WellBeingScorer.Component]
    }

    private func dailyWellbeingBreakdown(entries: [MoodEntry]) -> DailyWellbeing? {
        guard !entries.isEmpty else { return nil }

        struct Agg {
            var title: String
            var pointsSum: Double = 0
            var weightSum: Double = 0
            var normalizedSum: Double = 0
            var normalizedCount: Int = 0
        }

        let n = Double(entries.count)
        var agg: [WellBeingScorer.Component.Kind: Agg] = [:]

        for e in entries {
            let b = scorer.breakdown(for: e)
            for c in b.components {
                var a = agg[c.kind] ?? Agg(title: c.title)
                a.pointsSum += c.points
                a.weightSum += c.weight
                if let norm = c.normalized {
                    a.normalizedSum += norm
                    a.normalizedCount += 1
                }
                agg[c.kind] = a
            }
        }

        // Preserve a stable, meaningful order.
        let order: [WellBeingScorer.Component.Kind] = [
            .mood,
            .stressInverse,
            .energy,
            .sentiment
        ]

        let components: [WellBeingScorer.Component] = order.compactMap { kind in
            guard let a = agg[kind] else { return nil }
            let avgPoints = a.pointsSum / n
            let avgWeight = a.weightSum / n
            let avgNormalized = a.normalizedCount > 0 ? (a.normalizedSum / Double(a.normalizedCount)) : nil
            return WellBeingScorer.Component(
                kind: kind,
                title: a.title,
                weight: avgWeight,
                normalized: avgNormalized,
                points: avgPoints
            )
        }

        let total = components.reduce(0.0) { $0 + $1.points }.clamped(to: 0...100)
        return DailyWellbeing(entryCount: entries.count, total: total, components: components)
    }
}

private struct KeywordChip: View {
    let word: String
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "leaf.fill")
                .font(.caption)
                .foregroundStyle(AppTheme.tint)

            Text(word)
                .font(.callout.weight(.semibold))
                .lineLimit(1)

            Spacer(minLength: 0)

            Text("\(count)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(AppTheme.tint)
                .clipShape(Capsule())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(AppTheme.tint.opacity(0.10))
        .overlay(
            Capsule()
                .stroke(AppTheme.tint.opacity(0.18), lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

private struct KeywordEntriesSheet: View {
    @Environment(\.dismiss) private var dismiss
    let keyword: String
    let entries: [MoodEntry]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                    .ignoresSafeArea()

                if entries.isEmpty {
                    VStack(spacing: 10) {
                        Text("No entries found")
                            .font(.headline)
                        Text("Try writing a few more entries so themes have more signal.")
                            .foregroundStyle(.secondary)
                    }
                    .appCard()
                    .padding()
                } else {
                    List {
                        Section {
                            ForEach(entries) { entry in
                                NavigationLink {
                                    EntryDetailView(entry: entry)
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(entry.timestamp, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())
                                                .font(.subheadline.weight(.semibold))
                                            Spacer()
                                            Text("Mood \(Int(entry.mood.rounded()))")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                        if !entry.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                            Text(entry.note)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(2)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        } header: {
                            Text("Entries mentioning “\(keyword)”")
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle(keyword)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
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
    struct KeywordStat: Hashable {
        let word: String
        let count: Int
    }

    static func recentKeywordStats(entries: [MoodEntry]) -> [KeywordStat] {
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
            .map { KeywordStat(word: $0.key, count: $0.value) }
    }

}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

