import SwiftUI
#if canImport(Charts)
import Charts
#endif

struct TrendsView: View {
    @EnvironmentObject private var entryStore: EntryStore
    @Environment(\.colorScheme) private var scheme

    enum RangeOption: String, CaseIterable, Identifiable {
        case week = "7D"
        case month = "30D"
        case quarter = "90D"

        var id: String { rawValue }
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            }
        }
        var title: String {
            switch self {
            case .week: return "Last 7 days"
            case .month: return "Last 30 days"
            case .quarter: return "Last 90 days"
            }
        }
    }

    @State private var range: RangeOption = .month

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: scheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        rangePicker
                        moodOverTimeCard
                        timeOfDayCard
                        weekdayCard
                        tagCorrelationCard
                    }
                    .padding()
                }
            }
            .navigationTitle("Trends")
        }
    }

    private var rangePicker: some View {
        HStack(spacing: 10) {
            Text("Range")
                .font(.headline)
            Spacer()
            Picker("Range", selection: $range) {
                ForEach(RangeOption.allCases) { opt in
                    Text(opt.rawValue).tag(opt)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 220)
        }
        .appCard()
    }

    private var filteredEntries: [MoodEntry] {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -(range.days - 1), to: end) ?? end
        return entryStore.entries
            .filter { $0.timestamp >= start && $0.timestamp <= end }
            .sorted(by: { $0.timestamp < $1.timestamp })
    }

    private var moodOverTimeCard: some View {
        let points = Self.dailyAverages(from: filteredEntries)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Mood over time")
                    .font(.headline)
                Spacer()
                Text(range.title)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if points.count < 2 {
                Text("Add a few entries to see your line chart here.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            } else {
#if canImport(Charts)
                if #available(iOS 16.0, *) {
                    Chart(points) { p in
                        LineMark(
                            x: .value("Day", p.day, unit: .day),
                            y: .value("Mood", p.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(AppTheme.tint)

                        PointMark(
                            x: .value("Day", p.day, unit: .day),
                            y: .value("Mood", p.value)
                        )
                        .foregroundStyle(AppTheme.tint.opacity(0.8))
                    }
                    .chartYScale(domain: 0...10)
                    .frame(height: 180)
                } else {
                    fallbackList(points: points)
                }
#else
                fallbackList(points: points)
#endif
            }
        }
        .appCard()
    }

    private var timeOfDayCard: some View {
        let stats = Self.timeOfDayAverages(from: filteredEntries)
        return VStack(alignment: .leading, spacing: 10) {
            Text("Time of day")
                .font(.headline)

            if stats.isEmpty {
                Text("No entries in this range yet.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            } else {
#if canImport(Charts)
                if #available(iOS 16.0, *) {
                    Chart(stats) { s in
                        BarMark(
                            x: .value("Bucket", s.bucket.displayName),
                            y: .value("Avg mood", s.avgMood)
                        )
                        .foregroundStyle(by: .value("Bucket", s.bucket.displayName))
                    }
                    .chartYScale(domain: 0...10)
                    .frame(height: 160)
                } else {
                    fallbackBuckets(stats: stats)
                }
#else
                fallbackBuckets(stats: stats)
#endif
            }
        }
        .appCard()
    }

    private var weekdayCard: some View {
        let stats = Self.weekdayAverages(from: filteredEntries)
        return VStack(alignment: .leading, spacing: 10) {
            Text("Day of week")
                .font(.headline)

            if stats.isEmpty {
                Text("No entries in this range yet.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            } else {
#if canImport(Charts)
                if #available(iOS 16.0, *) {
                    Chart(stats) { s in
                        BarMark(
                            x: .value("Day", s.label),
                            y: .value("Avg mood", s.avgMood)
                        )
                        .foregroundStyle(AppTheme.tint.opacity(0.75))
                    }
                    .chartYScale(domain: 0...10)
                    .frame(height: 160)
                } else {
                    fallbackWeekdays(stats: stats)
                }
#else
                fallbackWeekdays(stats: stats)
#endif
            }
        }
        .appCard()
    }

    private var tagCorrelationCard: some View {
        let stats = Self.tagMoodAverages(from: filteredEntries)
        return VStack(alignment: .leading, spacing: 10) {
            Text("Tags and mood (best-effort)")
                .font(.headline)

            if stats.isEmpty {
                Text("Add tags to entries to see correlations.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            } else {
                VStack(spacing: 10) {
                    ForEach(stats.prefix(6), id: \.tag) { row in
                        HStack {
                            Text(row.tag.displayName)
                            Spacer()
                            Text(String(format: "%.1f", row.avgMood))
                                .foregroundStyle(.secondary)
                        }
                        Divider()
                    }
                }
                .font(.subheadline)
            }
        }
        .appCard()
    }

    private func fallbackList(points: [DayPoint]) -> some View {
        VStack(spacing: 8) {
            ForEach(points.suffix(7), id: \.day) { p in
                HStack {
                    Text(p.day, format: .dateTime.month(.abbreviated).day())
                    Spacer()
                    Text(String(format: "%.1f", p.value))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Divider()
            }
        }
        .font(.subheadline)
    }

    private func fallbackBuckets(stats: [BucketStat]) -> some View {
        VStack(spacing: 8) {
            ForEach(stats, id: \.bucket) { s in
                HStack {
                    Text(s.bucket.displayName)
                    Spacer()
                    Text(String(format: "%.1f", s.avgMood))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Divider()
            }
        }
        .font(.subheadline)
    }

    private func fallbackWeekdays(stats: [WeekdayStat]) -> some View {
        VStack(spacing: 8) {
            ForEach(stats, id: \.weekday) { s in
                HStack {
                    Text(s.label)
                    Spacer()
                    Text(String(format: "%.1f", s.avgMood))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Divider()
            }
        }
        .font(.subheadline)
    }
}

// MARK: - Trend computations

private struct DayPoint: Hashable, Identifiable {
    var id: Date { day }
    let day: Date
    let value: Double
}

private enum DayBucket: CaseIterable, Hashable {
    case morning
    case afternoon
    case evening
    case night

    var displayName: String {
        switch self {
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        case .night: return "Night"
        }
    }
}

private struct BucketStat: Hashable, Identifiable {
    var id: DayBucket { bucket }
    let bucket: DayBucket
    let avgMood: Double
}

private struct WeekdayStat: Hashable, Identifiable {
    var id: Int { weekday }
    let weekday: Int // 1...7
    let avgMood: Double

    var label: String {
        let symbols = Calendar.current.veryShortWeekdaySymbols
        let idx = max(1, min(7, weekday)) - 1
        return symbols[idx]
    }
}

private struct TagMoodStat: Hashable {
    let tag: Tag
    let avgMood: Double
    let count: Int
}

private extension TrendsView {
    static func dailyAverages(from entries: [MoodEntry]) -> [DayPoint] {
        guard !entries.isEmpty else { return [] }
        let cal = Calendar.current

        var buckets: [Date: (sum: Double, count: Int)] = [:]
        for e in entries {
            let day = cal.startOfDay(for: e.timestamp)
            var b = buckets[day] ?? (0, 0)
            b.sum += e.mood
            b.count += 1
            buckets[day] = b
        }

        return buckets
            .map { DayPoint(day: $0.key, value: $0.value.sum / Double($0.value.count)) }
            .sorted(by: { $0.day < $1.day })
    }

    static func timeOfDayAverages(from entries: [MoodEntry]) -> [BucketStat] {
        guard !entries.isEmpty else { return [] }
        let cal = Calendar.current

        func bucket(for date: Date) -> DayBucket {
            let hour = cal.component(.hour, from: date)
            switch hour {
            case 5..<12: return .morning
            case 12..<17: return .afternoon
            case 17..<22: return .evening
            default: return .night
            }
        }

        var buckets: [DayBucket: (sum: Double, count: Int)] = [:]
        for e in entries {
            let b = bucket(for: e.timestamp)
            var agg = buckets[b] ?? (0, 0)
            agg.sum += e.mood
            agg.count += 1
            buckets[b] = agg
        }

        return DayBucket.allCases.compactMap { b in
            guard let agg = buckets[b], agg.count > 0 else { return nil }
            return BucketStat(bucket: b, avgMood: agg.sum / Double(agg.count))
        }
    }

    static func weekdayAverages(from entries: [MoodEntry]) -> [WeekdayStat] {
        guard !entries.isEmpty else { return [] }
        let cal = Calendar.current

        var buckets: [Int: (sum: Double, count: Int)] = [:]
        for e in entries {
            let w = cal.component(.weekday, from: e.timestamp) // 1...7
            var agg = buckets[w] ?? (0, 0)
            agg.sum += e.mood
            agg.count += 1
            buckets[w] = agg
        }

        // Keep calendar order (veryShortWeekdaySymbols matches 1...7).
        return (1...7).compactMap { w in
            guard let agg = buckets[w], agg.count > 0 else { return nil }
            return WeekdayStat(weekday: w, avgMood: agg.sum / Double(agg.count))
        }
    }

    static func tagMoodAverages(from entries: [MoodEntry]) -> [TagMoodStat] {
        var buckets: [Tag: (sum: Double, count: Int)] = [:]
        for e in entries {
            for tag in e.tags {
                var agg = buckets[tag] ?? (0, 0)
                agg.sum += e.mood
                agg.count += 1
                buckets[tag] = agg
            }
        }
        return buckets.map { tag, agg in
            TagMoodStat(tag: tag, avgMood: agg.sum / Double(agg.count), count: agg.count)
        }
        .sorted { a, b in
            if a.count != b.count { return a.count > b.count }
            return a.avgMood > b.avgMood
        }
    }
}


