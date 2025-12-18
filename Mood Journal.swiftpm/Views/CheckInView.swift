import SwiftUI

struct JournalView: View {
    @EnvironmentObject private var entryStore: EntryStore
    @EnvironmentObject private var goalStore: GoalStore
    @State private var isPresentingNewEntry = false
    @AppStorage("displayName") private var displayName: String = ""
    @State private var searchText: String = ""
    @State private var promptSeed: Int = 0
    @State private var draftPrefill: String?
    @State private var goalEditor: Goal?
    @State private var showingNewGoal = false
    @State private var calendarMonth: Date = .now
    @State private var selectedDay: SelectedDay?

    private struct SelectedDay: Identifiable {
        let day: Date
        var id: Date { day }
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
                        calendarCard
                        goalsCard
                        

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
        .sheet(item: $selectedDay) { sel in
            DayEntriesSheet(day: sel.day, entries: entries(on: sel.day))
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
            Text(greetingLine)
                .font(.title2.weight(.semibold))
            Text("This is your private space—kept on-device.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }

    private var greetingLine: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting: String
        switch hour {
        case 5..<12: greeting = "Good morning"
        case 12..<17: greeting = "Good afternoon"
        case 17..<22: greeting = "Good evening"
        default: greeting = "Good night"
        }

        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty { return "\(greeting)." }
        return "\(greeting), \(name)."
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

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Calendar")
                    .font(.headline)
                Spacer()

                Button {
                    calendarMonth = Calendar.current.date(byAdding: .month, value: -1, to: calendarMonth) ?? calendarMonth
                } label: {
                    Label("Previous month", systemImage: "chevron.left")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Button {
                    calendarMonth = Calendar.current.date(byAdding: .month, value: 1, to: calendarMonth) ?? calendarMonth
                } label: {
                    Label("Next month", systemImage: "chevron.right")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            Text(monthTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            CalendarMonthGrid(
                month: calendarMonth,
                entryCountsByDay: entryCountsByDay,
                streakDays: streakDaySet,
                selectedDay: selectedDay?.day,
                onSelect: { day in
                    selectedDay = SelectedDay(day: day)
                }
            )
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
                Text("Add a goal to track progress—like entries per week, journal days, or words written.")
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
            guard !q.isEmpty else { return true }

            if entry.note.lowercased().contains(q) { return true }
            if entry.tags.map(\.displayName).joined(separator: " ").lowercased().contains(q) { return true }

            // Also allow searching formatted dates (e.g. "Dec", "2025")
            let dateText = entry.timestamp.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year())
            return dateText.lowercased().contains(q)
        }
    }

    private var monthTitle: String {
        calendarMonth.formatted(.dateTime.month(.wide).year())
    }

    private var entryCountsByDay: [Date: Int] {
        let cal = Calendar.current
        return Dictionary(grouping: entryStore.entries) { cal.startOfDay(for: $0.timestamp) }
            .mapValues { $0.count }
    }

    private var streakDaySet: Set<Date> {
        let cal = Calendar.current
        let daysWithEntries = Set(entryStore.entries.map { cal.startOfDay(for: $0.timestamp) })
        var set: Set<Date> = []

        var day = cal.startOfDay(for: Date())
        while daysWithEntries.contains(day) {
            set.insert(day)
            day = cal.date(byAdding: .day, value: -1, to: day) ?? day.addingTimeInterval(-86400)
        }
        return set
    }

    private func entries(on day: Date) -> [MoodEntry] {
        let cal = Calendar.current
        let d = cal.startOfDay(for: day)
        return entryStore.entries
            .filter { cal.startOfDay(for: $0.timestamp) == d }
            .sorted(by: { $0.timestamp > $1.timestamp })
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

private struct CalendarMonthGrid: View {
    let month: Date
    let entryCountsByDay: [Date: Int]
    let streakDays: Set<Date>
    let selectedDay: Date?
    let onSelect: (Date) -> Void

    private var cal: Calendar { Calendar.current }

    var body: some View {
        VStack(spacing: 8) {
            weekdayHeader
            grid
            legend
        }
    }

    private var weekdayHeader: some View {
        let symbols = cal.shortWeekdaySymbols // already localized
        let first = cal.firstWeekday - 1 // 0-based
        let ordered = Array(symbols[first...] + symbols[..<first])

        return HStack(spacing: 0) {
            ForEach(ordered, id: \.self) { s in
                Text(s.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var grid: some View {
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: month)) ?? month
        let daysRange = cal.range(of: .day, in: .month, for: startOfMonth) ?? (1..<31)
        let daysInMonth = daysRange.count

        let weekdayOfFirst = cal.component(.weekday, from: startOfMonth) // 1...7
        let offset = (weekdayOfFirst - cal.firstWeekday + 7) % 7

        let totalCells = Int(ceil(Double(offset + daysInMonth) / 7.0)) * 7
        let today = cal.startOfDay(for: Date())

        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(0..<totalCells, id: \.self) { idx in
                let dayNumber = idx - offset + 1
                if dayNumber < 1 || dayNumber > daysInMonth {
                    Color.clear
                        .frame(height: 34)
                } else {
                    let date = cal.date(byAdding: .day, value: dayNumber - 1, to: startOfMonth) ?? startOfMonth
                    let day = cal.startOfDay(for: date)
                    let count = entryCountsByDay[day] ?? 0
                    let isInStreak = streakDays.contains(day)
                    let isToday = day == today
                    let isSelected = selectedDay.map { cal.startOfDay(for: $0) == day } ?? false

                    Button {
                        onSelect(day)
                    } label: {
                        CalendarDayCell(
                            day: dayNumber,
                            count: count,
                            isInStreak: isInStreak,
                            isToday: isToday,
                            isSelected: isSelected
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Circle()
                    .fill(AppTheme.tint)
                    .frame(width: 6, height: 6)
                Text("Entry")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(AppTheme.tint.opacity(0.18))
                    .frame(width: 14, height: 10)
                Text("Streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.top, 2)
    }
}

private struct CalendarDayCell: View {
    let day: Int
    let count: Int
    let isInStreak: Bool
    let isToday: Bool
    let isSelected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isInStreak ? AppTheme.tint.opacity(0.18) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(
                            isSelected ? AppTheme.tint.opacity(0.95) : (isToday ? AppTheme.tint.opacity(0.6) : Color.primary.opacity(0.06)),
                            lineWidth: isSelected ? 2 : (isToday ? 1.5 : 1)
                        )
                )

            VStack(spacing: 4) {
                Text("\(day)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)

                if count > 0 {
                    if count == 1 {
                        Circle()
                            .fill(AppTheme.tint)
                            .frame(width: 6, height: 6)
                    } else {
                        Text("\(min(count, 9))")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.tint)
                            .clipShape(Capsule())
                    }
                } else {
                    Color.clear.frame(height: 6)
                }
            }
            .padding(.vertical, 6)
        }
        .frame(height: 34)
    }
}

private struct DayEntriesSheet: View {
    @Environment(\.dismiss) private var dismiss
    let day: Date
    let entries: [MoodEntry]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                    .ignoresSafeArea()

                if entries.isEmpty {
                    VStack(spacing: 10) {
                        Text("No entries")
                            .font(.headline)
                        Text("Write something for this day to see it here.")
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
                                            Text(entry.timestamp, format: .dateTime.hour().minute())
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
                            Text(day.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Entries")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
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


