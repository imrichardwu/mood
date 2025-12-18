import SwiftUI

struct JournalView: View {
    @EnvironmentObject private var entryStore: EntryStore
    @EnvironmentObject private var goalStore: GoalStore
    @State private var isPresentingNewEntry = false
    @State private var searchText: String = ""
    @State private var filter: JournalFilter = .all
    @State private var promptSeed: Int = 0
    @State private var draftPrefill: String?
    @State private var goalEditor: Goal?
    @State private var showingNewGoal = false

    enum JournalFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case written = "Written"
        case tagged = "Tagged"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        header
                        writeCard
                        practiceCard
                        goalsCard
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
        .sheet(isPresented: $isPresentingNewEntry, onDismiss: { draftPrefill = nil }) {
            EntryEditorView(mode: .new, prefillNote: draftPrefill) { saved in
                entryStore.add(saved)
            }
        }
        .sheet(item: $goalEditor) { goal in
            GoalEditorSheet(existing: goal) { updated, isEdit in
                if isEdit {
                    goalStore.update(updated)
                } else {
                    goalStore.add(updated)
                }
            }
        }
        .sheet(isPresented: $showingNewGoal) {
            GoalEditorSheet(existing: nil) { goal, _ in
                goalStore.add(goal)
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

    private var goalsCard: some View {
        let activeGoals = goalStore.goals.filter(\.isActive)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Goals")
                    .font(.headline)
                Spacer()
                Button {
                    showingNewGoal = true
                } label: {
                    Label("Add goal", systemImage: "plus")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            if goalStore.goals.isEmpty {
                Text("Add a goal to track progress—like entries per week, steps today, or sleep last night.")
                    .foregroundStyle(.secondary)
            } else if activeGoals.isEmpty {
                Text("No active goals. Turn one on to start tracking.")
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(activeGoals) { g in
                        GoalRow(
                            goal: g,
                            progress: g.progress(entries: entryStore.entries)
                        )
                        .contextMenu {
                            Button {
                                goalEditor = g
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }

                            Button {
                                goalStore.toggleActive(g)
                            } label: {
                                Label("Pause goal", systemImage: "pause.circle")
                            }

                            Button(role: .destructive) {
                                goalStore.delete(g)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        Divider()
                    }
                }
            }
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
            "What did you do today that you’re proud of (even if it’s small)?",
            "Name one moment you want to remember from today. Why?",
            "If today had a title, what would it be?",
            "What are you grateful for—specifically, and why?",
            "What would you tell a friend who felt exactly like you do right now?"
        ]
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let idx = abs(dayOfYear + promptSeed) % max(prompts.count, 1)
        return prompts[idx]
    }
}

private struct GoalRow: View {
    let goal: Goal
    let progress: Goal.Progress

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(goal.title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if progress.isComplete {
                    Label("Done", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.tint)
                } else {
                    Text(progress.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            ProgressView(value: progress.value, total: max(progress.target, 0.0001))
                .tint(AppTheme.tint)
        }
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

/// Kept inside this file so it is always compiled as part of the main target
/// (some Swift Playgrounds/Xcode setups can miss new standalone files until refresh).
private struct GoalEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    let existing: Goal?
    let onSave: (Goal, /*isEdit*/ Bool) -> Void

    @State private var title: String = ""
    @State private var kind: Goal.Kind = .entriesToday
    @State private var target: Double = Goal.Kind.entriesToday.defaultTarget
    @State private var isActive: Bool = true

    init(existing: Goal?, onSave: @escaping (Goal, Bool) -> Void) {
        self.existing = existing
        self.onSave = onSave

        if let existing {
            _title = State(initialValue: existing.title)
            _kind = State(initialValue: existing.kind)
            _target = State(initialValue: existing.target)
            _isActive = State(initialValue: existing.isActive)
        } else {
            _title = State(initialValue: "")
            _kind = State(initialValue: .entriesToday)
            _target = State(initialValue: Goal.Kind.entriesToday.defaultTarget)
            _isActive = State(initialValue: true)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                    .ignoresSafeArea()

                Form {
                    Section("Goal") {
                        TextField("What do you want to do?", text: $title)

                        Picker("Type", selection: $kind) {
                            ForEach(Goal.Kind.allCases) { k in
                                Text(k.displayName).tag(k)
                            }
                        }
                        .onChange(of: kind) { newKind in
                            // Keep targets sensible when switching types.
                            let clamped = min(max(target, newKind.targetBounds.lowerBound), newKind.targetBounds.upperBound)
                            if clamped == target { return }
                            target = clamped
                        }

                        targetPicker
                        Toggle("Active", isOn: $isActive)
                    }

                    Section {
                        Text(helperText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(existing == nil ? "New Goal" : "Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    @ViewBuilder
    private var targetPicker: some View {
        switch kind {
        default:
            Stepper(value: $target, in: kind.targetBounds, step: kind.targetStep) {
                Text("Target: \(Int(target.rounded())) \(kind.unitLabel)")
            }
        }
    }

    private var helperText: String {
        switch kind {
        case .entriesToday:
            return "Counts how many entries you write today."
        case .entriesThisWeek:
            return "Counts how many entries you write this week."
        case .daysThisWeek:
            return "Counts how many days this week you journal at least once."
        case .wordsToday:
            return "Counts words you write in entries today."
        case .wordsThisWeek:
            return "Counts words you write in entries this week."
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = trimmedTitle.isEmpty ? kind.displayName : trimmedTitle
        let clampedTarget = min(max(target, kind.targetBounds.lowerBound), kind.targetBounds.upperBound)

        if var existing {
            existing.title = finalTitle
            existing.kind = kind
            existing.target = clampedTarget
            existing.isActive = isActive
            onSave(existing, true)
        } else {
            let g = Goal(title: finalTitle, kind: kind, target: clampedTarget, isActive: isActive)
            onSave(g, false)
        }
        dismiss()
    }
}


