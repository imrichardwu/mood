import SwiftUI

struct JournalView: View {
    @EnvironmentObject private var entryStore: EntryStore
    @State private var isPresentingNewEntry = false
    @Environment(\.colorScheme) private var scheme
    @AppStorage("healthkitEnabled") private var healthkitEnabled: Bool = false
    @StateObject private var healthKit = HealthKitManager()
    @State private var searchText: String = ""
    @State private var filter: JournalFilter = .all
    @State private var promptSeed: Int = 0
    @State private var draftPrefill: String?

    enum JournalFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case written = "Written"
        case tagged = "Tagged"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: scheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        header
                        writeCard
                        practiceCard
                        promptCard

                        if entryStore.entries.isEmpty {
                            emptyState
                        } else {
                            journalTimeline
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        draftPrefill = nil
                        isPresentingNewEntry = true
                    } label: {
                        Label("Write", systemImage: "square.and.pencil")
                    }
                }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search notes or tags")
        .task(id: healthkitEnabled) {
            guard healthkitEnabled else { return }
            await healthKit.requestAuthorization()
            await healthKit.refreshToday()
        }
        .sheet(isPresented: $isPresentingNewEntry, onDismiss: { draftPrefill = nil }) {
            EntryEditorView(mode: .new, prefillNote: draftPrefill) { saved in
                let context = healthContextForNewEntry()
                entryStore.add(saved, healthContext: context)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day())
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Write what’s on your mind.")
                .font(.title2.weight(.semibold))
            Text("This is your private space—kept on-device.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }

    private var writeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("New entry")
                .font(.headline)
            Text("A few lines is enough. You can also just log how you felt.")
                .font(.callout)
                .foregroundStyle(.secondary)

            Button {
                draftPrefill = nil
                isPresentingNewEntry = true
            } label: {
                Text("Write")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .appCard()
    }

    private var practiceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Your practice")
                    .font(.headline)
                Spacer()
                Picker("Filter", selection: $filter) {
                    ForEach(JournalFilter.allCases) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 240)
            }

            HStack(spacing: 12) {
                StatChip(title: "Streak", value: "\(streakDays)d", symbol: "flame.fill")
                StatChip(title: "Entries", value: "\(entryStore.entries.count)", symbol: "text.book.closed")
                if !visibleEntries.isEmpty && visibleEntries.count != entryStore.entries.count {
                    StatChip(title: "Shown", value: "\(visibleEntries.count)", symbol: "line.3.horizontal.decrease.circle")
                }
            }

            if healthkitEnabled {
                HStack(spacing: 12) {
                    if let steps = healthKit.todaySteps {
                        StatChip(title: "Steps today", value: "\(Int(steps.rounded()))", symbol: "figure.walk")
                    }
                    if let sleep = healthKit.lastNightSleepHours {
                        StatChip(title: "Sleep", value: String(format: "%.1f h", sleep), symbol: "bed.double.fill")
                    }
                }
            }

            if healthkitEnabled, let msg = healthKit.lastErrorMessage {
                Text(msg)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .appCard()
    }

    private var promptCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Today’s prompt")
                    .font(.headline)
                Spacer()
                Button {
                    promptSeed += 1
                } label: {
                    Label("Shuffle", systemImage: "shuffle")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            Text(promptText)
                .font(.body)
                .foregroundStyle(.secondary)

            Button {
                draftPrefill = promptText + "\n\n"
                isPresentingNewEntry = true
            } label: {
                Text("Write from prompt")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .appCard()
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No entries yet.")
                .font(.headline)
            Text("Start with a few lines about today, or just a quick mood check‑in.")
                .foregroundStyle(.secondary)
            Button {
                isPresentingNewEntry = true
            } label: {
                Text("Add your first entry")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .appCard()
    }

    private var journalTimeline: some View {
        LazyVStack(alignment: .leading, spacing: 14) {
            ForEach(groupedEntries, id: \.day) { section in
                DaySection(
                    day: section.day,
                    entries: section.entries,
                    onDelete: { entryStore.delete($0) }
                )
            }
        }
    }

    private var groupedEntries: [(day: Date, entries: [MoodEntry])] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: visibleEntries) { cal.startOfDay(for: $0.timestamp) }
        return grouped.keys
            .sorted(by: >)
            .map { day in
                let items = (grouped[day] ?? []).sorted(by: { $0.timestamp > $1.timestamp })
                return (day: day, entries: items)
            }
    }

    private var visibleEntries: [MoodEntry] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return entryStore.entries.filter { entry in
            if !matchesFilter(entry) { return false }
            guard !q.isEmpty else { return true }

            if entry.note.lowercased().contains(q) { return true }
            if entry.tags.map(\.displayName).joined(separator: " ").lowercased().contains(q) { return true }

            // Also allow searching formatted dates (e.g. "Dec", "2025")
            let dateText = entry.timestamp.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year())
            return dateText.lowercased().contains(q)
        }
    }

    private func matchesFilter(_ entry: MoodEntry) -> Bool {
        switch filter {
        case .all:
            return true
        case .written:
            return !entry.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .tagged:
            return !entry.tags.isEmpty
        }
    }

    private var streakDays: Int {
        let cal = Calendar.current
        let daysWithEntries = Set(entryStore.entries.map { cal.startOfDay(for: $0.timestamp) })
        var count = 0
        var day = cal.startOfDay(for: Date())
        while daysWithEntries.contains(day) {
            count += 1
            day = cal.date(byAdding: .day, value: -1, to: day) ?? day.addingTimeInterval(-86400)
        }
        return count
    }

    private var promptText: String {
        let prompts: [String] = [
            "What felt heavy today—and what helped, even a little?",
            "What did you do today that you’re proud of (even if it’s small)?",
            "What’s one thing you wish someone understood about you right now?",
            "Where did you feel tension in your body? What might it be asking for?",
            "What did you avoid today? What would a gentler approach look like?",
            "Name one moment you want to remember from today. Why?",
            "If today had a title, what would it be?",
            "What’s one boundary you want to practice this week?",
            "What are you grateful for—specifically, and why?",
            "What would you tell a friend who felt exactly like you do right now?"
        ]
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let idx = abs(dayOfYear + promptSeed) % max(prompts.count, 1)
        return prompts[idx]
    }

    private func healthContextForNewEntry() -> MoodEntry.HealthContext? {
        guard healthkitEnabled else { return nil }
        let context = MoodEntry.HealthContext(
            sleepHours: healthKit.lastNightSleepHours,
            steps: healthKit.todaySteps
        )
        // Only attach if we actually have something.
        if context.sleepHours == nil && context.steps == nil { return nil }
        return context
    }
}

private struct DaySection: View {
    let day: Date
    let entries: [MoodEntry]
    let onDelete: (MoodEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(day, format: .dateTime.month(.wide).day().year())
                .font(.headline)

            VStack(spacing: 10) {
                ForEach(entries) { entry in
                    NavigationLink {
                        EntryDetailView(entry: entry)
                    } label: {
                        JournalEntryCard(entry: entry)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            onDelete(entry)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .appCard()
    }
}

private struct StatChip: View {
    let title: String
    let value: String
    let symbol: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.subheadline)
                .foregroundStyle(AppTheme.tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(AppTheme.tint.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct JournalEntryCard: View {
    let entry: MoodEntry
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(entry.timestamp, format: .dateTime.hour().minute())
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("Mood \(Int(entry.mood.rounded()))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !entry.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(entry.note)
                    .font(.body)
                    .lineLimit(4)
                    .foregroundStyle(.primary)
            } else {
                Text("No text for this entry.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            if !entry.tags.isEmpty {
                Text(entry.tags.map(\.displayName).joined(separator: " · "))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if entry.health.sleepHours != nil || entry.health.steps != nil {
                HStack(spacing: 12) {
                    if let steps = entry.health.steps {
                        Label("\(Int(steps.rounded()))", systemImage: "figure.walk")
                            .labelStyle(.titleAndIcon)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    if let sleep = entry.health.sleepHours {
                        Label(String(format: "%.1f h", sleep), systemImage: "bed.double.fill")
                            .labelStyle(.titleAndIcon)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppTheme.cardBackground(for: scheme).opacity(scheme == .dark ? 0.45 : 0.85))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}


